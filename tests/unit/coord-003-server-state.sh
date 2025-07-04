#!/bin/bash

# Test ID: COORD-003
# Description: Server state management
# Expected: Server state is tracked and updated correctly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR="$1"

# Source the coordination library with overridden paths
source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"

# Test functions
test_initial_server_state() {
    echo "Testing initial server state..."
    
    # Initial state should be unknown
    local initial_state=$(get_server_state)
    if [ "$initial_state" != "unknown" ]; then
        echo "ERROR: Initial server state should be 'unknown', got '$initial_state'"
        return 1
    fi
    
    local initial_status=$(get_server_status)
    if [ "$initial_status" != "unknown" ]; then
        echo "ERROR: Initial server status should be 'unknown', got '$initial_status'"
        return 1
    fi
    
    local initial_pid=$(get_server_pid)
    if [ -n "$initial_pid" ]; then
        echo "ERROR: Initial server PID should be empty, got '$initial_pid'"
        return 1
    fi
    
    echo "✅ Initial server state correct"
    return 0
}

test_server_state_setting() {
    echo "Testing server state setting..."
    
    # Set server state
    local test_pid=12345
    set_server_state "running" "$test_pid"
    
    # Verify state was set correctly
    local current_state=$(get_server_state)
    if [[ ! "$current_state" =~ ^running:12345:[0-9]+$ ]]; then
        echo "ERROR: Server state should be 'running:12345:timestamp', got '$current_state'"
        return 1
    fi
    
    local current_status=$(get_server_status)
    if [ "$current_status" != "running" ]; then
        echo "ERROR: Server status should be 'running', got '$current_status'"
        return 1
    fi
    
    local current_pid=$(get_server_pid)
    if [ "$current_pid" != "12345" ]; then
        echo "ERROR: Server PID should be '12345', got '$current_pid'"
        return 1
    fi
    
    echo "✅ Server state setting successful"
    return 0
}

test_server_state_updates() {
    echo "Testing server state updates..."
    
    # Set initial state
    set_server_state "starting" "11111"
    
    # Verify initial state
    local status1=$(get_server_status)
    local pid1=$(get_server_pid)
    
    if [ "$status1" != "starting" ] || [ "$pid1" != "11111" ]; then
        echo "ERROR: Initial state not set correctly"
        return 1
    fi
    
    # Update state
    set_server_state "running" "22222"
    
    # Verify updated state
    local status2=$(get_server_status)
    local pid2=$(get_server_pid)
    
    if [ "$status2" != "running" ] || [ "$pid2" != "22222" ]; then
        echo "ERROR: Updated state not set correctly"
        return 1
    fi
    
    # Update state again
    set_server_state "stopping" "22222"
    
    # Verify final state
    local status3=$(get_server_status)
    local pid3=$(get_server_pid)
    
    if [ "$status3" != "stopping" ] || [ "$pid3" != "22222" ]; then
        echo "ERROR: Final state not set correctly"
        return 1
    fi
    
    echo "✅ Server state updates successful"
    return 0
}

test_server_state_persistence() {
    echo "Testing server state persistence..."
    
    # Set server state
    set_server_state "persistent" "33333"
    
    # Verify state file exists
    if [ ! -f "$SERVER_STATE_FILE" ]; then
        echo "ERROR: Server state file should exist"
        return 1
    fi
    
    # Verify state file content
    local file_content=$(cat "$SERVER_STATE_FILE")
    if [[ ! "$file_content" =~ ^persistent:33333:[0-9]+$ ]]; then
        echo "ERROR: Server state file content incorrect: '$file_content'"
        return 1
    fi
    
    # Simulate restart by re-reading state
    local persisted_status=$(get_server_status)
    local persisted_pid=$(get_server_pid)
    
    if [ "$persisted_status" != "persistent" ] || [ "$persisted_pid" != "33333" ]; then
        echo "ERROR: Server state not persisted correctly"
        return 1
    fi
    
    echo "✅ Server state persistence successful"
    return 0
}

test_server_info_display() {
    echo "Testing server info display..."
    
    # Set up server state
    set_server_state "info_test" "44444"
    
    # Register a user
    register_server_user "test-info-agent"
    
    # Get server info
    local server_info=$(get_server_info)
    
    # Verify server info contains expected components
    if [[ ! "$server_info" =~ "State: info_test" ]]; then
        echo "ERROR: Server info should contain state"
        echo "Got: $server_info"
        return 1
    fi
    
    if [[ ! "$server_info" =~ "PID: 44444" ]]; then
        echo "ERROR: Server info should contain PID"
        echo "Got: $server_info"
        return 1
    fi
    
    if [[ ! "$server_info" =~ "Users: 1" ]]; then
        echo "ERROR: Server info should contain user count"
        echo "Got: $server_info"
        return 1
    fi
    
    if [[ ! "$server_info" =~ "Lock: Free" ]]; then
        echo "ERROR: Server info should contain lock status"
        echo "Got: $server_info"
        return 1
    fi
    
    if [[ ! "$server_info" =~ "test-info-agent" ]]; then
        echo "ERROR: Server info should contain user list"
        echo "Got: $server_info"
        return 1
    fi
    
    # Clean up
    unregister_server_user "test-info-agent"
    
    echo "✅ Server info display successful"
    return 0
}

test_state_with_special_characters() {
    echo "Testing state with special characters..."
    
    # Test various state values
    local test_states=("running" "stopped" "error:connection-failed" "test_mode" "debug-session")
    
    for state in "${test_states[@]}"; do
        set_server_state "$state" "55555"
        
        local current_status=$(get_server_status)
        if [ "$current_status" != "$state" ]; then
            echo "ERROR: State '$state' not preserved correctly, got '$current_status'"
            return 1
        fi
    done
    
    echo "✅ State with special characters successful"
    return 0
}

test_concurrent_state_updates() {
    echo "Testing concurrent state updates..."
    
    # Start background processes that update state
    local pids=()
    
    for i in {1..3}; do
        (
            export SERVER_STATE_FILE="$TEST_TEMP_DIR/availably-dev-server.state"
            export USERS_COUNT_FILE="$TEST_TEMP_DIR/availably-server-users.count"
            export USERS_LIST_FILE="$TEST_TEMP_DIR/availably-server-users.list"
            export LOCK_FILE="$TEST_TEMP_DIR/availably-dev-server.lock"
            
            source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"
            
            # Each process updates state multiple times
            for j in {1..5}; do
                set_server_state "process${i}_update${j}" "$((60000 + i * 1000 + j))"
                sleep 0.1
            done
        ) &
        pids+=($!)
    done
    
    # Wait for all processes to complete
    for pid in "${pids[@]}"; do
        wait $pid
    done
    
    # Verify final state is valid
    local final_state=$(get_server_state)
    if [[ ! "$final_state" =~ ^process[1-3]_update[1-5]:[0-9]+:[0-9]+$ ]]; then
        echo "ERROR: Final state after concurrent updates is invalid: '$final_state'"
        return 1
    fi
    
    # Verify we can still read state components
    local final_status=$(get_server_status)
    local final_pid=$(get_server_pid)
    
    if [ -z "$final_status" ] || [ -z "$final_pid" ]; then
        echo "ERROR: Final state components should not be empty"
        return 1
    fi
    
    echo "✅ Concurrent state updates successful"
    return 0
}

# Main test execution
main() {
    echo "Running COORD-003: Server state management test"
    
    # Run individual tests
    if ! test_initial_server_state; then
        echo "❌ Initial server state test failed"
        return 1
    fi
    
    if ! test_server_state_setting; then
        echo "❌ Server state setting test failed"
        return 1
    fi
    
    if ! test_server_state_updates; then
        echo "❌ Server state updates test failed"
        return 1
    fi
    
    if ! test_server_state_persistence; then
        echo "❌ Server state persistence test failed"
        return 1
    fi
    
    if ! test_server_info_display; then
        echo "❌ Server info display test failed"
        return 1
    fi
    
    if ! test_state_with_special_characters; then
        echo "❌ State with special characters test failed"
        return 1
    fi
    
    if ! test_concurrent_state_updates; then
        echo "❌ Concurrent state updates test failed"
        return 1
    fi
    
    echo "✅ All COORD-003 tests passed"
    return 0
}

# Run the test
main