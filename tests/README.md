# Server Coordination System Tests

This directory contains comprehensive tests for the Availably server coordination system, focusing on failure recovery and performance validation.

## Test Structure

```
tests/
├── failure/
│   ├── test-failure-recovery.sh  # Main failure recovery tests (FAIL-001 to REC-003)
│   └── test-edge-cases.sh        # Edge case and stress tests
├── performance/
│   └── test-performance.sh       # Performance benchmarks (PERF-001 to PERF-004)
├── run-all-tests.sh              # Comprehensive test runner
└── README.md                     # This file
```

## Quick Start

### Run All Tests
```bash
./run-all-tests.sh
```

### Run Specific Test Suites
```bash
# Only failure recovery tests
./run-all-tests.sh --failure

# Only performance tests
./run-all-tests.sh --performance

# Check system requirements
./run-all-tests.sh --check
```

### Run Individual Test Files
```bash
# Failure recovery tests
./failure/test-failure-recovery.sh

# Performance tests
./performance/test-performance.sh

# Edge case tests
./failure/test-edge-cases.sh
```

## Test Categories

### Failure Recovery Tests (`test-failure-recovery.sh`)

Tests system behavior under various failure conditions:

- **FAIL-001**: Process crash during lock hold
- **FAIL-002**: Corrupted state files
- **FAIL-003**: File system permission issues
- **FAIL-004**: Network connectivity issues during server check
- **REC-001**: Recovery from partial cleanup
- **REC-002**: Recovery from lock directory without owner file
- **REC-003**: Recovery from inconsistent user count

### Performance Tests (`test-performance.sh`)

Validates system performance meets specified benchmarks:

- **PERF-001**: Lock acquisition time under normal conditions (< 1 second)
- **PERF-002**: System performance with 10+ concurrent users
- **PERF-003**: Cleanup performance with many dead registrations (< 5 seconds)
- **PERF-004**: Server start time with coordination overhead (< 10 seconds)

### Edge Case Tests (`test-edge-cases.sh`)

Tests unusual but possible scenarios:

- **EDGE-001**: Extremely long user names
- **EDGE-002**: Special characters in user names
- **EDGE-003**: Rapid registration and deregistration cycles
- **EDGE-004**: Disk full simulation
- **EDGE-005**: Lock contention stress test
- **EDGE-006**: Complete file system corruption recovery
- **EDGE-007**: Maximum concurrent users test
- **EDGE-008**: Recovery from partial writes

## System Requirements

### Required Commands
- `bash` - Shell interpreter
- `kill` - Process termination
- `pgrep` - Process search
- `date` - Timestamp utilities
- `chmod` - File permissions
- `mkdir` - Directory creation
- `rm` - File removal

### Optional Commands
- `bc` - Floating point arithmetic (for precise timing)
- `dd` - Data manipulation (for corruption tests)
- `stat` - File statistics

### Dependencies
- Server coordination library: `../scripts/lib/server-coordination.sh`
- Server locking library: `../scripts/lib/server-locking.sh`

## Test Execution Environment

### Isolation
- Each test runs in isolated temporary directories
- No interference between concurrent test runs
- Clean state before and after each test
- Proper cleanup of test artifacts

### Temporary Files
- Test files created in `/tmp/availably-*-tests-$$`
- Automatic cleanup on test completion
- Process IDs tracked to prevent orphaned processes

## Understanding Test Results

### Success Criteria
- **Functional**: All coordination operations complete successfully
- **Data Integrity**: No corruption or inconsistent state
- **Error Handling**: Graceful degradation and recovery
- **Performance**: Operations complete within specified timeframes

### Performance Benchmarks
- **Lock acquisition**: < 1 second (normal), < 30 seconds (contention)
- **Server startup**: < 10 seconds including coordination
- **User registration/release**: < 2 seconds
- **Cleanup operations**: < 5 seconds

### Failure Tolerance
- **Data loss**: 0% tolerance
- **Single-point failures**: 100% recovery rate
- **Resource constraints**: Graceful degradation
- **Common failures**: Automatic recovery

## Test Output

### Console Output
```
[INFO] Starting Failure Recovery Tests
[INFO] ================================
[INFO] Running test: FAIL-001: Process crash during lock hold
[SUCCESS] PASS: FAIL-001: Process crash during lock hold
[TIMING] PERF-001: 0.234s (benchmark: 1s)
[SUCCESS] All tests passed!
```

### Log Files
- Detailed execution logs: `/tmp/availably-test-results-YYYYMMDD-HHMMSS.log`
- Test reports: `/tmp/availably-test-report-YYYYMMDD-HHMMSS.md`

## Troubleshooting

### Common Issues

**Permission Denied**
```bash
chmod +x run-all-tests.sh
chmod +x failure/test-failure-recovery.sh
chmod +x performance/test-performance.sh
```

**Missing Dependencies**
```bash
# Check system requirements
./run-all-tests.sh --check

# Install missing tools (example for Ubuntu)
sudo apt-get install bc
```

**Tests Timeout**
- Increase timeout values in test scripts
- Check for stuck processes: `pgrep -f availably-test`
- Clean up manually: `pkill -f availably-test`

**Disk Space Issues**
```bash
# Clean up test artifacts
rm -rf /tmp/availably-*-tests-*
```

### Debug Mode
```bash
# Run with debug output
bash -x ./run-all-tests.sh

# Run individual test with debug
bash -x ./failure/test-failure-recovery.sh
```

## Adding New Tests

### Test Function Template
```bash
test_new_feature() {
    log_info "NEW-001: Description of new test"
    
    # Setup test scenario
    local pid=$(create_background_process "test_name" 30)
    
    # Execute test
    if register_user "test-user" "$pid"; then
        log_success "Test passed"
        return 0
    else
        log_error "Test failed"
        return 1
    fi
}
```

### Integration
1. Add test function to appropriate test file
2. Add test to main execution in `main()` function
3. Update this README with test description
4. Run tests to verify integration

## Continuous Integration

### Automated Testing
```bash
# Run tests automatically
./run-all-tests.sh > test-results.log 2>&1
echo "Exit code: $?"
```

### Test Reporting
- Test results logged to timestamped files
- Markdown reports generated automatically
- Performance metrics tracked over time
- Failed tests clearly identified

## Performance Monitoring

### Key Metrics
- Lock acquisition time
- User registration/deregistration speed
- Cleanup efficiency
- System resource usage
- Concurrent user handling

### Benchmarking
- Run performance tests regularly
- Compare results over time
- Identify performance regressions
- Optimize based on bottlenecks

## Safety Considerations

### Test Isolation
- Tests run in isolated environments
- No impact on production systems
- Temporary files automatically cleaned up
- Test processes properly terminated

### Resource Management
- Tests respect system resource limits
- Automatic cleanup prevents resource leaks
- Graceful handling of system constraints
- Monitoring of system impact during tests

## Contributing

### Test Development Guidelines
1. Follow existing test structure and naming conventions
2. Include both positive and negative test cases
3. Test edge cases and error conditions
4. Provide clear, descriptive test names
5. Include proper cleanup and error handling
6. Document expected behavior and benchmarks

### Code Review Checklist
- [ ] Tests isolated and don't interfere with each other
- [ ] Proper cleanup of temporary files and processes
- [ ] Clear success/failure criteria
- [ ] Appropriate error handling
- [ ] Performance benchmarks realistic
- [ ] Documentation updated

This comprehensive test suite ensures the server coordination system is robust, performant, and ready for production use with parallel subagents.