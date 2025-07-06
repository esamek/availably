#!/bin/bash

# Simplified Concurrency Test for Server Coordination System
# Tests the most critical concurrency scenarios

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/lib/server-locking.sh"
source "$SCRIPT_DIR/../../scripts/lib/server-coordination.sh"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log_test() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $message"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $message"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            ;;
        *)
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
    esac
}

start_test() {
    local test_name="$1"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "INFO" "Starting test: $test_name"
    
    # Clean up before each test
    cleanup_coordination_files
}

# Test 1: Basic concurrent registration
test_concurrent_registration() {
    start_test "Concurrent Registration"
    
    # Start 3 agents concurrently
    (
        register_server_user "agent-1"
        sleep 2
        unregister_server_user "agent-1"
    ) &
    local pid1=$!
    
    (
        register_server_user "agent-2"  
        sleep 2
        unregister_server_user "agent-2"
    ) &
    local pid2=$!
    
    (
        register_server_user "agent-3"
        sleep 2
        unregister_server_user "agent-3"
    ) &
    local pid3=$!
    
    # Wait for all agents to complete
    wait $pid1 $pid2 $pid3
    
    # Check final state
    local final_count=$(get_user_count)
    if [ "$final_count" -eq 0 ]; then
        log_test "PASS" "Concurrent registration completed successfully"
    else
        log_test "FAIL" "Concurrent registration left $final_count users registered"
    fi
}

# Test 2: Lock contention
test_lock_contention() {
    start_test "Lock Contention"
    
    local success_count=0
    local pids=()
    
    # Start 5 processes that compete for the lock
    for i in $(seq 1 5); do
        (
            if acquire_lock 10; then
                sleep 1
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
    
    if [ $success_count -eq 5 ]; then
        log_test "PASS" "All 5 processes acquired lock successfully"
    elif [ $success_count -ge 3 ]; then
        log_test "PASS" "Lock contention handled reasonably ($success_count/5 successes)"
    else
        log_test "FAIL" "Poor lock contention performance ($success_count/5 successes)"
    fi
}

# Test 3: Agent handoff scenario
test_agent_handoff() {
    start_test "Agent Handoff"
    
    # Agent 1 starts working
    register_server_user "handoff-agent-1"
    local count1=$(get_user_count)
    
    # Agent 2 joins
    register_server_user "handoff-agent-2"
    local count2=$(get_user_count)
    
    # Agent 1 finishes, hands off to Agent 2
    unregister_server_user "handoff-agent-1"
    local count3=$(get_user_count)
    
    # Agent 2 finishes
    unregister_server_user "handoff-agent-2"
    local count4=$(get_user_count)
    
    if [ $count1 -eq 1 ] && [ $count2 -eq 2 ] && [ $count3 -eq 1 ] && [ $count4 -eq 0 ]; then
        log_test "PASS" "Agent handoff scenario completed successfully"
    else
        log_test "FAIL" "Agent handoff failed: counts were $count1->$count2->$count3->$count4"
    fi
}

# Test 4: Cleanup after process death
test_cleanup_after_death() {
    start_test "Cleanup After Process Death"
    
    # Start a background process that will die
    (
        register_server_user "dying-agent"
        sleep 10  # This process will be killed before this completes
    ) &
    local dying_pid=$!
    
    # Give it time to register
    sleep 1
    
    # Kill the process
    kill $dying_pid 2>/dev/null
    wait $dying_pid 2>/dev/null || true
    
    # Check that cleanup detects the dead process
    local count_before=$(get_user_count)
    cleanup_dead_users
    local count_after=$(get_user_count)
    
    if [ $count_before -gt $count_after ] && [ $count_after -eq 0 ]; then
        log_test "PASS" "Dead process cleanup worked correctly"
    else
        log_test "FAIL" "Dead process cleanup failed: $count_before -> $count_after"
    fi
}

# Test 5: High-frequency operations
test_high_frequency() {
    start_test "High-Frequency Operations"
    
    local operations=0
    local start_time=$(date +%s)
    
    # Perform rapid register/unregister cycles
    for i in $(seq 1 10); do
        if register_server_user "rapid-agent-$i" > /dev/null 2>&1; then
            if unregister_server_user "rapid-agent-$i" > /dev/null 2>&1; then
                operations=$((operations + 1))
            fi
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $operations -ge 8 ] && [ $duration -le 10 ]; then
        log_test "PASS" "High-frequency operations: $operations/10 completed in ${duration}s"
    else
        log_test "FAIL" "High-frequency operations too slow: $operations/10 in ${duration}s"
    fi
}

# Run all tests
run_all_tests() {
    echo "🧪 Simple Concurrency Tests for Server Coordination"
    echo "=================================================="
    
    test_concurrent_registration
    test_lock_contention  
    test_agent_handoff
    test_cleanup_after_death
    test_high_frequency
    
    # Final cleanup
    cleanup_coordination_files
    
    # Results
    echo ""
    echo "=================================================="
    echo "Test Results:"
    echo "  Total: $TOTAL_TESTS"
    echo "  Passed: $PASSED_TESTS"  
    echo "  Failed: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

# Run tests
run_all_tests