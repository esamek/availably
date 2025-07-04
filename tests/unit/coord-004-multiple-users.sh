#!/bin/bash

# Test ID: COORD-004
# Description: Multiple user tracking
# Expected: System correctly tracks multiple active users

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR="$1"

# Source the coordination library with overridden paths
source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"

# Test functions
test_multiple_user_registration() {
    echo "Testing multiple user registration..."
    
    # Register multiple users
    local user_agents=("ui-polish" "algorithm-dev" "realtime-features" "interaction-enhancement")
    local expected_count=0
    
    for agent in "${user_agents[@]}"; do
        if ! register_server_user "$agent"; then
            echo "ERROR: Failed to register agent: $agent"
            return 1
        fi
        
        expected_count=$((expected_count + 1))
        local current_count=$(get_user_count)
        
        if [ "$current_count" -ne "$expected_count" ]; then
            echo "ERROR: User count should be $expected_count after registering $agent, got $current_count"
            return 1
        fi
    done
    
    # Verify final count
    local final_count=$(get_user_count)
    if [ "$final_count" -ne 4 ]; then
        echo "ERROR: Final user count should be 4, got $final_count"
        return 1
    fi
    
    echo "✅ Multiple user registration successful"
    return 0
}

test_user_list_accuracy() {
    echo "Testing user list accuracy..."
    
    # Should have 4 users from previous test
    local user_list_output=$(list_server_users)
    
    # Verify all expected users are listed
    local expected_users=("ui-polish" "algorithm-dev" "realtime-features" "interaction-enhancement")
    
    for user in "${expected_users[@]}"; do
        if [[ ! "$user_list_output" =~ "$user" ]]; then
            echo "ERROR: User list should contain $user"
            echo "Got: $user_list_output"
            return 1
        fi
    done
    
    # Verify list contains correct metadata
    if [[ ! "$user_list_output" =~ "PID:" ]]; then
        echo "ERROR: User list should contain PID information"
        echo "Got: $user_list_output"
        return 1
    fi
    
    if [[ ! "$user_list_output" =~ "User:" ]]; then
        echo "ERROR: User list should contain user information"
        echo "Got: $user_list_output"
        return 1
    fi
    
    if [[ ! "$user_list_output" =~ "Age:" ]]; then
        echo "ERROR: User list should contain age information"
        echo "Got: $user_list_output"
        return 1
    fi
    
    echo "✅ User list accuracy verified"
    return 0
}

test_selective_user_unregistration() {
    echo "Testing selective user unregistration..."
    
    # Unregister users one by one
    local users_to_remove=("algorithm-dev" "interaction-enhancement")
    local remaining_count=4
    
    for user in "${users_to_remove[@]}"; do
        local remaining_users=$(unregister_server_user "$user")
        remaining_count=$((remaining_count - 1))
        
        if [ $? -ne "$remaining_count" ]; then
            echo "ERROR: Unregister should return $remaining_count remaining users"
            return 1
        fi
        
        local current_count=$(get_user_count)
        if [ "$current_count" -ne "$remaining_count" ]; then
            echo "ERROR: User count should be $remaining_count after removing $user, got $current_count"
            return 1
        fi
        
        # Verify user is removed from list
        local user_list_output=$(list_server_users)
        if [[ "$user_list_output" =~ "$user" ]]; then
            echo "ERROR: User $user should be removed from list"
            echo "Got: $user_list_output"
            return 1
        fi
    done
    
    # Verify remaining users are still there
    local final_list_output=$(list_server_users)
    local remaining_users=("ui-polish" "realtime-features")
    
    for user in "${remaining_users[@]}"; do
        if [[ ! "$final_list_output" =~ "$user" ]]; then
            echo "ERROR: User $user should still be in list"
            echo "Got: $final_list_output"
            return 1
        fi
    done
    
    echo "✅ Selective user unregistration successful"
    return 0
}

test_concurrent_user_operations() {
    echo "Testing concurrent user operations..."
    
    # Start multiple processes doing user operations concurrently
    local pids=()
    local agent_names=("concurrent-1" "concurrent-2" "concurrent-3" "concurrent-4" "concurrent-5")
    
    # Register users concurrently
    for agent in "${agent_names[@]}"; do
        (
            export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
            export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
            export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
            export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
            
            source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"
            
            register_server_user "$agent"
            sleep 0.5
            unregister_server_user "$agent"
        ) &
        pids+=($!)
    done
    
    # Wait for all concurrent operations to complete
    for pid in "${pids[@]}"; do
        wait $pid
    done
    
    # After concurrent operations, count should be back to 2 (from previous test)
    local final_count=$(get_user_count)
    if [ "$final_count" -ne 2 ]; then
        echo "ERROR: User count should be 2 after concurrent operations, got $final_count"
        return 1
    fi
    
    # Verify original users are still there
    local final_list_output=$(list_server_users)
    local expected_remaining=("ui-polish" "realtime-features")
    
    for user in "${expected_remaining[@]}"; do
        if [[ ! "$final_list_output" =~ "$user" ]]; then
            echo "ERROR: Original user $user should still be registered"
            echo "Got: $final_list_output"
            return 1
        fi
    done
    
    echo "✅ Concurrent user operations successful"
    return 0
}

test_user_age_tracking() {
    echo "Testing user age tracking..."
    
    # Register a new user
    register_server_user "age-test-agent"
    
    # Wait a bit
    sleep 2
    
    # Check user list for age information
    local user_list_output=$(list_server_users)
    
    # Verify age is tracked and reasonable
    if [[ ! "$user_list_output" =~ "age-test-agent" ]]; then
        echo "ERROR: Age test agent should be in user list"
        echo "Got: $user_list_output"
        return 1
    fi
    
    # Extract age for our test agent
    local age_line=$(echo "$user_list_output" | grep "age-test-agent")
    if [[ ! "$age_line" =~ Age:\ ([0-9]+)s ]]; then
        echo "ERROR: Age information not found or malformed"
        echo "Got: $age_line"
        return 1
    fi
    
    local age="${BASH_REMATCH[1]}"
    if [ "$age" -lt 1 ] || [ "$age" -gt 10 ]; then
        echo "ERROR: Age should be between 1-10 seconds, got ${age}s"
        return 1
    fi
    
    # Clean up
    unregister_server_user "age-test-agent"
    
    echo "✅ User age tracking successful"
    return 0
}

test_server_stop_readiness() {
    echo "Testing server stop readiness..."
    
    # Should have 2 users remaining from previous tests
    if can_stop_server; then
        echo "ERROR: Server should not be ready to stop with active users"
        return 1
    fi
    
    # Remove one user
    unregister_server_user "ui-polish"
    
    # Should still not be ready
    if can_stop_server; then
        echo "ERROR: Server should not be ready to stop with 1 active user"
        return 1
    fi
    
    # Remove last user
    unregister_server_user "realtime-features"
    
    # Now should be ready to stop
    if ! can_stop_server; then
        echo "ERROR: Server should be ready to stop with no active users"
        return 1
    fi
    
    echo "✅ Server stop readiness logic successful"
    return 0
}

test_large_user_scale() {
    echo "Testing large user scale..."
    
    # Register many users to test scalability
    local num_users=50
    
    for i in $(seq 1 $num_users); do
        register_server_user "scale-test-agent-$i"
    done
    
    # Verify all users registered
    local final_count=$(get_user_count)
    if [ "$final_count" -ne "$num_users" ]; then
        echo "ERROR: Should have $num_users users, got $final_count"
        return 1
    fi
    
    # Verify user list performance (should complete reasonably quickly)
    local start_time=$(date +%s)
    local user_list_output=$(list_server_users)
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ "$duration" -gt 5 ]; then
        echo "ERROR: User list operation took too long: ${duration}s"
        return 1
    fi
    
    # Verify list contains expected number of entries
    local line_count=$(echo "$user_list_output" | grep "scale-test-agent" | wc -l)
    if [ "$line_count" -ne "$num_users" ]; then
        echo "ERROR: User list should contain $num_users entries, got $line_count"
        return 1
    fi
    
    # Clean up all users
    for i in $(seq 1 $num_users); do
        unregister_server_user "scale-test-agent-$i"
    done
    
    # Verify cleanup
    local cleanup_count=$(get_user_count)
    if [ "$cleanup_count" -ne 0 ]; then
        echo "ERROR: All users should be cleaned up, got $cleanup_count"
        return 1
    fi
    
    echo "✅ Large user scale test successful"
    return 0
}

# Main test execution
main() {
    echo "Running COORD-004: Multiple user tracking test"
    
    # Run individual tests
    if ! test_multiple_user_registration; then
        echo "❌ Multiple user registration test failed"
        return 1
    fi
    
    if ! test_user_list_accuracy; then
        echo "❌ User list accuracy test failed"
        return 1
    fi
    
    if ! test_selective_user_unregistration; then
        echo "❌ Selective user unregistration test failed"
        return 1
    fi
    
    if ! test_concurrent_user_operations; then
        echo "❌ Concurrent user operations test failed"
        return 1
    fi
    
    if ! test_user_age_tracking; then
        echo "❌ User age tracking test failed"
        return 1
    fi
    
    if ! test_server_stop_readiness; then
        echo "❌ Server stop readiness test failed"
        return 1
    fi
    
    if ! test_large_user_scale; then
        echo "❌ Large user scale test failed"
        return 1
    fi
    
    echo "✅ All COORD-004 tests passed"
    return 0
}

# Run the test
main