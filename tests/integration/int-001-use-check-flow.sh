#!/bin/bash

# Test ID: INT-001
# Description: use-dev-server.sh → check-dev-server.sh flow
# Expected: Registration shows up in status checks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR="$1"

# Test functions
test_use_check_integration() {
    echo "Testing use-dev-server.sh → check-dev-server.sh integration..."
    
    # Override environment variables for scripts
    export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
    export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
    export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
    export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
    
    # Clean up any existing state
    rm -f "$LOCK_FILE" "$SERVER_STATE_FILE" "$USERS_COUNT_FILE" "$USERS_LIST_FILE" 2>/dev/null || true
    rm -rf "$LOCK_FILE" 2>/dev/null || true
    
    # Create a test agent ID
    local test_agent="int-test-agent-1"
    
    # Step 1: Use use-dev-server.sh to register as user
    local use_output=$("$SCRIPT_DIR/../../scripts/use-dev-server.sh" "$test_agent" 2>&1)
    local use_exit_code=$?
    
    if [ $use_exit_code -ne 0 ]; then
        echo "ERROR: use-dev-server.sh failed with exit code $use_exit_code"
        echo "Output: $use_output"
        return 1
    fi
    
    # Verify registration was successful
    if [[ ! "$use_output" =~ "Registered as server user: $test_agent" ]]; then
        echo "ERROR: use-dev-server.sh should show registration success"
        echo "Output: $use_output"
        return 1
    fi
    
    # Step 2: Use check-dev-server.sh to verify registration shows up
    local check_output=$("$SCRIPT_DIR/../../scripts/check-dev-server.sh" 2>&1)
    local check_exit_code=$?
    
    if [ $check_exit_code -ne 0 ]; then
        echo "ERROR: check-dev-server.sh failed with exit code $check_exit_code"
        echo "Output: $check_output"
        return 1
    fi
    
    # Verify agent appears in status
    if [[ ! "$check_output" =~ "$test_agent" ]]; then
        echo "ERROR: check-dev-server.sh should show registered agent"
        echo "Output: $check_output"
        return 1
    fi
    
    # Verify user count is shown
    if [[ ! "$check_output" =~ "Users: 1" ]]; then
        echo "ERROR: check-dev-server.sh should show 1 user"
        echo "Output: $check_output"
        return 1
    fi
    
    # Step 3: Use release-dev-server.sh to unregister
    local release_output=$("$SCRIPT_DIR/../../scripts/release-dev-server.sh" "$test_agent" 2>&1)
    local release_exit_code=$?
    
    if [ $release_exit_code -ne 0 ]; then
        echo "ERROR: release-dev-server.sh failed with exit code $release_exit_code"
        echo "Output: $release_output"
        return 1
    fi
    
    # Step 4: Verify agent is no longer shown in status
    local final_check_output=$("$SCRIPT_DIR/../../scripts/check-dev-server.sh" 2>&1)
    
    if [[ "$final_check_output" =~ "$test_agent" ]]; then
        echo "ERROR: check-dev-server.sh should not show unregistered agent"
        echo "Output: $final_check_output"
        return 1
    fi
    
    # Verify user count is 0
    if [[ ! "$final_check_output" =~ "Users: 0" ]]; then
        echo "ERROR: check-dev-server.sh should show 0 users after release"
        echo "Output: $final_check_output"
        return 1
    fi
    
    echo "✅ use-dev-server.sh → check-dev-server.sh integration successful"
    return 0
}

test_multiple_agents_flow() {
    echo "Testing multiple agents use-check flow..."
    
    # Override environment variables for scripts
    export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
    export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
    export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
    export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
    
    # Clean up any existing state
    rm -f "$LOCK_FILE" "$SERVER_STATE_FILE" "$USERS_COUNT_FILE" "$USERS_LIST_FILE" 2>/dev/null || true
    rm -rf "$LOCK_FILE" 2>/dev/null || true
    
    local agents=("agent-1" "agent-2" "agent-3")
    
    # Register multiple agents
    for agent in "${agents[@]}"; do
        local use_output=$("$SCRIPT_DIR/../../scripts/use-dev-server.sh" "$agent" 2>&1)
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to register agent: $agent"
            echo "Output: $use_output"
            return 1
        fi
    done
    
    # Check that all agents are shown
    local check_output=$("$SCRIPT_DIR/../../scripts/check-dev-server.sh" 2>&1)
    
    for agent in "${agents[@]}"; do
        if [[ ! "$check_output" =~ "$agent" ]]; then
            echo "ERROR: Agent $agent should be shown in status"
            echo "Output: $check_output"
            return 1
        fi
    done
    
    # Verify user count
    if [[ ! "$check_output" =~ "Users: 3" ]]; then
        echo "ERROR: Should show 3 users"
        echo "Output: $check_output"
        return 1
    fi
    
    # Release agents one by one and verify count decreases
    local expected_count=3
    for agent in "${agents[@]}"; do
        "$SCRIPT_DIR/../../scripts/release-dev-server.sh" "$agent" >/dev/null 2>&1
        expected_count=$((expected_count - 1))
        
        local check_output=$("$SCRIPT_DIR/../../scripts/check-dev-server.sh" 2>&1)
        if [[ ! "$check_output" =~ "Users: $expected_count" ]]; then
            echo "ERROR: Should show $expected_count users after releasing $agent"
            echo "Output: $check_output"
            return 1
        fi
    done
    
    echo "✅ Multiple agents use-check flow successful"
    return 0
}

test_error_handling() {
    echo "Testing error handling in use-check flow..."
    
    # Override environment variables for scripts
    export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
    export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
    export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
    export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
    
    # Clean up any existing state
    rm -f "$LOCK_FILE" "$SERVER_STATE_FILE" "$USERS_COUNT_FILE" "$USERS_LIST_FILE" 2>/dev/null || true
    rm -rf "$LOCK_FILE" 2>/dev/null || true
    
    # Test 1: check-dev-server.sh with no registered users
    local check_output=$("$SCRIPT_DIR/../../scripts/check-dev-server.sh" 2>&1)
    
    if [[ ! "$check_output" =~ "Users: 0" ]]; then
        echo "ERROR: Should show 0 users when none are registered"
        echo "Output: $check_output"
        return 1
    fi
    
    # Test 2: release-dev-server.sh with non-existent agent
    local release_output=$("$SCRIPT_DIR/../../scripts/release-dev-server.sh" "non-existent-agent" 2>&1)
    local release_exit_code=$?
    
    # Should succeed (no-op) but show warning
    if [ $release_exit_code -ne 0 ]; then
        echo "ERROR: release-dev-server.sh should succeed for non-existent agent"
        echo "Output: $release_output"
        return 1
    fi
    
    # Test 3: Double registration of same agent
    local agent="duplicate-test-agent"
    
    # First registration
    "$SCRIPT_DIR/../../scripts/use-dev-server.sh" "$agent" >/dev/null 2>&1
    
    # Second registration (should succeed with warning)
    local duplicate_output=$("$SCRIPT_DIR/../../scripts/use-dev-server.sh" "$agent" 2>&1)
    
    if [[ ! "$duplicate_output" =~ "already registered" ]]; then
        echo "ERROR: Duplicate registration should show warning"
        echo "Output: $duplicate_output"
        return 1
    fi
    
    # Clean up
    "$SCRIPT_DIR/../../scripts/release-dev-server.sh" "$agent" >/dev/null 2>&1
    
    echo "✅ Error handling in use-check flow successful"
    return 0
}

# Main test execution
main() {
    echo "Running INT-001: use-dev-server.sh → check-dev-server.sh integration test"
    
    # Run individual tests
    if ! test_use_check_integration; then
        echo "❌ Use-check integration test failed"
        return 1
    fi
    
    if ! test_multiple_agents_flow; then
        echo "❌ Multiple agents flow test failed"
        return 1
    fi
    
    if ! test_error_handling; then
        echo "❌ Error handling test failed"
        return 1
    fi
    
    echo "✅ All INT-001 tests passed"
    return 0
}

# Run the test
main