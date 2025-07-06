# Test Framework Documentation

## Overview
This test framework provides comprehensive testing infrastructure for the Availably server coordination system. It supports isolated test environments, parallel execution, and detailed reporting.

## Core Components

### Main Test Runner: `test-coordination.sh`
The primary test coordinator that orchestrates all test execution.

**Usage:**
```bash
# Run all tests
./test-coordination.sh --all

# Run specific test categories
./test-coordination.sh --unit
./test-coordination.sh --integration
./test-coordination.sh --concurrency
./test-coordination.sh --failure
./test-coordination.sh --performance

# Run specific test by ID
./test-coordination.sh --test LOCK-001

# Run tests in parallel (experimental)
./test-coordination.sh --parallel --unit

# Get help
./test-coordination.sh --help
```

### Test Utilities: `test-utils.sh`
Provides common testing functions and utilities.

**Key Functions:**
- `setup_test_environment()` - Creates isolated test environment
- `cleanup_test_environment()` - Cleans up test artifacts
- `run_test()` - Executes individual test with timing
- `assert_*()` functions - Test assertions
- `mock_process()` - Creates mock processes for testing
- `start_timer()` / `end_timer()` - Performance timing

### Test Directory Structure
```
tests/
├── test-coordination.sh       # Main test runner
├── test-utils.sh             # Test utilities
├── unit/                     # Unit tests
├── integration/              # Integration tests
├── concurrency/              # Concurrency tests
├── failure/                  # Failure recovery tests
├── performance/              # Performance tests
└── results/                  # Test results and logs
```

## Test Environment Features

### Isolation
- Each test runs in a separate temporary directory
- Coordination files are isolated per test
- No interference between concurrent test runs

### Timing
- Automatic test execution timing
- Performance metrics collection
- Timer utilities for custom measurements

### Assertions
Available assertion functions:
- `assert_equals(expected, actual, message)`
- `assert_not_equals(expected, actual, message)`
- `assert_file_exists(file, message)`
- `assert_file_not_exists(file, message)`
- `assert_process_exists(pid, message)`
- `assert_process_not_exists(pid, message)`
- `assert_greater_than(actual, threshold, message)`
- `assert_less_than(actual, threshold, message)`
- `assert_contains(text, substring, message)`

### Mock Utilities
- `mock_process(duration, name)` - Create background test processes
- `kill_mock_process(pid)` - Clean up mock processes
- `wait_for_condition(cmd, timeout, interval)` - Wait for conditions

## Writing Tests

### Basic Test Structure
```bash
#!/bin/bash

# Load test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../test-utils.sh"

# Test ID: YOUR-TEST-ID
# Description: Your test description

test_your_functionality() {
    local test_id="$1"
    
    # Your test logic here
    assert_equals "expected" "actual" "Test description"
    
    return 0  # Success
}

# Main execution
main() {
    case "$1" in
        "--test")
            case "$2" in
                "YOUR-TEST-ID")
                    run_test "YOUR-TEST-ID" "test_your_functionality" "Test description"
                    ;;
                *)
                    log_error "Unknown test ID: $2"
                    exit 1
                    ;;
            esac
            ;;
        *)
            # Run all tests in this file
            run_test "YOUR-TEST-ID" "test_your_functionality" "Test description"
            ;;
    esac
    
    generate_test_report
    return $?
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
```

### Test ID Conventions
- **LOCK-xxx**: Locking system tests
- **COORD-xxx**: Coordination system tests
- **INT-xxx**: Integration tests
- **CONC-xxx**: Concurrency tests
- **FAIL-xxx**: Failure recovery tests
- **PERF-xxx**: Performance tests

## Current Test Status

### Unit Tests
- ✅ LOCK-001: Basic lock acquisition and release
- ⚠️ LOCK-002: Lock timeout behavior (partial)
- ✅ LOCK-003: Stale lock cleanup
- ⚠️ LOCK-004: Lock ownership verification (partial)
- ⚠️ COORD-001: User registration and unregistration (partial)
- ⚠️ COORD-002: Dead user cleanup (partial)
- ✅ SAMPLE-001-003: Test framework validation

### Integration Tests
- 🔄 INT-001-004: Not yet implemented

### Other Categories
- 🔄 Concurrency tests: Some implementations exist
- 🔄 Failure tests: Some implementations exist
- 🔄 Performance tests: Some implementations exist

## Features Implemented

### ✅ Core Framework
- Test runner with command-line interface
- Isolated test environments
- Test timing and reporting
- Assertion functions
- Mock process utilities

### ✅ Test Discovery
- Automatic test file discovery
- Test ID-based execution
- Category-based execution

### ✅ Environment Management
- Clean test setup/teardown
- Temporary file management
- Process cleanup

### ✅ Reporting
- CSV test results
- Console output with colors
- Test execution summaries
- Pass/fail statistics

### 🔄 In Progress
- Parallel test execution
- Test dependency management
- Advanced timing analysis
- Integration with CI/CD

## Known Issues

### Timer Compatibility
The timing functions may have compatibility issues with some bash versions. The framework falls back to second-precision timing if high-precision timing is unavailable.

### Mock Process Testing
Mock process assertions may fail in some environments due to process startup timing. Tests include appropriate timing delays.

### Directory Path Conflicts
The coordination library sets its own SCRIPT_DIR variable, which required careful path management in the test framework.

## Future Enhancements

1. **Enhanced Parallel Execution**: Better parallel test management
2. **Test Dependencies**: Support for test prerequisites
3. **Real-time Reporting**: Live test progress updates
4. **CI/CD Integration**: GitHub Actions integration
5. **Performance Benchmarking**: Baseline performance tracking
6. **Test Coverage**: Code coverage reporting
7. **Interactive Mode**: Interactive test debugging

## Usage Examples

```bash
# Development workflow
./test-coordination.sh --unit                    # Quick unit test check
./test-coordination.sh --test LOCK-001           # Debug specific test
./test-coordination.sh --all --timeout 60        # Full test suite

# CI/CD workflow
./test-coordination.sh --all --log-level ERROR   # Minimal output
./test-coordination.sh --results-dir ./ci-results # Custom results location

# Parallel development
./test-coordination.sh --parallel --concurrency  # Test concurrent features
```

The framework is designed to be extensible and can accommodate additional test categories and features as the coordination system evolves.