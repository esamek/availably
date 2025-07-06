#!/bin/bash

# Server Coordination System Test Framework
# Comprehensive testing suite for the parallel subagent server coordination system

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"
UNIT_TESTS_DIR="$TESTS_DIR/unit"
INTEGRATION_TESTS_DIR="$TESTS_DIR/integration"
TEST_RESULTS_DIR="$TESTS_DIR/results"
TEST_LOG_FILE="$TEST_RESULTS_DIR/test-$(date +%Y%m%d-%H%M%S).log"

# Test configuration
TEST_TIMEOUT=30
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test framework functions
log_test() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$TEST_LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

print_test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    case "$result" in
        "PASS")
            echo -e "  ${GREEN}✅ PASS${NC}: $test_name"
            ((PASSED_TESTS++))
            ;;
        "FAIL")
            echo -e "  ${RED}❌ FAIL${NC}: $test_name - $message"
            ((FAILED_TESTS++))
            ;;
        "SKIP")
            echo -e "  ${YELLOW}⏸️  SKIP${NC}: $test_name - $message"
            ((SKIPPED_TESTS++))
            ;;
    esac
    ((TOTAL_TESTS++))
    log_test "$result: $test_name - $message"
}

# Test environment setup
setup_test_env() {
    local test_name="$1"
    local test_temp_dir="/tmp/availably-test-$$-$test_name"
    
    # Create isolated test environment
    mkdir -p "$test_temp_dir"
    
    # Override coordination file paths for isolation
    export LOCK_FILE="$test_temp_dir/availably-dev-server.lock"
    export SERVER_STATE_FILE="$test_temp_dir/availably-dev-server.state"
    export USERS_COUNT_FILE="$test_temp_dir/availably-server-users.count"
    export USERS_LIST_FILE="$test_temp_dir/availably-server-users.list"
    
    echo "$test_temp_dir"
}

cleanup_test_env() {
    local test_temp_dir="$1"
    
    # Clean up test environment
    rm -rf "$test_temp_dir"
    
    # Clean up any leftover coordination files from test
    rm -f "$LOCK_FILE" "$SERVER_STATE_FILE" "$USERS_COUNT_FILE" "$USERS_LIST_FILE" 2>/dev/null || true
    rm -rf "$LOCK_FILE" 2>/dev/null || true
    
    # Kill any test processes
    pkill -f "availably-test-$$" 2>/dev/null || true
    
    # Reset environment variables
    unset LOCK_FILE SERVER_STATE_FILE USERS_COUNT_FILE USERS_LIST_FILE
}

# Test execution wrapper
run_test() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .sh)"
    
    if [ ! -f "$test_file" ]; then
        print_test_result "$test_name" "SKIP" "Test file not found"
        return 1
    fi
    
    if [ ! -x "$test_file" ]; then
        print_test_result "$test_name" "SKIP" "Test file not executable"
        return 1
    fi
    
    # Setup isolated test environment
    local test_temp_dir=$(setup_test_env "$test_name")
    
    # Run test with timeout (use gtimeout on macOS if available, otherwise plain bash)
    local test_start_time=$(date +%s)
    local test_exit_code
    
    if command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$TEST_TIMEOUT" bash "$test_file" "$test_temp_dir" 2>&1
        test_exit_code=$?
    elif command -v timeout >/dev/null 2>&1; then
        timeout "$TEST_TIMEOUT" bash "$test_file" "$test_temp_dir" 2>&1
        test_exit_code=$?
    else
        # Fallback: run without timeout
        bash "$test_file" "$test_temp_dir" 2>&1
        test_exit_code=$?
    fi
    
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - test_start_time))
    
    # Cleanup test environment
    cleanup_test_env "$test_temp_dir"
    
    # Report results
    if [ $test_exit_code -eq 0 ]; then
        print_test_result "$test_name" "PASS" "Duration: ${test_duration}s"
    elif [ $test_exit_code -eq 124 ]; then
        print_test_result "$test_name" "FAIL" "Timeout after ${TEST_TIMEOUT}s"
    else
        print_test_result "$test_name" "FAIL" "Exit code: $test_exit_code, Duration: ${test_duration}s"
    fi
    
    return $test_exit_code
}

# Test discovery and execution
run_unit_tests() {
    print_header "UNIT TESTS"
    
    if [ ! -d "$UNIT_TESTS_DIR" ]; then
        echo "Unit tests directory not found: $UNIT_TESTS_DIR"
        return 1
    fi
    
    for test_file in "$UNIT_TESTS_DIR"/*.sh; do
        if [ -f "$test_file" ]; then
            run_test "$test_file"
        fi
    done
}

run_integration_tests() {
    print_header "INTEGRATION TESTS"
    
    if [ ! -d "$INTEGRATION_TESTS_DIR" ]; then
        echo "Integration tests directory not found: $INTEGRATION_TESTS_DIR"
        return 1
    fi
    
    for test_file in "$INTEGRATION_TESTS_DIR"/*.sh; do
        if [ -f "$test_file" ]; then
            run_test "$test_file"
        fi
    done
}

run_specific_test() {
    local test_id="$1"
    
    # Search for test file with matching ID
    local test_file
    for dir in "$UNIT_TESTS_DIR" "$INTEGRATION_TESTS_DIR"; do
        for file in "$dir"/*.sh; do
            if [ -f "$file" ] && grep -q "# Test ID: $test_id" "$file"; then
                test_file="$file"
                break 2
            fi
        done
    done
    
    if [ -z "$test_file" ]; then
        echo "Test not found: $test_id"
        return 1
    fi
    
    run_test "$test_file"
}

# Test results summary
print_summary() {
    print_header "TEST RESULTS SUMMARY"
    
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo -e "Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"
    
    if [ $FAILED_TESTS -gt 0 ]; then
        echo -e "\n${RED}❌ Some tests failed${NC}"
        echo "Check log file: $TEST_LOG_FILE"
        return 1
    elif [ $PASSED_TESTS -eq 0 ]; then
        echo -e "\n${YELLOW}⚠️  No tests were run${NC}"
        return 1
    else
        echo -e "\n${GREEN}✅ All tests passed${NC}"
        return 0
    fi
}

# Initialize test environment
initialize_test_framework() {
    # Create test directories
    mkdir -p "$TESTS_DIR" "$UNIT_TESTS_DIR" "$INTEGRATION_TESTS_DIR" "$TEST_RESULTS_DIR"
    
    # Create test log file
    log_test "Starting test run at $(date)"
    log_test "Test framework initialized"
    
    # Verify coordination libraries exist
    if [ ! -f "$SCRIPT_DIR/scripts/lib/server-locking.sh" ]; then
        echo "Error: server-locking.sh not found"
        return 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/scripts/lib/server-coordination.sh" ]; then
        echo "Error: server-coordination.sh not found"
        return 1
    fi
    
    echo "Test framework initialized successfully"
}

# Usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Test the server coordination system with comprehensive unit and integration tests.

Options:
  --all               Run all tests (unit + integration)
  --unit              Run unit tests only
  --integration       Run integration tests only
  --test TEST_ID      Run specific test by ID (e.g., LOCK-001)
  --timeout SECONDS   Set test timeout (default: 30)
  --help              Show this help message

Examples:
  $0 --all                    # Run all tests
  $0 --unit                   # Run unit tests only
  $0 --test LOCK-001          # Run specific test
  $0 --timeout 60 --all       # Run all tests with 60s timeout

Test Categories:
  LOCK-001 to LOCK-004       # Locking system unit tests
  COORD-001 to COORD-004     # Coordination system unit tests
  INT-001 to INT-004         # Integration tests

EOF
}

# Main execution
main() {
    local run_unit=false
    local run_integration=false
    local run_all=false
    local test_id=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                run_all=true
                shift
                ;;
            --unit)
                run_unit=true
                shift
                ;;
            --integration)
                run_integration=true
                shift
                ;;
            --test)
                test_id="$2"
                shift 2
                ;;
            --timeout)
                TEST_TIMEOUT="$2"
                shift 2
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Default to running all tests if no specific option provided
    if [ "$run_unit" = false ] && [ "$run_integration" = false ] && [ "$run_all" = false ] && [ -z "$test_id" ]; then
        run_all=true
    fi
    
    # Initialize test framework
    if ! initialize_test_framework; then
        echo "Failed to initialize test framework"
        exit 1
    fi
    
    print_header "SERVER COORDINATION SYSTEM TEST SUITE"
    echo "Log file: $TEST_LOG_FILE"
    echo "Test timeout: ${TEST_TIMEOUT}s"
    
    # Run tests based on options
    if [ -n "$test_id" ]; then
        run_specific_test "$test_id"
    else
        if [ "$run_all" = true ] || [ "$run_unit" = true ]; then
            run_unit_tests
        fi
        
        if [ "$run_all" = true ] || [ "$run_integration" = true ]; then
            run_integration_tests
        fi
    fi
    
    # Print summary and exit with appropriate code
    print_summary
    exit $?
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi