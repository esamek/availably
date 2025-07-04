#!/bin/bash

# Test ID: LOCK-003
# Description: Stale lock cleanup
# Expected: Old locks from dead processes are automatically cleaned up

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR="$1"

# Source the locking library with overridden paths
source "$SCRIPT_DIR/../../scripts/lib/server-locking.sh"

# Test functions
test_dead_process_cleanup() {
    echo "Testing dead process cleanup..."
    
    # Create a lock file with a dead process PID
    mkdir -p "$LOCK_FILE"
    local fake_pid=99999
    local timestamp=$(date +%s)
    local owner_info="$fake_pid:$timestamp:$USER:$(hostname)"
    echo "$owner_info" > "$LOCK_FILE/owner"
    
    # Verify lock exists
    if [ ! -d "$LOCK_FILE" ]; then
        echo "ERROR: Test setup failed - lock file should exist"
        return 1
    fi
    
    # Cleanup stale locks should remove the dead process lock
    cleanup_stale_locks
    
    # Verify lock is cleaned up
    if [ -d "$LOCK_FILE" ]; then
        echo "ERROR: Stale lock should have been cleaned up"
        return 1
    fi
    
    echo "✅ Dead process cleanup successful"
    return 0
}

test_old_lock_cleanup() {
    echo "Testing old lock cleanup..."
    
    # Create a lock file with an old timestamp
    mkdir -p "$LOCK_FILE"
    local old_timestamp=$(($(date +%s) - 400))  # 400 seconds ago (older than MAX_LOCK_AGE)
    local owner_info="$$:$old_timestamp:$USER:$(hostname)"
    echo "$owner_info" > "$LOCK_FILE/owner"
    
    # Verify lock exists
    if [ ! -d "$LOCK_FILE" ]; then
        echo "ERROR: Test setup failed - lock file should exist"
        return 1
    fi
    
    # Cleanup stale locks should remove the old lock
    cleanup_stale_locks
    
    # Verify lock is cleaned up
    if [ -d "$LOCK_FILE" ]; then
        echo "ERROR: Old lock should have been cleaned up"
        return 1
    fi
    
    echo "✅ Old lock cleanup successful"
    return 0
}

test_malformed_lock_cleanup() {
    echo "Testing malformed lock cleanup..."
    
    # Create a lock directory without owner file
    mkdir -p "$LOCK_FILE"
    
    # Verify lock exists but no owner file
    if [ ! -d "$LOCK_FILE" ]; then
        echo "ERROR: Test setup failed - lock file should exist"
        return 1
    fi
    
    if [ -f "$LOCK_FILE/owner" ]; then
        echo "ERROR: Test setup failed - owner file should not exist"
        return 1
    fi
    
    # Cleanup stale locks should remove the malformed lock
    cleanup_stale_locks
    
    # Verify lock is cleaned up
    if [ -d "$LOCK_FILE" ]; then
        echo "ERROR: Malformed lock should have been cleaned up"
        return 1
    fi
    
    echo "✅ Malformed lock cleanup successful"
    return 0
}

test_valid_lock_preservation() {
    echo "Testing valid lock preservation..."
    
    # Create a valid lock file (current process, recent timestamp)
    mkdir -p "$LOCK_FILE"
    local timestamp=$(date +%s)
    local owner_info="$$:$timestamp:$USER:$(hostname)"
    echo "$owner_info" > "$LOCK_FILE/owner"
    
    # Verify lock exists
    if [ ! -d "$LOCK_FILE" ]; then
        echo "ERROR: Test setup failed - lock file should exist"
        return 1
    fi
    
    # Cleanup stale locks should NOT remove valid lock
    cleanup_stale_locks
    
    # Verify lock still exists
    if [ ! -d "$LOCK_FILE" ]; then
        echo "ERROR: Valid lock should not have been cleaned up"
        return 1
    fi
    
    # Verify owner file is intact
    if [ ! -f "$LOCK_FILE/owner" ]; then
        echo "ERROR: Valid lock owner file should be intact"
        return 1
    fi
    
    # Clean up for next test
    release_lock
    
    echo "✅ Valid lock preservation successful"
    return 0
}

test_cleanup_during_acquisition() {
    echo "Testing cleanup during acquisition..."
    
    # Create a stale lock from a dead process
    mkdir -p "$LOCK_FILE"
    local fake_pid=99998
    local timestamp=$(date +%s)
    local owner_info="$fake_pid:$timestamp:$USER:$(hostname)"
    echo "$owner_info" > "$LOCK_FILE/owner"
    
    # Verify stale lock exists
    if [ ! -d "$LOCK_FILE" ]; then
        echo "ERROR: Test setup failed - stale lock should exist"
        return 1
    fi
    
    # Acquire lock should clean up stale lock and succeed
    if ! acquire_lock; then
        echo "ERROR: Failed to acquire lock after cleanup"
        return 1
    fi
    
    # Verify we now own the lock
    if ! is_locked; then
        echo "ERROR: Lock should be held after acquisition"
        return 1
    fi
    
    # Verify owner is correct
    local owner_info=$(cat "$LOCK_FILE/owner")
    local lock_pid=$(echo "$owner_info" | cut -d: -f1)
    
    if [ "$lock_pid" != "$$" ]; then
        echo "ERROR: Lock should be owned by current process"
        return 1
    fi
    
    # Clean up
    release_lock
    
    echo "✅ Cleanup during acquisition successful"
    return 0
}

test_concurrent_cleanup() {
    echo "Testing concurrent cleanup..."
    
    # Create multiple stale locks with different scenarios
    local lock_base="$TEST_TEMP_DIR/test-lock"
    
    # Stale lock 1: Dead process
    mkdir -p "${lock_base}-1"
    echo "99997:$(date +%s):$USER:$(hostname)" > "${lock_base}-1/owner"
    
    # Stale lock 2: Old timestamp
    mkdir -p "${lock_base}-2"
    echo "$$:$(($(date +%s) - 400)):$USER:$(hostname)" > "${lock_base}-2/owner"
    
    # Stale lock 3: Malformed (no owner file)
    mkdir -p "${lock_base}-3"
    
    # Test cleanup by trying to acquire each lock
    for i in 1 2 3; do
        export LOCK_FILE="${lock_base}-${i}"
        
        # Cleanup should succeed
        if ! cleanup_stale_locks; then
            echo "ERROR: Cleanup failed for lock $i"
            return 1
        fi
        
        # Lock should be cleaned up
        if [ -d "$LOCK_FILE" ]; then
            echo "ERROR: Lock $i should have been cleaned up"
            return 1
        fi
    done
    
    echo "✅ Concurrent cleanup successful"
    return 0
}

# Main test execution
main() {
    echo "Running LOCK-003: Stale lock cleanup test"
    
    # Run individual tests
    if ! test_dead_process_cleanup; then
        echo "❌ Dead process cleanup test failed"
        return 1
    fi
    
    if ! test_old_lock_cleanup; then
        echo "❌ Old lock cleanup test failed"
        return 1
    fi
    
    if ! test_malformed_lock_cleanup; then
        echo "❌ Malformed lock cleanup test failed"
        return 1
    fi
    
    if ! test_valid_lock_preservation; then
        echo "❌ Valid lock preservation test failed"
        return 1
    fi
    
    if ! test_cleanup_during_acquisition; then
        echo "❌ Cleanup during acquisition test failed"
        return 1
    fi
    
    if ! test_concurrent_cleanup; then
        echo "❌ Concurrent cleanup test failed"
        return 1
    fi
    
    echo "✅ All LOCK-003 tests passed"
    return 0
}

# Run the test
main