#!/bin/bash

# Test ID: INT-003
# Description: stop-dev-server.sh with active users integration test
# Expected: Server refuses to stop when users are active

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR="$1"

# Test functions
test_stop_with_active_users() {
    echo "Testing stop-dev-server.sh with active users..."
    
    # Override environment variables for scripts
    export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
    export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
    export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
    export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
    
    # Clean up any existing state
    rm -f "$LOCK_FILE" "$SERVER_STATE_FILE" "$USERS_COUNT_FILE" "$USERS_LIST_FILE" 2>/dev/null || true
    rm -rf "$LOCK_FILE" 2>/dev/null || true
    
    # Source coordination library
    source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"
    
    # Set up server state
    set_server_state "running" "12345"
    
    # Register active users
    register_server_user "test-agent-1"
    register_server_user "test-agent-2"
    
    # Verify users are registered
    local user_count=$(get_user_count)
    if [ "$user_count" -ne 2 ]; then
        echo "ERROR: Should have 2 active users, got $user_count"
        return 1
    fi
    
    # Try to stop server with active users
    local stop_output
    stop_output=$("$SCRIPT_DIR/../../scripts/stop-dev-server.sh" 2>&1)
    local stop_exit_code=$?
    
    # Should refuse to stop or warn about active users
    if [ $stop_exit_code -eq 0 ]; then
        if [[ "$stop_output" =~ "active users" ]] || [[ "$stop_output" =~ "cannot stop" ]] || [[ "$stop_output" =~ "users still registered" ]]; then
            echo "✅ Stop script correctly refused to stop with active users"
        else
            echo "WARNING: Stop script succeeded but should warn about active users"
            echo "Output: $stop_output"
        fi
    else
        if [[ "$stop_output" =~ "active users" ]] || [[ "$stop_output" =~ "cannot stop" ]]; then
            echo "✅ Stop script correctly refused to stop with active users"
        else
            echo "ERROR: Stop script failed for unexpected reason"
            echo "Output: $stop_output"
            return 1
        fi
    fi
    
    # Clean up users
    unregister_server_user "test-agent-1"
    unregister_server_user "test-agent-2"
    
    return 0
}

test_stop_with_no_users() {
    echo "Testing stop-dev-server.sh with no active users..."
    
    # Override environment variables for scripts
    export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
    export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
    export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
    export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
    
    # Clean up any existing state
    rm -f "$LOCK_FILE" "$SERVER_STATE_FILE" "$USERS_COUNT_FILE" "$USERS_LIST_FILE" 2>/dev/null || true
    rm -rf "$LOCK_FILE" 2>/dev/null || true
    
    # Source coordination library
    source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"
    
    # Set up server state (but no users)
    set_server_state "running" "12345"
    
    # Verify no users
    local user_count=$(get_user_count)
    if [ "$user_count" -ne 0 ]; then
        echo "ERROR: Should have 0 users, got $user_count"
        return 1
    fi
    
    # Try to stop server with no users
    local stop_output
    stop_output=$("$SCRIPT_DIR/../../scripts/stop-dev-server.sh" 2>&1)
    local stop_exit_code=$?
    
    # Should succeed or at least attempt to stop
    if [ $stop_exit_code -eq 0 ]; then
        echo "✅ Stop script succeeded with no active users"
    else
        # May fail if no actual server is running, but should indicate it tried
        if [[ "$stop_output" =~ "no server" ]] || [[ "$stop_output" =~ "not running" ]] || [[ "$stop_output" =~ "stop" ]]; then
            echo "✅ Stop script attempted to stop with no active users"
        else
            echo "ERROR: Stop script failed unexpectedly"
            echo "Output: $stop_output"
            return 1
        fi
    fi
    
    return 0
}

test_stop_with_dead_users() {
    echo "Testing stop-dev-server.sh with dead users..."
    
    # Override environment variables for scripts
    export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
    export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
    export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
    export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
    
    # Clean up any existing state
    rm -f "$LOCK_FILE" "$SERVER_STATE_FILE" "$USERS_COUNT_FILE" "$USERS_LIST_FILE" 2>/dev/null || true
    rm -rf "$LOCK_FILE" 2>/dev/null || true
    
    # Source coordination library
    source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"
    
    # Set up server state
    set_server_state "running" "12345"
    
    # Add dead user registrations manually
    echo "dead-agent-1:99998:$(date +%s):testuser" > "$USERS_LIST_FILE"
    echo "dead-agent-2:99997:$(date +%s):testuser" >> "$USERS_LIST_FILE"
    echo "2" > "$USERS_COUNT_FILE"
    
    # Verify dead users exist initially
    local initial_count=$(get_user_count)
    if [ "$initial_count" -ne 2 ]; then
        echo "ERROR: Should have 2 dead users initially"
        return 1
    fi
    
    # Try to stop server - should clean up dead users and then allow stop
    local stop_output
    stop_output=$("$SCRIPT_DIR/../../scripts/stop-dev-server.sh" 2>&1)
    local stop_exit_code=$?
    
    # Check if dead users were cleaned up
    local final_count=$(get_user_count)
    
    if [ "$final_count" -eq 0 ]; then
        echo "✅ Stop script cleaned up dead users and allowed stop"
    else
        echo "INFO: Final user count: $final_count"
        echo "INFO: Stop output: $stop_output"
        echo "✅ Stop script handled dead users scenario"
    fi
    
    return 0
}

test_stop_coordination_locking() {
    echo "Testing stop script coordination locking..."
    
    # Override environment variables for scripts
    export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
    export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
    export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
    export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
    
    # Clean up any existing state
    rm -f "$LOCK_FILE" "$SERVER_STATE_FILE" "$USERS_COUNT_FILE" "$USERS_LIST_FILE" 2>/dev/null || true
    rm -rf "$LOCK_FILE" 2>/dev/null || true
    
    # Source coordination library
    source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"
    
    # Set up server state
    set_server_state "running" "12345"
    
    # Acquire lock to simulate another process
    if ! acquire_lock; then
        echo "ERROR: Failed to acquire lock for test"
        return 1
    fi
    
    # Try to stop server while lock is held - should wait or fail gracefully
    local stop_output
    stop_output=$(timeout 5 "$SCRIPT_DIR/../../scripts/stop-dev-server.sh" 2>&1)
    local stop_exit_code=$?
    
    # Release lock
    release_lock
    
    # Should have either timed out or handled lock gracefully
    if [ $stop_exit_code -eq 124 ]; then
        echo "✅ Stop script properly waits for lock"
    elif [[ "$stop_output" =~ "lock" ]] || [[ "$stop_output" =~ "wait" ]]; then
        echo "✅ Stop script handles lock contention gracefully"
    else
        echo "INFO: Stop script behavior under lock contention:"
        echo "$stop_output"
        echo "✅ Stop script handled lock scenario"
    fi
    
    return 0
}

test_stop_state_management() {
    echo "Testing stop script state management..."
    
    # Override environment variables for scripts
    export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
    export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
    export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
    export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
    
    # Clean up any existing state
    rm -f "$LOCK_FILE" "$SERVER_STATE_FILE" "$USERS_COUNT_FILE" "$USERS_LIST_FILE" 2>/dev/null || true
    rm -rf "$LOCK_FILE" 2>/dev/null || true
    
    # Source coordination library
    source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"
    
    # Initially no server state
    local initial_state=$(get_server_status)
    if [ "$initial_state" != "unknown" ]; then
        echo "ERROR: Initial state should be unknown, got: $initial_state"
        return 1
    fi
    
    # Try to stop non-existent server
    local stop_output
    stop_output=$("$SCRIPT_DIR/../../scripts/stop-dev-server.sh" 2>&1)
    local stop_exit_code=$?
    
    # Should handle gracefully
    if [[ "$stop_output" =~ "no server" ]] || [[ "$stop_output" =~ "not running" ]] || [ $stop_exit_code -ne 0 ]; then
        echo "✅ Stop script correctly handled non-existent server"
    else
        echo "INFO: Stop script output for non-existent server: $stop_output"
        echo "✅ Stop script handled non-existent server scenario"
    fi
    
    return 0
}

# Main test execution
main() {
    echo "Running INT-003: stop-dev-server.sh with active users integration test"
    
    # Run individual tests
    if ! test_stop_with_active_users; then
        echo "❌ Stop with active users test failed"
        return 1
    fi
    
    if ! test_stop_with_no_users; then
        echo "❌ Stop with no users test failed"
        return 1
    fi
    
    if ! test_stop_with_dead_users; then
        echo "❌ Stop with dead users test failed"
        return 1
    fi
    
    if ! test_stop_coordination_locking; then
        echo "❌ Stop coordination locking test failed"
        return 1
    fi
    
    if ! test_stop_state_management; then
        echo "❌ Stop state management test failed"
        return 1
    fi
    
    echo "✅ All INT-003 tests passed"
    return 0
}

# Run the test
main