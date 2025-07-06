#!/bin/bash

# Main Test Coordinator
# Orchestrates execution of all coordination system tests

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Preserve test script directory (coordination library may override SCRIPT_DIR)
TEST_SCRIPT_DIR="$SCRIPT_DIR"

# Load test utilities
source "$TEST_SCRIPT_DIR/test-utils.sh"

# Test categories (use preserved directory)
UNIT_TESTS_DIR="$TEST_SCRIPT_DIR/unit"
INTEGRATION_TESTS_DIR="$TEST_SCRIPT_DIR/integration"
CONCURRENCY_TESTS_DIR="$TEST_SCRIPT_DIR/concurrency"
FAILURE_TESTS_DIR="$TEST_SCRIPT_DIR/failure"
PERFORMANCE_TESTS_DIR="$TEST_SCRIPT_DIR/performance"

# Available test categories
AVAILABLE_CATEGORIES=("unit" "integration" "concurrency" "failure" "performance")

# Configuration
PARALLEL_TESTS="${PARALLEL_TESTS:-false}"
MAX_PARALLEL_TESTS="${MAX_PARALLEL_TESTS:-4}"

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Test coordination system for Availably development server"
    echo ""
    echo "OPTIONS:"
    echo "  --all                    Run all tests"
    echo "  --unit                   Run unit tests only"
    echo "  --integration            Run integration tests only"
    echo "  --concurrency            Run concurrency tests only"
    echo "  --failure                Run failure recovery tests only"
    echo "  --performance            Run performance tests only"
    echo "  --test TEST_ID           Run specific test by ID"
    echo "  --category CATEGORY      Run tests from specific category"
    echo "  --parallel               Run tests in parallel (experimental)"
    echo "  --max-parallel N         Maximum parallel tests (default: 4)"
    echo "  --timeout N              Test timeout in seconds (default: 30)"
    echo "  --log-level LEVEL        Log level: DEBUG, INFO, ERROR (default: INFO)"
    echo "  --results-dir DIR        Custom results directory"
    echo "  --clean                  Clean test environment before running"
    echo "  --list                   List available tests"
    echo "  --help                   Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 --all                 # Run all tests"
    echo "  $0 --unit --integration  # Run unit and integration tests"
    echo "  $0 --test LOCK-001       # Run specific test"
    echo "  $0 --concurrency --parallel  # Run concurrency tests in parallel"
    echo "  $0 --list                # List all available tests"
    echo ""
}

# List available tests
list_tests() {
    echo "Available test categories and tests:"
    echo ""
    
    for category in "${AVAILABLE_CATEGORIES[@]}"; do
        local category_dir="$TEST_SCRIPT_DIR/$category"
        if [ -d "$category_dir" ]; then
            echo "📂 $category tests:"
            if [ -n "$(ls -A "$category_dir" 2>/dev/null)" ]; then
                for test_file in "$category_dir"/*.sh; do
                    if [ -f "$test_file" ]; then
                        local test_name=$(basename "$test_file" .sh)
                        echo "  - $test_name"
                        
                        # Extract test IDs from file
                        grep -E "^[[:space:]]*#[[:space:]]*Test ID:" "$test_file" 2>/dev/null | while read -r line; do
                            local test_id=$(echo "$line" | sed 's/.*Test ID:[[:space:]]*//' | sed 's/[[:space:]]*$//')
                            echo "    📝 $test_id"
                        done
                    fi
                done
            else
                echo "  (no tests implemented yet)"
            fi
            echo ""
        fi
    done
}

# Find test by ID
find_test_by_id() {
    local test_id="$1"
    
    for category in "${AVAILABLE_CATEGORIES[@]}"; do
        local category_dir="$TEST_SCRIPT_DIR/$category"
        if [ -d "$category_dir" ]; then
            for test_file in "$category_dir"/*.sh; do
                if [ -f "$test_file" ] && grep -q "Test ID:[[:space:]]*$test_id" "$test_file"; then
                    echo "$test_file"
                    return 0
                fi
            done
        fi
    done
    
    return 1
}

# Run tests in category
run_category_tests() {
    local category="$1"
    local category_dir="$TEST_SCRIPT_DIR/$category"
    
    
    if [ ! -d "$category_dir" ]; then
        log_error "Category directory not found: $category_dir"
        return 1
    fi
    
    log_info "Running $category tests..."
    
    local category_passed=0
    local category_failed=0
    
    # Check if there are any test files
    if [ -z "$(ls -A "$category_dir"/*.sh 2>/dev/null)" ]; then
        log_info "No test files found in $category category"
        return 0
    fi
    
    # Run each test file in the category
    for test_file in "$category_dir"/*.sh; do
        if [ -f "$test_file" ]; then
            local test_name=$(basename "$test_file" .sh)
            log_info "Executing test file: $test_name"
            
            # Make test file executable
            chmod +x "$test_file"
            
            # Run the test file
            if "$test_file"; then
                log_success "Test file passed: $test_name"
                category_passed=$((category_passed + 1))
            else
                log_error "Test file failed: $test_name"
                category_failed=$((category_failed + 1))
            fi
        fi
    done
    
    log_info "Category $category results: $category_passed passed, $category_failed failed"
    return $category_failed
}

# Run specific test by ID
run_test_by_id() {
    local test_id="$1"
    
    log_info "Looking for test: $test_id"
    
    local test_file=$(find_test_by_id "$test_id")
    if [ -z "$test_file" ]; then
        log_error "Test not found: $test_id"
        return 1
    fi
    
    log_info "Found test $test_id in: $test_file"
    
    # Make test file executable
    chmod +x "$test_file"
    
    # Run the test file with specific test ID
    if "$test_file" --test "$test_id"; then
        log_success "Test passed: $test_id"
        return 0
    else
        log_error "Test failed: $test_id"
        return 1
    fi
}

# Run tests in parallel
run_parallel_tests() {
    local categories=("$@")
    local pids=()
    local results=()
    
    log_info "Running tests in parallel (max: $MAX_PARALLEL_TESTS)"
    
    for category in "${categories[@]}"; do
        # Wait if we've reached max parallel tests
        while [ ${#pids[@]} -ge $MAX_PARALLEL_TESTS ]; do
            wait_for_parallel_completion pids results
        done
        
        # Start test category in background
        log_info "Starting parallel test category: $category"
        (
            run_category_tests "$category"
            echo $? > "$TEST_RESULTS_DIR/parallel_${category}_$$"
        ) &
        
        pids+=($!)
        results+=("$TEST_RESULTS_DIR/parallel_${category}_$$")
    done
    
    # Wait for all remaining tests to complete
    log_info "Waiting for all parallel tests to complete..."
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Collect results
    local total_failed=0
    for result_file in "${results[@]}"; do
        if [ -f "$result_file" ]; then
            local exit_code=$(cat "$result_file")
            total_failed=$((total_failed + exit_code))
            rm -f "$result_file"
        fi
    done
    
    return $total_failed
}

# Wait for some parallel tests to complete
wait_for_parallel_completion() {
    local -n pid_array=$1
    local -n result_array=$2
    
    # Wait for at least one process to complete
    local completed_pids=()
    for i in "${!pid_array[@]}"; do
        local pid="${pid_array[$i]}"
        if ! kill -0 "$pid" 2>/dev/null; then
            completed_pids+=($i)
        fi
    done
    
    # If none completed, wait a bit
    if [ ${#completed_pids[@]} -eq 0 ]; then
        sleep 1
        return
    fi
    
    # Remove completed processes from arrays
    for i in "${completed_pids[@]}"; do
        unset pid_array[$i]
        unset result_array[$i]
    done
    
    # Reindex arrays
    pid_array=("${pid_array[@]}")
    result_array=("${result_array[@]}")
}

# Clean test environment
clean_test_environment() {
    log_info "Cleaning test environment..."
    
    # Remove test temp directory
    rm -rf "$TEST_TEMP_DIR"
    
    # Clean up any leftover coordination files
    rm -f /tmp/availably-test-*
    
    # Clean up results directory
    rm -rf "$TEST_RESULTS_DIR"
    mkdir -p "$TEST_RESULTS_DIR"
    
    log_success "Test environment cleaned"
}

# Main execution function
main() {
    local run_all=false
    local run_unit=false
    local run_integration=false
    local run_concurrency=false
    local run_failure=false
    local run_performance=false
    local specific_test=""
    local specific_category=""
    local clean_env=false
    local list_tests_only=false
    
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
            --concurrency)
                run_concurrency=true
                shift
                ;;
            --failure)
                run_failure=true
                shift
                ;;
            --performance)
                run_performance=true
                shift
                ;;
            --test)
                specific_test="$2"
                shift 2
                ;;
            --category)
                specific_category="$2"
                shift 2
                ;;
            --parallel)
                PARALLEL_TESTS=true
                shift
                ;;
            --max-parallel)
                MAX_PARALLEL_TESTS="$2"
                shift 2
                ;;
            --timeout)
                TEST_TIMEOUT="$2"
                shift 2
                ;;
            --log-level)
                TEST_LOG_LEVEL="$2"
                shift 2
                ;;
            --results-dir)
                TEST_RESULTS_DIR="$2"
                mkdir -p "$TEST_RESULTS_DIR"
                shift 2
                ;;
            --clean)
                clean_env=true
                shift
                ;;
            --list)
                list_tests_only=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Handle list command
    if [ "$list_tests_only" = true ]; then
        list_tests
        exit 0
    fi
    
    # Clean environment if requested
    if [ "$clean_env" = true ]; then
        clean_test_environment
    fi
    
    # Initialize test environment
    mkdir -p "$TEST_RESULTS_DIR"
    echo "test_id,status,message,timestamp" > "$TEST_RESULTS_DIR/test-results.csv"
    
    log_info "Starting coordination system tests"
    log_info "Log level: $TEST_LOG_LEVEL"
    log_info "Test timeout: $TEST_TIMEOUT seconds"
    log_info "Results directory: $TEST_RESULTS_DIR"
    
    local total_failed=0
    local categories_to_run=()
    
    # Determine which tests to run
    if [ -n "$specific_test" ]; then
        log_info "Running specific test: $specific_test"
        if ! run_test_by_id "$specific_test"; then
            total_failed=$((total_failed + 1))
        fi
    elif [ -n "$specific_category" ]; then
        log_info "Running specific category: $specific_category"
        if ! run_category_tests "$specific_category"; then
            total_failed=$((total_failed + 1))
        fi
    else
        # Build list of categories to run
        if [ "$run_all" = true ]; then
            categories_to_run=("${AVAILABLE_CATEGORIES[@]}")
        else
            [ "$run_unit" = true ] && categories_to_run+=("unit")
            [ "$run_integration" = true ] && categories_to_run+=("integration")
            [ "$run_concurrency" = true ] && categories_to_run+=("concurrency")
            [ "$run_failure" = true ] && categories_to_run+=("failure")
            [ "$run_performance" = true ] && categories_to_run+=("performance")
        fi
        
        # Default to all if nothing specified
        if [ ${#categories_to_run[@]} -eq 0 ]; then
            log_info "No specific tests specified, running all tests"
            categories_to_run=("${AVAILABLE_CATEGORIES[@]}")
        fi
        
        # Run tests
        if [ "$PARALLEL_TESTS" = true ] && [ ${#categories_to_run[@]} -gt 1 ]; then
            run_parallel_tests "${categories_to_run[@]}"
            total_failed=$?
        else
            for category in "${categories_to_run[@]}"; do
                if ! run_category_tests "$category"; then
                    total_failed=$((total_failed + 1))
                fi
            done
        fi
    fi
    
    # Generate final report
    log_info "Test execution completed"
    if ! generate_test_report; then
        total_failed=$((total_failed + $?))
    fi
    
    # Exit with appropriate code
    if [ $total_failed -eq 0 ]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed"
        exit 1
    fi
}

# Handle being called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi