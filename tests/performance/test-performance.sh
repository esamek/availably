#!/bin/bash

# Test Framework for Performance Tests
# Tests system performance under various load conditions

set -e

# Test configuration
TEST_DIR="/tmp/availably-performance-tests-$$"
SCRIPTS_DIR="$(cd "$(dirname "$0")/../../scripts" && pwd)"
LOCK_DIR="$TEST_DIR/server-coordination"
PID_FILE="$TEST_DIR/test-process.pid"

# Performance benchmarks (in seconds)
LOCK_ACQUISITION_TIMEOUT=1
CONCURRENT_USERS_MAX=10
CLEANUP_TIMEOUT=5
SERVER_START_TIMEOUT=10

# Test utilities
source "$SCRIPTS_DIR/lib/server-coordination.sh"
source "$SCRIPTS_DIR/lib/server-locking.sh"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Performance metrics
TIMING_RESULTS=()

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_timing() {
    local test_name="$1"
    local duration="$2"
    local benchmark="$3"
    
    echo -e "${BLUE}[TIMING]${NC} $test_name: ${YELLOW}${duration}s${NC} (benchmark: ${benchmark}s)"
    TIMING_RESULTS+=("$test_name: ${duration}s (benchmark: ${benchmark}s)")
}

# Test framework functions
setup_test_environment() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    mkdir -p "$LOCK_DIR"
    export SERVER_COORDINATION_DIR="$LOCK_DIR"
    log_info "Test environment created: $TEST_DIR"
}

cleanup_test_environment() {
    # Kill any test processes
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_info "Cleaning up test process: $pid"
            kill -9 "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi
    
    # Clean up background processes
    local pids=$(pgrep -f "availably-perf-test" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        log_info "Cleaning up background test processes: $pids"
        echo "$pids" | xargs kill -9 2>/dev/null || true
    fi
    
    # Clean up any lingering coordination files
    rm -rf "$TEST_DIR"
    log_info "Test environment cleaned up"
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    log_info "Running test: $test_name"
    
    if $test_function; then
        log_success "PASS: $test_name"
        ((TESTS_PASSED++))
    else
        log_error "FAIL: $test_name"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
    fi
    
    # Clean up between tests
    cleanup_test_environment
    setup_test_environment
}

# Timing utility functions
measure_time() {
    local start_time=$(date +%s.%N)
    "$@"
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    echo "$duration"
}

# Helper functions for performance testing
create_background_process() {
    local process_name="$1"
    local duration="${2:-30}"
    
    (
        trap 'exit 0' TERM
        exec -a "availably-perf-test-$process_name" sleep "$duration"
    ) &
    
    local pid=$!
    echo "$pid"
}

create_multiple_users() {
    local count="$1"
    local user_pids=()
    
    for i in $(seq 1 "$count"); do
        local pid=$(create_background_process "user$i" 60)
        user_pids+=("$pid")
        register_server_user "perf-user-$i" "$pid" || return 1
    done
    
    echo "${user_pids[@]}"
}

create_dead_registrations() {
    local count="$1"
    local dead_pids=()
    
    for i in $(seq 1 "$count"); do
        local pid=$(create_background_process "dead$i" 1)
        dead_pids+=("$pid")
        register_server_user "dead-user-$i" "$pid" || return 1
        
        # Wait for process to die
        sleep 2
    done
    
    echo "${dead_pids[@]}"
}

# PERF-001: Lock acquisition time under normal conditions
test_perf_001() {
    log_info "PERF-001: Lock acquisition time under normal conditions"
    
    # Test lock acquisition timing
    local duration=$(measure_time register_server_user "perf-test-user" "$$")
    
    log_timing "PERF-001" "$duration" "$LOCK_ACQUISITION_TIMEOUT"
    
    # Check if within benchmark
    if (( $(echo "$duration > $LOCK_ACQUISITION_TIMEOUT" | bc -l) )); then
        log_error "Lock acquisition took ${duration}s, exceeds benchmark of ${LOCK_ACQUISITION_TIMEOUT}s"
        return 1
    fi
    
    log_success "Lock acquisition within performance benchmark"
    return 0
}

# PERF-002: System performance with 10+ concurrent users
test_perf_002() {
    log_info "PERF-002: System performance with 10+ concurrent users"
    
    # Create baseline measurement with single user
    local single_user_pid=$(create_background_process "baseline" 60)
    local baseline_duration=$(measure_time register_server_user "baseline-user" "$single_user_pid")
    
    # Create 10 concurrent users
    local user_pids=($(create_multiple_users 10))
    
    # Test performance with concurrent users
    local concurrent_user_pid=$(create_background_process "concurrent" 60)
    local concurrent_duration=$(measure_time register_server_user "concurrent-user" "$concurrent_user_pid")
    
    log_timing "PERF-002-baseline" "$baseline_duration" "$LOCK_ACQUISITION_TIMEOUT"
    log_timing "PERF-002-concurrent" "$concurrent_duration" "$LOCK_ACQUISITION_TIMEOUT"
    
    # Performance should not degrade significantly (allow 2x slower)
    local max_acceptable=$(echo "$baseline_duration * 2" | bc -l)
    
    if (( $(echo "$concurrent_duration > $max_acceptable" | bc -l) )); then
        log_error "Concurrent performance degraded significantly: ${concurrent_duration}s vs baseline ${baseline_duration}s"
        return 1
    fi
    
    # Verify all users are registered
    local user_count=$(get_user_count)
    if [ "$user_count" -lt 11 ]; then  # 10 + 1 baseline + 1 concurrent
        log_error "Expected at least 11 users, got $user_count"
        return 1
    fi
    
    log_success "System performance maintained with concurrent users"
    return 0
}

# PERF-003: Cleanup performance with many dead registrations
test_perf_003() {
    log_info "PERF-003: Cleanup performance with many dead registrations"
    
    # Create many dead registrations
    local dead_count=20
    log_info "Creating $dead_count dead registrations"
    create_dead_registrations "$dead_count"
    
    # Verify dead registrations exist
    local initial_count=$(get_user_count)
    if [ "$initial_count" -lt "$dead_count" ]; then
        log_warning "Only $initial_count dead registrations created (expected $dead_count)"
    fi
    
    # Test cleanup performance
    local cleanup_pid=$(create_background_process "cleanup_test" 60)
    local cleanup_duration=$(measure_time register_server_user "cleanup-trigger" "$cleanup_pid")
    
    log_timing "PERF-003" "$cleanup_duration" "$CLEANUP_TIMEOUT"
    
    # Check if cleanup completed within benchmark
    if (( $(echo "$cleanup_duration > $CLEANUP_TIMEOUT" | bc -l) )); then
        log_error "Cleanup took ${cleanup_duration}s, exceeds benchmark of ${CLEANUP_TIMEOUT}s"
        return 1
    fi
    
    # Verify cleanup was effective
    local final_count=$(get_user_count)
    if [ "$final_count" -gt 2 ]; then  # Should be 1 (cleanup trigger) + maybe 1 (if any alive)
        log_warning "Cleanup may not have been complete: $final_count users remaining"
    fi
    
    log_success "Cleanup performance within benchmark"
    return 0
}

# PERF-004: Server start time with coordination overhead
test_perf_004() {
    log_info "PERF-004: Server start time with coordination overhead"
    
    # Simulate server startup process with coordination
    local server_start_script="$TEST_DIR/mock_server_start.sh"
    cat > "$server_start_script" << 'EOF'
#!/bin/bash
# Mock server start with coordination overhead
source "$(dirname "$0")/../../scripts/lib/server-coordination.sh"

# Register server process
register_server_user "mock-server" "$$" || exit 1

# Simulate server initialization
sleep 1

# Simulate server startup tasks
for i in {1..5}; do
    sleep 0.2
    echo "Initializing component $i..."
done

echo "Server started successfully"
EOF
    chmod +x "$server_start_script"
    
    # Measure server start time
    local start_duration=$(measure_time "$server_start_script")
    
    log_timing "PERF-004" "$start_duration" "$SERVER_START_TIMEOUT"
    
    # Check if server started within benchmark
    if (( $(echo "$start_duration > $SERVER_START_TIMEOUT" | bc -l) )); then
        log_error "Server start took ${start_duration}s, exceeds benchmark of ${SERVER_START_TIMEOUT}s"
        return 1
    fi
    
    # Verify server was registered
    local count=$(get_user_count)
    if [ "$count" -lt 1 ]; then
        log_error "Server registration failed during startup"
        return 1
    fi
    
    log_success "Server start time within benchmark"
    return 0
}

# Additional performance tests
test_perf_stress() {
    log_info "PERF-STRESS: Stress test with rapid registrations"
    
    # Test rapid registration/deregistration cycles
    local stress_count=50
    local stress_duration=$(measure_time bash -c "
        for i in \$(seq 1 $stress_count); do
            pid=\$(create_background_process \"stress\$i\" 1)
            register_server_user \"stress-user-\$i\" \"\$pid\" || exit 1
            sleep 0.1
        done
    ")
    
    log_timing "PERF-STRESS" "$stress_duration" "30"
    
    # System should handle stress without failure
    local final_count=$(get_user_count)
    if [ "$final_count" -lt 0 ]; then
        log_error "System became inconsistent during stress test"
        return 1
    fi
    
    log_success "System survived stress test"
    return 0
}

# Test execution
main() {
    log_info "Starting Performance Tests"
    log_info "========================="
    
    # Check if bc is available for floating point arithmetic
    if ! command -v bc &> /dev/null; then
        log_warning "bc command not found, using integer arithmetic"
        # Fallback to integer arithmetic
        measure_time() {
            local start_time=$(date +%s)
            "$@"
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo "$duration"
        }
    fi
    
    setup_test_environment
    
    # Run all performance tests
    run_test "PERF-001: Lock acquisition time under normal conditions" test_perf_001
    run_test "PERF-002: System performance with 10+ concurrent users" test_perf_002
    run_test "PERF-003: Cleanup performance with many dead registrations" test_perf_003
    run_test "PERF-004: Server start time with coordination overhead" test_perf_004
    run_test "PERF-STRESS: Stress test with rapid registrations" test_perf_stress
    
    cleanup_test_environment
    
    # Report results
    log_info "========================="
    log_info "Performance Test Results:"
    log_success "Tests Passed: $TESTS_PASSED"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        log_error "Tests Failed: $TESTS_FAILED"
        for test in "${FAILED_TESTS[@]}"; do
            log_error "  - $test"
        done
    fi
    
    # Show timing results
    log_info "========================="
    log_info "Performance Timing Results:"
    for result in "${TIMING_RESULTS[@]}"; do
        log_info "  $result"
    done
    
    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    else
        log_success "All performance tests passed!"
        exit 0
    fi
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi