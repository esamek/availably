#!/bin/bash

# Test ID: COORD-002
# Description: Dead user cleanup
# Expected: Dead process registrations are automatically removed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR="$1"

# Source the coordination library with overridden paths
source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"

# Test functions
test_dead_user_cleanup() {
    echo "Testing dead user cleanup..."
    
    # Add a dead user registration manually
    local fake_pid=99999
    local timestamp=$(date +%s)
    echo "test-dead-agent:$fake_pid:$timestamp:$USER" >> "$USERS_LIST_FILE"
    echo "1" > "$USERS_COUNT_FILE"
    
    # Verify dead user exists
    local initial_count=$(get_user_count)
    if [ "$initial_count" -ne 1 ]; then
        echo "ERROR: Expected 1 user initially, got $initial_count"
        return 1
    fi
    
    # Run cleanup
    cleanup_dead_users
    
    # Verify dead user was removed
    local count_after_cleanup=$(get_user_count)
    if [ "$count_after_cleanup" -ne 0 ]; then
        echo "ERROR: Dead user should have been cleaned up, count is $count_after_cleanup"
        return 1
    fi
    
    # Verify users list is clean
    if [ -f "$USERS_LIST_FILE" ]; then
        local remaining_users=$(cat "$USERS_LIST_FILE")
        if [ -n "$remaining_users" ]; then
            echo "ERROR: Users list should be empty after cleanup"
            echo "Got: $remaining_users"
            return 1
        fi
    fi
    
    echo "✅ Dead user cleanup successful"
    return 0
}

test_mixed_dead_and_alive_users() {
    echo "Testing mixed dead and alive users..."
    
    # Add alive user (current process)
    register_server_user "test-alive-agent"
    
    # Add dead user manually
    local fake_pid=99998
    local timestamp=$(date +%s)
    echo "test-dead-agent:$fake_pid:$timestamp:$USER" >> "$USERS_LIST_FILE"
    echo "2" > "$USERS_COUNT_FILE"
    
    # Verify we have 2 users
    local initial_count=$(get_user_count)
    if [ "$initial_count" -ne 2 ]; then
        echo "ERROR: Expected 2 users initially, got $initial_count"
        return 1
    fi
    
    # Run cleanup
    cleanup_dead_users
    
    # Verify only alive user remains
    local count_after_cleanup=$(get_user_count)
    if [ "$count_after_cleanup" -ne 1 ]; then
        echo "ERROR: Should have 1 user after cleanup, got $count_after_cleanup"
        return 1
    fi
    
    # Verify alive user is still there
    local user_list_output=$(list_server_users)
    if [[ ! "$user_list_output" =~ "test-alive-agent" ]]; then
        echo "ERROR: Alive user should still be in list"
        echo "Got: $user_list_output"
        return 1
    fi
    
    # Verify dead user is gone
    if [[ "$user_list_output" =~ "test-dead-agent" ]]; then
        echo "ERROR: Dead user should be removed from list"
        echo "Got: $user_list_output"
        return 1
    fi
    
    # Clean up
    unregister_server_user "test-alive-agent"
    
    echo "✅ Mixed dead and alive users cleanup successful"
    return 0
}

test_cleanup_during_registration() {
    echo "Testing cleanup during registration..."
    
    # Add dead user manually
    local fake_pid=99997
    local timestamp=$(date +%s)
    echo "test-dead-agent:$fake_pid:$timestamp:$USER" >> "$USERS_LIST_FILE"
    echo "1" > "$USERS_COUNT_FILE"
    
    # Register new user (should trigger cleanup)
    if ! register_server_user "test-new-agent"; then
        echo "ERROR: Failed to register new user"
        return 1
    fi
    
    # Verify only new user remains
    local count_after_register=$(get_user_count)
    if [ "$count_after_register" -ne 1 ]; then
        echo "ERROR: Should have 1 user after registration, got $count_after_register"
        return 1
    fi
    
    # Verify correct user is registered
    local user_list_output=$(list_server_users)
    if [[ ! "$user_list_output" =~ "test-new-agent" ]]; then
        echo "ERROR: New user should be in list"
        echo "Got: $user_list_output"
        return 1
    fi
    
    if [[ "$user_list_output" =~ "test-dead-agent" ]]; then
        echo "ERROR: Dead user should be cleaned up during registration"
        echo "Got: $user_list_output"
        return 1
    fi
    
    # Clean up
    unregister_server_user "test-new-agent"
    
    echo "✅ Cleanup during registration successful"
    return 0
}

test_cleanup_during_unregistration() {
    echo "Testing cleanup during unregistration..."
    
    # Register alive user
    register_server_user "test-alive-agent"
    
    # Add dead user manually
    local fake_pid=99996
    local timestamp=$(date +%s)
    echo "test-dead-agent:$fake_pid:$timestamp:$USER" >> "$USERS_LIST_FILE"
    echo "2" > "$USERS_COUNT_FILE"
    
    # Unregister alive user (should trigger cleanup)
    if ! unregister_server_user "test-alive-agent"; then
        echo "ERROR: Failed to unregister alive user"
        return 1
    fi
    
    # Verify no users remain
    local count_after_unregister=$(get_user_count)
    if [ "$count_after_unregister" -ne 0 ]; then
        echo "ERROR: Should have 0 users after unregistration and cleanup, got $count_after_unregister"
        return 1
    fi
    
    # Verify users list is clean
    if [ -f "$USERS_LIST_FILE" ]; then
        local remaining_users=$(cat "$USERS_LIST_FILE")
        if [ -n "$remaining_users" ]; then
            echo "ERROR: Users list should be empty after cleanup"
            echo "Got: $remaining_users"
            return 1
        fi
    fi
    
    echo "✅ Cleanup during unregistration successful"
    return 0
}

test_multiple_dead_users() {
    echo "Testing multiple dead users cleanup..."
    
    # Add multiple dead users manually
    local fake_pids=(99995 99994 99993)
    local timestamp=$(date +%s)
    
    for pid in "${fake_pids[@]}"; do
        echo "test-dead-agent-$pid:$pid:$timestamp:$USER" >> "$USERS_LIST_FILE"
    done
    echo "3" > "$USERS_COUNT_FILE"
    
    # Verify we have 3 users
    local initial_count=$(get_user_count)
    if [ "$initial_count" -ne 3 ]; then
        echo "ERROR: Expected 3 users initially, got $initial_count"
        return 1
    fi
    
    # Run cleanup
    cleanup_dead_users
    
    # Verify all dead users were removed
    local count_after_cleanup=$(get_user_count)
    if [ "$count_after_cleanup" -ne 0 ]; then
        echo "ERROR: All dead users should have been cleaned up, count is $count_after_cleanup"
        return 1
    fi
    
    # Verify users list is clean
    if [ -f "$USERS_LIST_FILE" ]; then
        local remaining_users=$(cat "$USERS_LIST_FILE")
        if [ -n "$remaining_users" ]; then
            echo "ERROR: Users list should be empty after cleanup"
            echo "Got: $remaining_users"
            return 1
        fi
    fi
    
    echo "✅ Multiple dead users cleanup successful"
    return 0
}

test_cleanup_with_corrupted_user_file() {
    echo "Testing cleanup with corrupted user file..."
    
    # Create corrupted user file
    echo "malformed-entry-without-colons" > "$USERS_LIST_FILE"
    echo "another:malformed:entry" >> "$USERS_LIST_FILE"
    echo "test-valid-agent:$$:$(date +%s):$USER" >> "$USERS_LIST_FILE"
    echo "3" > "$USERS_COUNT_FILE"
    
    # Run cleanup (should handle corrupted entries gracefully)
    cleanup_dead_users
    
    # Verify only valid entry remains
    local count_after_cleanup=$(get_user_count)
    if [ "$count_after_cleanup" -ne 1 ]; then
        echo "ERROR: Should have 1 user after cleanup, got $count_after_cleanup"
        return 1
    fi
    
    # Verify correct user remains
    local user_list_output=$(list_server_users)
    if [[ ! "$user_list_output" =~ "test-valid-agent" ]]; then
        echo "ERROR: Valid user should remain after cleanup"
        echo "Got: $user_list_output"
        return 1
    fi
    
    # Clean up
    unregister_server_user "test-valid-agent"
    
    echo "✅ Cleanup with corrupted user file successful"
    return 0
}

# Main test execution
main() {
    echo "Running COORD-002: Dead user cleanup test"
    
    # Run individual tests
    if ! test_dead_user_cleanup; then
        echo "❌ Dead user cleanup test failed"
        return 1
    fi
    
    if ! test_mixed_dead_and_alive_users; then
        echo "❌ Mixed dead and alive users test failed"
        return 1
    fi
    
    if ! test_cleanup_during_registration; then
        echo "❌ Cleanup during registration test failed"
        return 1
    fi
    
    if ! test_cleanup_during_unregistration; then
        echo "❌ Cleanup during unregistration test failed"
        return 1
    fi
    
    if ! test_multiple_dead_users; then
        echo "❌ Multiple dead users test failed"
        return 1
    fi
    
    if ! test_cleanup_with_corrupted_user_file; then
        echo "❌ Cleanup with corrupted user file test failed"
        return 1
    fi
    
    echo "✅ All COORD-002 tests passed"
    return 0
}

# Run the test
main