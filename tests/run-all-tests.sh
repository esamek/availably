#!/bin/bash

# Comprehensive Test Runner for Failure Recovery and Performance Tests
# Executes all tests and provides consolidated reporting

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILURE_TESTS="$SCRIPT_DIR/failure/test-failure-recovery.sh"
PERFORMANCE_TESTS="$SCRIPT_DIR/performance/test-performance.sh"
LOG_FILE="/tmp/availably-test-results-$(date +%Y%m%d-%H%M%S).log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
FAILED_SUITES=()

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Test suite execution
run_test_suite() {
    local suite_name="$1"
    local suite_script="$2"
    
    log_info "Starting $suite_name"
    log_info "$(printf '=%.0s' {1..50})"
    
    if [ ! -f "$suite_script" ]; then
        log_error "$suite_name script not found: $suite_script"
        FAILED_SUITES+=("$suite_name")
        return 1
    fi
    
    if [ ! -x "$suite_script" ]; then
        log_error "$suite_name script not executable: $suite_script"
        FAILED_SUITES+=("$suite_name")
        return 1
    fi
    
    # Execute test suite and capture output
    local suite_start_time=$(date +%s)
    if "$suite_script" 2>&1 | tee -a "$LOG_FILE"; then
        local suite_end_time=$(date +%s)
        local suite_duration=$((suite_end_time - suite_start_time))
        log_success "$suite_name completed successfully in ${suite_duration}s"
        return 0
    else
        local suite_end_time=$(date +%s)
        local suite_duration=$((suite_end_time - suite_start_time))
        log_error "$suite_name failed after ${suite_duration}s"
        FAILED_SUITES+=("$suite_name")
        return 1
    fi
}

# Parse test results from log
parse_test_results() {
    local log_content=$(cat "$LOG_FILE")
    
    # Extract test counts from each suite
    local failure_passed=$(echo "$log_content" | grep -o "Tests Passed: [0-9]*" | tail -1 | grep -o "[0-9]*" || echo "0")
    local failure_failed=$(echo "$log_content" | grep -o "Tests Failed: [0-9]*" | tail -1 | grep -o "[0-9]*" || echo "0")
    
    # For performance tests, we need to look for the last occurrence
    local perf_section=$(echo "$log_content" | sed -n '/Starting Performance Tests/,$p')
    local perf_passed=$(echo "$perf_section" | grep -o "Tests Passed: [0-9]*" | tail -1 | grep -o "[0-9]*" || echo "0")
    local perf_failed=$(echo "$perf_section" | grep -o "Tests Failed: [0-9]*" | tail -1 | grep -o "[0-9]*" || echo "0")
    
    TOTAL_PASSED=$((failure_passed + perf_passed))
    TOTAL_FAILED=$((failure_failed + perf_failed))
    TOTAL_TESTS=$((TOTAL_PASSED + TOTAL_FAILED))
}

# System requirements check
check_requirements() {
    log_info "Checking system requirements..."
    
    local missing_commands=()
    
    # Check for required commands
    for cmd in bash kill pgrep date chmod mkdir rm; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        return 1
    fi
    
    # Check for optional commands
    if ! command -v bc &> /dev/null; then
        log_warning "bc command not found - performance timing will use integer arithmetic"
    fi
    
    # Check script dependencies
    local scripts_dir="$(cd "$SCRIPT_DIR/../scripts" && pwd)"
    if [ ! -f "$scripts_dir/lib/server-coordination.sh" ]; then
        log_error "Server coordination library not found: $scripts_dir/lib/server-coordination.sh"
        return 1
    fi
    
    if [ ! -f "$scripts_dir/lib/server-locking.sh" ]; then
        log_error "Server locking library not found: $scripts_dir/lib/server-locking.sh"
        return 1
    fi
    
    log_success "System requirements check passed"
    return 0
}

# Generate test report
generate_report() {
    local report_file="/tmp/availably-test-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# Availably Server Coordination Test Report

**Generated:** $(date)
**Test Log:** $LOG_FILE

## Summary

- **Total Tests:** $TOTAL_TESTS
- **Passed:** $TOTAL_PASSED
- **Failed:** $TOTAL_FAILED
- **Success Rate:** $(( TOTAL_TESTS > 0 ? (TOTAL_PASSED * 100) / TOTAL_TESTS : 0 ))%

## Test Suites

### Failure Recovery Tests
- **Script:** $FAILURE_TESTS
- **Status:** $([ ! " ${FAILED_SUITES[*]} " =~ " Failure Recovery Tests " ] && echo "PASSED" || echo "FAILED")

### Performance Tests
- **Script:** $PERFORMANCE_TESTS
- **Status:** $([ ! " ${FAILED_SUITES[*]} " =~ " Performance Tests " ] && echo "PASSED" || echo "FAILED")

## Failed Suites
EOF

    if [ ${#FAILED_SUITES[@]} -gt 0 ]; then
        for suite in "${FAILED_SUITES[@]}"; do
            echo "- $suite" >> "$report_file"
        done
    else
        echo "None" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## Performance Metrics

$(grep -E "^\[TIMING\]" "$LOG_FILE" | sed 's/^/- /' || echo "No timing data available")

## Recommendations

EOF

    if [ $TOTAL_FAILED -gt 0 ]; then
        cat >> "$report_file" << EOF
### Issues Found
- $TOTAL_FAILED tests failed
- Review detailed logs in: $LOG_FILE
- Address failed test scenarios before production use

### Next Steps
1. Fix failing test scenarios
2. Re-run tests to verify fixes
3. Consider additional edge cases based on failures
EOF
    else
        cat >> "$report_file" << EOF
### System Status
- All tests passed successfully
- System appears ready for production use
- Consider periodic re-testing as system evolves

### Maintenance
1. Run tests periodically to catch regressions
2. Update tests when adding new features
3. Monitor performance metrics in production
EOF
    fi
    
    log_info "Test report generated: $report_file"
}

# Main test execution
main() {
    local start_time=$(date +%s)
    
    log_info "Availably Server Coordination Test Suite"
    log_info "========================================"
    log_info "Starting comprehensive test execution..."
    log_info "Log file: $LOG_FILE"
    
    # Check system requirements
    if ! check_requirements; then
        log_error "System requirements check failed"
        exit 1
    fi
    
    # Run test suites
    local suites_failed=0
    
    if run_test_suite "Failure Recovery Tests" "$FAILURE_TESTS"; then
        log_success "Failure Recovery Tests: PASSED"
    else
        log_error "Failure Recovery Tests: FAILED"
        ((suites_failed++))
    fi
    
    if run_test_suite "Performance Tests" "$PERFORMANCE_TESTS"; then
        log_success "Performance Tests: PASSED"
    else
        log_error "Performance Tests: FAILED"
        ((suites_failed++))
    fi
    
    # Parse results and generate report
    parse_test_results
    generate_report
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    # Final summary
    log_info "========================================"
    log_info "Test Execution Summary:"
    log_info "Total Runtime: ${total_duration}s"
    log_info "Test Suites: $((${#FAILED_SUITES[@]} == 0 ? 2 : 2 - ${#FAILED_SUITES[@]}))/2 passed"
    log_info "Individual Tests: $TOTAL_PASSED/$TOTAL_TESTS passed"
    
    if [ $suites_failed -eq 0 ] && [ $TOTAL_FAILED -eq 0 ]; then
        log_success "All tests passed successfully!"
        log_info "System is ready for production use"
        exit 0
    else
        log_error "Some tests failed - review logs and fix issues"
        log_error "Failed suites: ${FAILED_SUITES[*]}"
        exit 1
    fi
}

# Command line options
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --check        Check system requirements only"
        echo "  --failure      Run only failure recovery tests"
        echo "  --performance  Run only performance tests"
        echo "  --report       Generate report from existing log"
        echo ""
        echo "Examples:"
        echo "  $0                    # Run all tests"
        echo "  $0 --failure          # Run only failure recovery tests"
        echo "  $0 --performance      # Run only performance tests"
        echo "  $0 --check            # Check system requirements"
        exit 0
        ;;
    --check)
        check_requirements
        exit $?
        ;;
    --failure)
        run_test_suite "Failure Recovery Tests" "$FAILURE_TESTS"
        exit $?
        ;;
    --performance)
        run_test_suite "Performance Tests" "$PERFORMANCE_TESTS"
        exit $?
        ;;
    --report)
        if [ -f "$LOG_FILE" ]; then
            parse_test_results
            generate_report
        else
            log_error "No log file found. Run tests first."
            exit 1
        fi
        exit 0
        ;;
    "")
        main "$@"
        ;;
    *)
        log_error "Unknown option: $1"
        log_info "Use --help for usage information"
        exit 1
        ;;
esac