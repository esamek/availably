#!/bin/bash

# Test ID: LOCK-004
# Description: Lock ownership verification
# Expected: Only lock owner can release the lock

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR="$1"

# Source the locking library with overridden paths
source "$SCRIPT_DIR/../../scripts/lib/server-locking.sh"

# Test functions
test_ownership_verification() {
    echo "Testing lock ownership verification..."
    
    # Acquire lock in current process
    if ! acquire_lock; then
        echo "ERROR: Failed to acquire lock"
        return 1
    fi
    
    # Verify we own the lock
    if ! is_locked; then
        echo "ERROR: Lock should be held"
        return 1
    fi
    
    # Get lock owner information
    local owner_info=$(get_lock_owner)
    if [[ ! "$owner_info" =~ "PID: $$" ]]; then
        echo "ERROR: Lock owner should be current process ($$)"
        echo "Got: $owner_info"
        return 1
    fi
    
    # Release lock should succeed (we own it)
    if ! release_lock; then
        echo "ERROR: Failed to release lock that we own"
        return 1
    fi
    
    echo "✅ Lock ownership verification successful"
    return 0
}

test_non_owner_release_attempt() {
    echo "Testing non-owner release attempt..."
    
    # Create lock owned by different process
    mkdir -p "$LOCK_FILE"
    local fake_pid=99999
    local timestamp=$(date +%s)
    local owner_info="$fake_pid:$timestamp:$USER:$(hostname)"
    echo "$owner_info" > "$LOCK_FILE/owner"
    
    # Verify lock exists
    if [ ! -d "$LOCK_FILE" ]; then
        echo "ERROR: Test setup failed - lock should exist"
        return 1
    fi
    
    # Attempt to release lock should fail (we don't own it)
    if release_lock; then
        echo "ERROR: Should not be able to release lock owned by different process"
        return 1
    fi
    
    # Verify lock still exists
    if [ ! -d "$LOCK_FILE" ]; then
        echo "ERROR: Lock should still exist after failed release"
        return 1
    fi
    
    # Clean up manually
    rm -rf "$LOCK_FILE"
    
    echo "✅ Non-owner release attempt correctly rejected"
    return 0
}

test_owner_info_accuracy() {
    echo "Testing owner info accuracy..."
    
    # Acquire lock
    if ! acquire_lock; then
        echo "ERROR: Failed to acquire lock"
        return 1
    fi
    
    # Get owner information
    local owner_info=$(get_lock_owner)
    
    # Verify owner info contains expected components
    if [[ ! "$owner_info" =~ "PID: $$" ]]; then
        echo "ERROR: Owner info should contain current PID ($$)"
        echo "Got: $owner_info"
        release_lock
        return 1
    fi
    
    if [[ ! "$owner_info" =~ "User: $USER" ]]; then
        echo "ERROR: Owner info should contain current user ($USER)"
        echo "Got: $owner_info"
        release_lock
        return 1
    fi
    
    if [[ ! "$owner_info" =~ "Host: $(hostname)" ]]; then
        echo "ERROR: Owner info should contain hostname ($(hostname))"
        echo "Got: $owner_info"
        release_lock
        return 1
    fi
    
    if [[ ! "$owner_info" =~ "Time:" ]]; then
        echo "ERROR: Owner info should contain timestamp"
        echo "Got: $owner_info"
        release_lock
        return 1
    fi
    
    # Release lock
    release_lock
    
    echo "✅ Owner info accuracy verified"
    return 0
}

test_ownership_through_subprocess() {
    echo "Testing ownership through subprocess..."
    
    # Create lock in subprocess
    (
        export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
        export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
        export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
        export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
        
        source "$SCRIPT_DIR/../../scripts/lib/server-locking.sh"
        
        if acquire_lock; then
            echo "Subprocess acquired lock (PID: $$)"
            # Keep lock for 3 seconds
            sleep 3
            release_lock
            echo "Subprocess released lock"
        else
            echo "ERROR: Subprocess failed to acquire lock"
            exit 1
        fi
    ) &
    
    local subprocess_pid=$!
    
    # Wait for subprocess to acquire lock
    sleep 1
    
    # Verify lock is held
    if ! is_locked; then
        echo "ERROR: Lock should be held by subprocess"
        wait $subprocess_pid
        return 1
    fi
    
    # Verify owner is the subprocess
    local owner_info=$(get_lock_owner)
    if [[ "$owner_info" =~ "PID: $$" ]]; then
        echo "ERROR: Lock should be owned by subprocess, not current process"
        echo "Got: $owner_info"
        wait $subprocess_pid
        return 1
    fi
    
    # Attempt to release lock should fail (subprocess owns it)
    if release_lock; then
        echo "ERROR: Should not be able to release lock owned by subprocess"
        wait $subprocess_pid
        return 1
    fi
    
    # Wait for subprocess to finish
    wait $subprocess_pid
    
    # Verify lock is now free
    if is_locked; then
        echo "ERROR: Lock should be free after subprocess finishes"
        return 1
    fi
    
    echo "✅ Ownership through subprocess verified"
    return 0
}

test_ownership_after_process_death() {
    echo "Testing ownership after process death..."
    
    # Create lock owned by a process that will die
    local temp_script="$TEST_TEMP_DIR/temp_lock_holder.sh"
    cat > "$temp_script" << 'EOF'
#!/bin/bash
export LOCK_FILE="$1"
export SERVER_STATE_FILE="$2"
export USERS_COUNT_FILE="$3"
export USERS_LIST_FILE="$4"

source "$5"

if acquire_lock; then
    echo "Temp process acquired lock (PID: $$)"
    # Process will be killed while holding lock
    sleep 10
else
    echo "ERROR: Temp process failed to acquire lock"
    exit 1
fi
EOF
    
    chmod +x "$temp_script"
    
    # Start temp process
    "$temp_script" \
        "$TEST_TEMP_DIR/availably-dev-server.lock" \
        "$TEST_TEMP_DIR/availably-dev-server.state" \
        "$TEST_TEMP_DIR/availably-server-users.count" \
        "$TEST_TEMP_DIR/availably-server-users.list" \
        "$SCRIPT_DIR/../../scripts/lib/server-locking.sh" &
    
    local temp_pid=$!
    
    # Wait for temp process to acquire lock
    sleep 1
    
    # Verify lock is held
    if ! is_locked; then
        echo "ERROR: Lock should be held by temp process"
        kill $temp_pid 2>/dev/null
        wait $temp_pid 2>/dev/null
        return 1
    fi
    
    # Kill the temp process
    kill $temp_pid 2>/dev/null
    wait $temp_pid 2>/dev/null
    
    # Lock should still exist (dead process)
    if [ ! -d "$LOCK_FILE" ]; then
        echo "ERROR: Lock should still exist after process death"
        return 1
    fi
    
    # But cleanup should detect it's stale
    if cleanup_stale_locks; then
        echo "✅ Stale lock from dead process cleaned up"
    else
        echo "ERROR: Failed to clean up stale lock from dead process"
        return 1
    fi
    
    # Lock should now be free
    if is_locked; then
        echo "ERROR: Lock should be free after cleanup"
        return 1
    fi
    
    # Clean up temp script
    rm -f "$temp_script"
    
    echo "✅ Ownership after process death handled correctly"
    return 0
}

# Main test execution
main() {
    echo "Running LOCK-004: Lock ownership verification test"
    
    # Run individual tests
    if ! test_ownership_verification; then
        echo "❌ Ownership verification test failed"
        return 1
    fi
    
    if ! test_non_owner_release_attempt; then
        echo "❌ Non-owner release attempt test failed"
        return 1
    fi
    
    if ! test_owner_info_accuracy; then
        echo "❌ Owner info accuracy test failed"
        return 1
    fi
    
    if ! test_ownership_through_subprocess; then
        echo "❌ Ownership through subprocess test failed"
        return 1
    fi
    
    if ! test_ownership_after_process_death; then
        echo "❌ Ownership after process death test failed"
        return 1
    fi
    
    echo "✅ All LOCK-004 tests passed"
    return 0
}

# Run the test
main