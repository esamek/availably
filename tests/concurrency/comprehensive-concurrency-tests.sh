#!/bin/bash

# Comprehensive Concurrency Tests for Server Coordination System
# Tests all scenarios required by the test plan: CONC-001 through CONC-004 and REAL-001 through REAL-003

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/lib/server-locking.sh"
source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
FAILED_TEST_NAMES=""

log_test() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $timestamp - $message"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $timestamp - $message"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            FAILED_TEST_NAMES="$FAILED_TEST_NAMES $3"
            ;;
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $timestamp - $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $timestamp - $message"
            ;;
    esac
}

start_test() {
    local test_id="$1"
    local description="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "INFO" "Starting $test_id: $description"
    
    # Clean up before each test
    cleanup_coordination_files
    
    export TEST_START_TIME=$(date +%s)
}

end_test() {
    local test_id="$1"
    local result="$2"
    local message="$3"
    
    local duration=$(($(date +%s) - TEST_START_TIME))
    
    if [ "$result" = "PASS" ]; then
        log_test "PASS" "$test_id completed successfully: $message (${duration}s)"
    else
        log_test "FAIL" "$test_id failed: $message (${duration}s)" "$test_id"
    fi
    
    echo ""
}

# Wait for background processes with timeout
wait_for_background_processes() {
    local timeout="$1"
    shift
    local pids=("$@")
    
    local waited=0
    local remaining_pids=()
    
    while [ ${#pids[@]} -gt 0 ]; do
        remaining_pids=()
        
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                remaining_pids+=("$pid")
            fi
        done
        
        pids=("${remaining_pids[@]}")
        
        if [ ${#pids[@]} -eq 0 ]; then
            return 0
        fi
        
        if [ $waited -ge $timeout ]; then
            # Kill remaining processes
            for pid in "${pids[@]}"; do
                kill -TERM "$pid" 2>/dev/null || true
            done
            return 1
        fi
        
        sleep 1
        waited=$((waited + 1))
    done
    
    return 0
}

# Create mock agent that registers, works, and unregisters
create_mock_agent() {
    local agent_id="$1"
    local duration="$2"
    
    (
        register_server_user "$agent_id" > /dev/null 2>&1
        sleep "$duration"
        unregister_server_user "$agent_id" > /dev/null 2>&1
    ) &
    
    echo $!
}

# CONC-001: Simultaneous user registration
test_conc_001() {
    start_test "CONC-001" "Simultaneous user registration"
    
    # Create 5 agents that register simultaneously
    local pids=()
    for i in $(seq 1 5); do
        pids+=($(create_mock_agent "agent-$i" 3))
    done
    
    # Wait for all agents to complete
    if wait_for_background_processes 10 "${pids[@]}"; then
        # Verify final state - all agents should have unregistered
        local final_count=$(get_user_count)
        if [ "$final_count" -eq 0 ]; then
            end_test "CONC-001" "PASS" "All 5 agents registered and unregistered successfully"
        else
            end_test "CONC-001" "FAIL" "$final_count agents still registered after completion"
        fi
    else
        end_test "CONC-001" "FAIL" "Timeout waiting for simultaneous registration to complete"
    fi
}

# CONC-002: Concurrent server start attempts
test_conc_002() {
    start_test "CONC-002" "Concurrent server start attempts"
    
    local success_count=0
    local pids=()
    
    # Start multiple "server start" processes simultaneously
    for i in $(seq 1 3); do
        (
            if acquire_lock 10; then
                local current_state=$(get_server_status)
                if [ "$current_state" = "unknown" ] || [ "$current_state" = "stopped" ]; then
                    set_server_state "running" $$
                    sleep 2
                    set_server_state "stopped" ""
                    echo "Server started by process $$"
                    exit 0
                else
                    echo "Server already running ($$)"
                    exit 1
                fi
                release_lock
            else
                echo "Failed to acquire lock ($$)"
                exit 1
            fi
        ) &
        pids+=($!)
    done
    
    # Count successful starts
    for pid in "${pids[@]}"; do
        if wait "$pid"; then
            success_count=$((success_count + 1))
        fi
    done
    
    # Only one should succeed in starting the server
    if [ $success_count -eq 1 ]; then
        end_test "CONC-002" "PASS" "Exactly one server start succeeded out of 3 attempts"
    else
        end_test "CONC-002" "FAIL" "$success_count server starts succeeded (expected 1)"
    fi
}

# CONC-003: Race condition in stop requests
test_conc_003() {
    start_test "CONC-003" "Race condition in stop requests"
    
    # Set up initial state with multiple users
    register_server_user "agent-1" > /dev/null
    register_server_user "agent-2" > /dev/null
    register_server_user "agent-3" > /dev/null
    
    local initial_users=$(get_user_count)
    
    # Start concurrent stop requests
    local stop_attempts=0
    local pids=()
    
    for i in $(seq 1 3); do
        (
            if acquire_lock 5; then
                local current_users=$(get_user_count)
                if [ $current_users -eq 0 ]; then
                    echo "Server can be stopped by process $$"
                    exit 0
                else
                    echo "Server cannot be stopped, $current_users users active ($$)"
                    exit 1
                fi
                release_lock
            else
                exit 1
            fi
        ) &
        pids+=($!)
    done
    
    # Count stop attempts that said "can stop"
    for pid in "${pids[@]}"; do
        if wait "$pid"; then
            stop_attempts=$((stop_attempts + 1))
        fi
    done
    
    # No stop should succeed while users are active
    local final_users=$(get_user_count)
    if [ $stop_attempts -eq 0 ] && [ $final_users -eq $initial_users ]; then
        end_test "CONC-003" "PASS" "Stop requests correctly blocked with $final_users active users"
    else
        end_test "CONC-003" "FAIL" "$stop_attempts stop attempts succeeded with active users"
    fi
    
    # Clean up users
    unregister_server_user "agent-1" > /dev/null
    unregister_server_user "agent-2" > /dev/null  
    unregister_server_user "agent-3" > /dev/null
}

# CONC-004: Lock contention under high load
test_conc_004() {
    start_test "CONC-004" "Lock contention under high load"
    
    local success_count=0
    local pids=()
    
    # Create high contention with 8 concurrent lock requests
    for i in $(seq 1 8); do
        (
            if acquire_lock 15; then
                # Brief work while holding lock
                sleep 0.5
                release_lock
                exit 0
            else
                exit 1
            fi
        ) &
        pids+=($!)
    done
    
    # Count successes
    for pid in "${pids[@]}"; do
        if wait "$pid"; then
            success_count=$((success_count + 1))
        fi
    done
    
    # Should have high success rate under contention
    local success_rate=$((success_count * 100 / 8))
    if [ $success_rate -ge 75 ]; then
        end_test "CONC-004" "PASS" "Lock contention handled well: $success_count/8 successes ($success_rate%)"
    else
        end_test "CONC-004" "FAIL" "Poor contention handling: only $success_count/8 successes ($success_rate%)"
    fi
}

# REAL-001: 4 agents working simultaneously (realistic scenario)
test_real_001() {
    start_test "REAL-001" "4 agents working simultaneously"
    
    # Create agents with different work patterns
    local pids=()
    
    # UI Polish - quick tasks
    pids+=($(create_mock_agent "ui-polish" 4))
    
    # Algorithm Development - longer tasks  
    pids+=($(create_mock_agent "algorithm-dev" 8))
    
    # Real-time Features - medium tasks
    pids+=($(create_mock_agent "realtime-features" 6))
    
    # Interaction Enhancement - testing focused
    pids+=($(create_mock_agent "interaction-enhancement" 5))
    
    # Monitor peak usage
    local max_users=0
    local monitoring_duration=0
    
    while [ ${#pids[@]} -gt 0 ]; do
        local remaining_pids=()
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                remaining_pids+=("$pid")
            fi
        done
        pids=("${remaining_pids[@]}")
        
        local current_users=$(get_user_count)
        if [ $current_users -gt $max_users ]; then
            max_users=$current_users
        fi
        
        monitoring_duration=$((monitoring_duration + 1))
        if [ $monitoring_duration -gt 15 ]; then
            # Kill remaining processes if taking too long
            for pid in "${pids[@]}"; do
                kill -TERM "$pid" 2>/dev/null || true
            done
            break
        fi
        
        sleep 1
    done
    
    # Verify final state
    local final_users=$(get_user_count)
    if [ $final_users -eq 0 ] && [ $max_users -ge 3 ]; then
        end_test "REAL-001" "PASS" "4 agents coordinated successfully, peak users: $max_users"
    else
        end_test "REAL-001" "FAIL" "Final users: $final_users, peak users: $max_users"
    fi
}

# REAL-002: Agent handoff scenario
test_real_002() {
    start_test "REAL-002" "Agent handoff scenario"
    
    # Agent 1 starts
    register_server_user "agent-first" > /dev/null
    local count1=$(get_user_count)
    
    # Agent 2 joins for overlap
    register_server_user "agent-second" > /dev/null
    local count2=$(get_user_count)
    
    # Agent 1 hands off to Agent 2
    unregister_server_user "agent-first" > /dev/null
    local count3=$(get_user_count)
    
    # Agent 3 joins Agent 2
    register_server_user "agent-third" > /dev/null
    local count4=$(get_user_count)
    
    # All agents finish
    unregister_server_user "agent-second" > /dev/null
    unregister_server_user "agent-third" > /dev/null
    local count5=$(get_user_count)
    
    # Verify handoff sequence: 1 -> 2 -> 1 -> 2 -> 0
    if [ $count1 -eq 1 ] && [ $count2 -eq 2 ] && [ $count3 -eq 1 ] && [ $count4 -eq 2 ] && [ $count5 -eq 0 ]; then
        end_test "REAL-002" "PASS" "Agent handoff sequence completed correctly"
    else
        end_test "REAL-002" "FAIL" "Handoff sequence incorrect: $count1->$count2->$count3->$count4->$count5"
    fi
}

# REAL-003: Cleanup after agent crash
test_real_003() {
    start_test "REAL-003" "Cleanup after agent crash"
    
    # Start normal agent
    register_server_user "agent-normal" > /dev/null
    
    # Start agent that will "crash"
    (
        register_server_user "agent-crash" > /dev/null
        sleep 60  # Will be killed before this completes
    ) &
    local crash_pid=$!
    
    # Wait for crash agent to register
    sleep 2
    local users_before_crash=$(get_user_count)
    
    # Kill the "crashed" agent
    kill -KILL $crash_pid 2>/dev/null
    wait $crash_pid 2>/dev/null || true
    
    # Trigger cleanup
    sleep 1
    cleanup_dead_users > /dev/null
    local users_after_cleanup=$(get_user_count)
    
    # Normal agent finishes
    unregister_server_user "agent-normal" > /dev/null
    local final_users=$(get_user_count)
    
    # Should clean up crashed agent but keep normal agent
    if [ $users_before_crash -eq 2 ] && [ $users_after_cleanup -eq 1 ] && [ $final_users -eq 0 ]; then
        end_test "REAL-003" "PASS" "Crash cleanup worked: $users_before_crash->$users_after_cleanup->$final_users"
    else
        end_test "REAL-003" "FAIL" "Cleanup failed: $users_before_crash->$users_after_cleanup->$final_users"
    fi
}

# Performance test
test_performance() {
    start_test "PERF-001" "Performance under concurrent load"
    
    local start_time=$(date +%s%3N)
    local operations=0
    
    # Rapid operations test
    for i in $(seq 1 5); do
        if register_server_user "perf-agent-$i" > /dev/null 2>&1; then
            if unregister_server_user "perf-agent-$i" > /dev/null 2>&1; then
                operations=$((operations + 1))
            fi
        fi
    done
    
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    
    # Should complete 5 operations quickly
    if [ $operations -eq 5 ] && [ $duration -lt 5000 ]; then
        end_test "PERF-001" "PASS" "Performance acceptable: $operations operations in ${duration}ms"
    else
        end_test "PERF-001" "FAIL" "Performance poor: $operations operations in ${duration}ms"
    fi
}

# Generate test report
generate_test_report() {
    echo ""
    echo "=========================================="
    echo "COMPREHENSIVE CONCURRENCY TEST RESULTS"
    echo "=========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo "Success Rate: $success_rate%"
    fi
    
    if [ $FAILED_TESTS -gt 0 ]; then
        echo ""
        echo "Failed Tests:$FAILED_TEST_NAMES"
    fi
    
    echo "=========================================="
    
    # Return success/failure
    [ $FAILED_TESTS -eq 0 ]
}

# Main test runner
run_all_tests() {
    echo "🧪 Comprehensive Concurrency Tests for Server Coordination System"
    echo "================================================================="
    echo ""
    
    # Core concurrency tests (CONC-001 through CONC-004)
    test_conc_001
    test_conc_002
    test_conc_003
    test_conc_004
    
    # Real-world scenario tests (REAL-001 through REAL-003)
    test_real_001
    test_real_002
    test_real_003
    
    # Performance test
    test_performance
    
    # Final cleanup
    cleanup_coordination_files
    
    # Generate and return results
    generate_test_report
}

# Clean up on exit
cleanup_on_exit() {
    cleanup_coordination_files > /dev/null 2>&1
    # Kill any remaining background processes
    pkill -P $$ 2>/dev/null || true
}

trap cleanup_on_exit EXIT INT TERM

# Run specific test if provided, otherwise run all
if [ $# -eq 1 ]; then
    case "$1" in
        "CONC-001") test_conc_001; generate_test_report ;;
        "CONC-002") test_conc_002; generate_test_report ;;
        "CONC-003") test_conc_003; generate_test_report ;;
        "CONC-004") test_conc_004; generate_test_report ;;
        "REAL-001") test_real_001; generate_test_report ;;
        "REAL-002") test_real_002; generate_test_report ;;
        "REAL-003") test_real_003; generate_test_report ;;
        "PERF-001") test_performance; generate_test_report ;;
        *) echo "Unknown test: $1" ;;
    esac
else
    run_all_tests
fi