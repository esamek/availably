#!/bin/bash

# Test ID: LOCK-002
# Description: Lock timeout behavior
# Expected: Lock acquisition fails after timeout when another process holds lock

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR="$1"

# Source the locking library with overridden paths
source "$SCRIPT_DIR/../../scripts/lib/server-locking.sh"

# Test functions
test_lock_timeout_behavior() {
    echo "Testing lock timeout behavior..."
    
    # Create a background process that holds the lock
    (
        # Override lock file path in subprocess
        export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
        export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
        export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
        export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
        
        # Source library in subprocess
        source "$SCRIPT_DIR/../../scripts/lib/server-locking.sh"
        
        # Acquire lock and hold it
        if acquire_lock; then
            echo "Background process acquired lock"
            # Hold lock for 8 seconds
            sleep 8
            release_lock
            echo "Background process released lock"
        else
            echo "ERROR: Background process failed to acquire lock"
            exit 1
        fi
    ) &
    
    local bg_pid=$!
    
    # Wait for background process to acquire lock
    sleep 1
    
    # Verify lock is held
    if ! is_locked; then
        echo "ERROR: Lock should be held by background process"
        kill $bg_pid 2>/dev/null
        wait $bg_pid 2>/dev/null
        return 1
    fi
    
    # Attempt to acquire lock with short timeout (should fail)
    local start_time=$(date +%s)
    if acquire_lock 3; then
        echo "ERROR: Lock acquisition should have failed due to timeout"
        release_lock
        kill $bg_pid 2>/dev/null
        wait $bg_pid 2>/dev/null
        return 1
    fi
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    # Verify timeout occurred (should be around 3 seconds)
    if [ $elapsed -lt 2 ] || [ $elapsed -gt 5 ]; then
        echo "ERROR: Timeout behavior incorrect (elapsed: ${elapsed}s, expected: ~3s)"
        kill $bg_pid 2>/dev/null
        wait $bg_pid 2>/dev/null
        return 1
    fi
    
    # Wait for background process to finish
    wait $bg_pid
    
    # Verify lock is now available
    if is_locked; then
        echo "ERROR: Lock should be available after background process finishes"
        return 1
    fi
    
    echo "✅ Lock timeout behavior correct (elapsed: ${elapsed}s)"
    return 0
}

test_lock_timeout_with_valid_owner() {
    echo "Testing timeout behavior with valid owner..."
    
    # Create lock file with valid owner (current process)
    mkdir -p "$LOCK_FILE"
    local timestamp=$(date +%s)
    local owner_info="$$:$timestamp:$USER:$(hostname)"
    echo "$owner_info" > "$LOCK_FILE/owner"
    
    # Acquiring lock should succeed immediately (we already own it)
    if ! acquire_lock 1; then
        echo "ERROR: Should be able to acquire lock we already own"
        return 1
    fi
    
    # Clean up
    release_lock
    
    echo "✅ Lock timeout with valid owner handled correctly"
    return 0
}

test_concurrent_timeout_scenarios() {
    echo "Testing concurrent timeout scenarios..."
    
    # Start multiple processes trying to acquire lock
    local pids=()
    local results=()
    
    # First process gets the lock
    (
        export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
        export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
        export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
        export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
        
        source "$SCRIPT_DIR/../../scripts/lib/server-locking.sh"
        
        if acquire_lock; then
            echo "Process 1 acquired lock"
            sleep 5
            release_lock
            echo "Process 1 released lock"
            exit 0
        else
            echo "Process 1 failed to acquire lock"
            exit 1
        fi
    ) &
    pids+=($!)
    
    # Wait for first process to acquire lock
    sleep 1
    
    # Second and third processes should timeout
    for i in 2 3; do
        (
            export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
            export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
            export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
            export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
            
            source "$SCRIPT_DIR/../../scripts/lib/server-locking.sh"
            
            if acquire_lock 2; then
                echo "Process $i acquired lock (unexpected)"
                release_lock
                exit 1
            else
                echo "Process $i timed out (expected)"
                exit 0
            fi
        ) &
        pids+=($!)
    done
    
    # Wait for all processes to complete
    local all_success=true
    for pid in "${pids[@]}"; do
        if ! wait $pid; then
            all_success=false
        fi
    done
    
    if [ "$all_success" = true ]; then
        echo "✅ Concurrent timeout scenarios handled correctly"
        return 0
    else
        echo "ERROR: Some concurrent timeout scenarios failed"
        return 1
    fi
}

# Main test execution
main() {
    echo "Running LOCK-002: Lock timeout behavior test"
    
    # Run individual tests
    if ! test_lock_timeout_behavior; then
        echo "❌ Lock timeout behavior test failed"
        return 1
    fi
    
    if ! test_lock_timeout_with_valid_owner; then
        echo "❌ Lock timeout with valid owner test failed"
        return 1
    fi
    
    if ! test_concurrent_timeout_scenarios; then
        echo "❌ Concurrent timeout scenarios test failed"
        return 1
    fi
    
    echo "✅ All LOCK-002 tests passed"
    return 0
}

# Run the test
main