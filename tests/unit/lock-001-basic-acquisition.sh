#!/bin/bash

# Test ID: LOCK-001
# Description: Basic lock acquisition and release
# Expected: Lock acquired successfully, then released

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR="$1"

# Source the locking library with overridden paths
source "$SCRIPT_DIR/../../scripts/lib/server-locking.sh"

# Test functions
test_basic_lock_acquisition() {
    echo "Testing basic lock acquisition..."
    
    # Verify no lock initially
    if is_locked; then
        echo "ERROR: Lock should not be held initially"
        return 1
    fi
    
    # Acquire lock
    if ! acquire_lock; then
        echo "ERROR: Failed to acquire lock"
        return 1
    fi
    
    # Verify lock is held
    if ! is_locked; then
        echo "ERROR: Lock should be held after acquisition"
        return 1
    fi
    
    # Verify lock file structure
    if [ ! -d "$LOCK_FILE" ]; then
        echo "ERROR: Lock file directory should exist"
        return 1
    fi
    
    if [ ! -f "$LOCK_FILE/owner" ]; then
        echo "ERROR: Lock owner file should exist"
        return 1
    fi
    
    # Verify owner information
    local owner_info=$(cat "$LOCK_FILE/owner")
    local lock_pid=$(echo "$owner_info" | cut -d: -f1)
    
    if [ "$lock_pid" != "$$" ]; then
        echo "ERROR: Lock should be owned by current process (expected: $$, got: $lock_pid)"
        return 1
    fi
    
    echo "✅ Lock acquired successfully"
    return 0
}

test_basic_lock_release() {
    echo "Testing basic lock release..."
    
    # Verify lock is held
    if ! is_locked; then
        echo "ERROR: Lock should be held before release"
        return 1
    fi
    
    # Release lock
    if ! release_lock; then
        echo "ERROR: Failed to release lock"
        return 1
    fi
    
    # Verify lock is released
    if is_locked; then
        echo "ERROR: Lock should not be held after release"
        return 1
    fi
    
    # Verify lock file is cleaned up
    if [ -d "$LOCK_FILE" ]; then
        echo "ERROR: Lock file should be cleaned up after release"
        return 1
    fi
    
    echo "✅ Lock released successfully"
    return 0
}

test_multiple_acquisition_attempts() {
    echo "Testing multiple acquisition attempts..."
    
    # First acquisition should succeed
    if ! acquire_lock; then
        echo "ERROR: First lock acquisition failed"
        return 1
    fi
    
    # Second acquisition should fail (timeout quickly)
    if acquire_lock 1; then
        echo "ERROR: Second lock acquisition should have failed"
        return 1
    fi
    
    # Release the lock
    if ! release_lock; then
        echo "ERROR: Failed to release lock"
        return 1
    fi
    
    # Third acquisition should succeed
    if ! acquire_lock; then
        echo "ERROR: Third lock acquisition failed"
        return 1
    fi
    
    # Clean up
    release_lock
    
    echo "✅ Multiple acquisition attempts handled correctly"
    return 0
}

# Main test execution
main() {
    echo "Running LOCK-001: Basic lock acquisition and release test"
    
    # Run individual tests
    if ! test_basic_lock_acquisition; then
        echo "❌ Basic lock acquisition test failed"
        return 1
    fi
    
    if ! test_basic_lock_release; then
        echo "❌ Basic lock release test failed"
        return 1
    fi
    
    if ! test_multiple_acquisition_attempts; then
        echo "❌ Multiple acquisition attempts test failed"
        return 1
    fi
    
    echo "✅ All LOCK-001 tests passed"
    return 0
}

# Run the test
main