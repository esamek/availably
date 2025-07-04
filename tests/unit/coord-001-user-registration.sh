#!/bin/bash

# Test ID: COORD-001
# Description: User registration and unregistration
# Expected: User count increments/decrements correctly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR="$1"

# Source the coordination library with overridden paths
source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"

# Test functions
test_user_registration() {
    echo "Testing user registration..."
    
    # Clean up any existing state files to ensure clean start
    rm -f "$USERS_COUNT_FILE" "$USERS_LIST_FILE" "$SERVER_STATE_FILE" 2>/dev/null || true
    rm -rf "$LOCK_FILE" 2>/dev/null || true
    
    # Initial user count should be 0
    local initial_count=$(get_user_count)
    if [ "$initial_count" -ne 0 ]; then
        echo "ERROR: Initial user count should be 0, got $initial_count"
        return 1
    fi
    
    # Register first user
    local agent1="test-agent-1"
    if ! register_server_user "$agent1"; then
        echo "ERROR: Failed to register first user: $agent1"
        return 1
    fi
    
    # Verify user count increased
    local count_after_first=$(get_user_count)
    if [ "$count_after_first" -ne 1 ]; then
        echo "ERROR: User count should be 1 after first registration, got $count_after_first"
        return 1
    fi
    
    # Verify user is in list
    local user_list=$(list_server_users)
    if [[ ! "$user_list" =~ "$agent1" ]]; then
        echo "ERROR: User list should contain $agent1"
        echo "Got: $user_list"
        return 1
    fi
    
    # Register second user
    local agent2="test-agent-2"
    if ! register_server_user "$agent2"; then
        echo "ERROR: Failed to register second user: $agent2"
        return 1
    fi
    
    # Verify user count increased
    local count_after_second=$(get_user_count)
    if [ "$count_after_second" -ne 2 ]; then
        echo "ERROR: User count should be 2 after second registration, got $count_after_second"
        return 1
    fi
    
    # Verify both users are in list
    local user_list2=$(list_server_users)
    if [[ ! "$user_list2" =~ "$agent1" ]]; then
        echo "ERROR: User list should contain $agent1"
        echo "Got: $user_list2"
        return 1
    fi
    if [[ ! "$user_list2" =~ "$agent2" ]]; then
        echo "ERROR: User list should contain $agent2"
        echo "Got: $user_list2"
        return 1
    fi
    
    echo "✅ User registration successful"
    return 0
}

test_user_unregistration() {
    echo "Testing user unregistration..."
    
    # Should have 2 users from previous test
    local initial_count=$(get_user_count)
    if [ "$initial_count" -ne 2 ]; then
        echo "ERROR: Expected 2 users for unregistration test, got $initial_count"
        return 1
    fi
    
    # Unregister first user
    unregister_server_user "test-agent-1"
    local exit_code=$?
    if [ $exit_code -ne 1 ]; then
        echo "ERROR: Unregister should return 1 (remaining users), got $exit_code"
        return 1
    fi
    
    # Verify user count decreased
    local count_after_first=$(get_user_count)
    if [ "$count_after_first" -ne 1 ]; then
        echo "ERROR: User count should be 1 after first unregistration, got $count_after_first"
        return 1
    fi
    
    # Unregister second user
    unregister_server_user "test-agent-2"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "ERROR: Unregister should return 0 (no remaining users), got $exit_code"
        return 1
    fi
    
    # Verify user count is 0
    local count_after_second=$(get_user_count)
    if [ "$count_after_second" -ne 0 ]; then
        echo "ERROR: User count should be 0 after final unregistration, got $count_after_second"
        return 1
    fi
    
    echo "✅ User unregistration successful"
    return 0
}

test_duplicate_registration() {
    echo "Testing duplicate registration..."
    
    # Register user
    if ! register_server_user "test-agent-duplicate"; then
        echo "ERROR: Failed to register user initially"
        return 1
    fi
    
    # Verify count is 1
    local count_after_first=$(get_user_count)
    if [ "$count_after_first" -ne 1 ]; then
        echo "ERROR: User count should be 1 after registration, got $count_after_first"
        return 1
    fi
    
    # Try to register same user again
    if ! register_server_user "test-agent-duplicate"; then
        echo "ERROR: Duplicate registration should succeed (no-op)"
        return 1
    fi
    
    # Verify count is still 1
    local count_after_duplicate=$(get_user_count)
    if [ "$count_after_duplicate" -ne 1 ]; then
        echo "ERROR: User count should still be 1 after duplicate registration, got $count_after_duplicate"
        return 1
    fi
    
    # Clean up
    unregister_server_user "test-agent-duplicate"
    
    echo "✅ Duplicate registration handled correctly"
    return 0
}

test_unregister_non_existent() {
    echo "Testing unregistration of non-existent user..."
    
    # Verify no users initially
    local initial_count=$(get_user_count)
    if [ "$initial_count" -ne 0 ]; then
        echo "ERROR: Expected 0 users initially, got $initial_count"
        return 1
    fi
    
    # Try to unregister non-existent user
    if ! unregister_server_user "non-existent-agent"; then
        echo "ERROR: Unregistering non-existent user should succeed (no-op)"
        return 1
    fi
    
    # Verify count is still 0
    local count_after_unregister=$(get_user_count)
    if [ "$count_after_unregister" -ne 0 ]; then
        echo "ERROR: User count should still be 0 after unregistering non-existent user, got $count_after_unregister"
        return 1
    fi
    
    echo "✅ Non-existent user unregistration handled correctly"
    return 0
}

test_user_list_management() {
    echo "Testing user list management..."
    
    # Register multiple users
    register_server_user "test-agent-alpha"
    register_server_user "test-agent-beta"
    register_server_user "test-agent-gamma"
    
    # Verify user list
    local user_list_output=$(list_server_users)
    
    # Check that all users are listed
    if [[ ! "$user_list_output" =~ "test-agent-alpha" ]]; then
        echo "ERROR: User list should contain test-agent-alpha"
        echo "Got: $user_list_output"
        return 1
    fi
    
    if [[ ! "$user_list_output" =~ "test-agent-beta" ]]; then
        echo "ERROR: User list should contain test-agent-beta"
        echo "Got: $user_list_output"
        return 1
    fi
    
    if [[ ! "$user_list_output" =~ "test-agent-gamma" ]]; then
        echo "ERROR: User list should contain test-agent-gamma"
        echo "Got: $user_list_output"
        return 1
    fi
    
    # Unregister one user
    unregister_server_user "test-agent-beta"
    
    # Verify user list updated
    local updated_list_output=$(list_server_users)
    
    if [[ "$updated_list_output" =~ "test-agent-beta" ]]; then
        echo "ERROR: User list should not contain test-agent-beta after unregistration"
        echo "Got: $updated_list_output"
        return 1
    fi
    
    if [[ ! "$updated_list_output" =~ "test-agent-alpha" ]]; then
        echo "ERROR: User list should still contain test-agent-alpha"
        echo "Got: $updated_list_output"
        return 1
    fi
    
    if [[ ! "$updated_list_output" =~ "test-agent-gamma" ]]; then
        echo "ERROR: User list should still contain test-agent-gamma"
        echo "Got: $updated_list_output"
        return 1
    fi
    
    # Clean up
    unregister_server_user "test-agent-alpha"
    unregister_server_user "test-agent-gamma"
    
    echo "✅ User list management successful"
    return 0
}

test_default_agent_id() {
    echo "Testing default agent ID..."
    
    # Register without specifying agent ID (should use default)
    if ! register_server_user; then
        echo "ERROR: Failed to register with default agent ID"
        return 1
    fi
    
    # Verify user count increased
    local count_after_register=$(get_user_count)
    if [ "$count_after_register" -ne 1 ]; then
        echo "ERROR: User count should be 1 after registration, got $count_after_register"
        return 1
    fi
    
    # Verify user appears in list
    local user_list_output=$(list_server_users)
    if [[ ! "$user_list_output" =~ "agent-$$" ]]; then
        echo "ERROR: User list should contain default agent ID (agent-$$)"
        echo "Got: $user_list_output"
        return 1
    fi
    
    # Unregister without specifying agent ID
    if ! unregister_server_user; then
        echo "ERROR: Failed to unregister with default agent ID"
        return 1
    fi
    
    # Verify user count back to 0
    local count_after_unregister=$(get_user_count)
    if [ "$count_after_unregister" -ne 0 ]; then
        echo "ERROR: User count should be 0 after unregistration, got $count_after_unregister"
        return 1
    fi
    
    echo "✅ Default agent ID handling successful"
    return 0
}

# Main test execution
main() {
    echo "Running COORD-001: User registration and unregistration test"
    
    # Run individual tests
    if ! test_user_registration; then
        echo "❌ User registration test failed"
        return 1
    fi
    
    if ! test_user_unregistration; then
        echo "❌ User unregistration test failed"
        return 1
    fi
    
    if ! test_duplicate_registration; then
        echo "❌ Duplicate registration test failed"
        return 1
    fi
    
    if ! test_unregister_non_existent; then
        echo "❌ Unregister non-existent user test failed"
        return 1
    fi
    
    if ! test_user_list_management; then
        echo "❌ User list management test failed"
        return 1
    fi
    
    if ! test_default_agent_id; then
        echo "❌ Default agent ID test failed"
        return 1
    fi
    
    echo "✅ All COORD-001 tests passed"
    return 0
}

# Run the test
main