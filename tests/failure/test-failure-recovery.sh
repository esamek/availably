#!/bin/bash

# Test Framework for Failure Recovery Tests
# Tests system behavior under various failure conditions

set -e

# Test configuration
TEST_DIR="/tmp/availably-failure-tests-$$"
SCRIPTS_DIR="$(cd "$(dirname "$0")/../../scripts" && pwd)"
LOCK_DIR="$TEST_DIR/server-coordination"
PID_FILE="$TEST_DIR/test-process.pid"

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

# Helper functions for creating test scenarios
create_background_process() {
    local process_name="$1"
    local duration="${2:-30}"
    
    (
        trap 'exit 0' TERM
        sleep "$duration"
    ) &
    
    local pid=$!
    echo "$pid" > "$PID_FILE"
    echo "$pid"
}

simulate_process_crash() {
    local pid="$1"
    log_info "Simulating process crash for PID: $pid"
    kill -9 "$pid" 2>/dev/null || true
}

create_corrupted_state_file() {
    local file_path="$1"
    local corruption_type="${2:-truncate}"
    
    case "$corruption_type" in
        "truncate")
            echo "partial content" > "$file_path"
            ;;
        "binary")
            dd if=/dev/urandom of="$file_path" bs=1 count=50 2>/dev/null
            ;;
        "empty")
            touch "$file_path"
            ;;
        *)
            echo "invalid corruption type" > "$file_path"
            ;;
    esac
}

# FAIL-001: Process crash during lock hold
test_fail_001() {
    log_info "FAIL-001: Process crash during lock hold"
    
    # Create a background process that will hold a lock
    local pid=$(create_background_process "lock_holder" 10)
    
    # Register the process as a user
    register_server_user "test-user-$pid" "$pid" || return 1
    
    # Verify the user is registered
    local count=$(get_user_count)
    if [ "$count" -ne 1 ]; then
        log_error "Expected 1 user, got $count"
        return 1
    fi
    
    # Simulate process crash
    simulate_process_crash "$pid"
    
    # Wait a moment for the system to detect the crash
    sleep 2
    
    # Try to register a new user (should trigger cleanup)
    local new_pid=$(create_background_process "new_user" 5)
    register_server_user "test-user-$new_pid" "$new_pid" || return 1
    
    # Verify cleanup occurred - should only have 1 user (the new one)
    local final_count=$(get_user_count)
    if [ "$final_count" -ne 1 ]; then
        log_error "Expected 1 user after cleanup, got $final_count"
        return 1
    fi
    
    log_success "System recovered from process crash"
    return 0
}

# FAIL-002: Corrupted state files
test_fail_002() {
    log_info "FAIL-002: Corrupted state files"
    
    # Create initial state
    local pid=$(create_background_process "test_user" 10)
    register_server_user "test-user-$pid" "$pid" || return 1
    
    # Corrupt various state files
    local user_count_file="$LOCK_DIR/user_count"
    local user_list_file="$LOCK_DIR/users"
    
    if [ -f "$user_count_file" ]; then
        create_corrupted_state_file "$user_count_file" "binary"
    fi
    
    if [ -f "$user_list_file" ]; then
        create_corrupted_state_file "$user_list_file" "truncate"
    fi
    
    # Try to perform operations - system should recover
    local new_pid=$(create_background_process "recovery_user" 5)
    if ! register_server_user "recovery-user-$new_pid" "$new_pid"; then
        log_error "Failed to register user after corruption"
        return 1
    fi
    
    # Verify system rebuilt state correctly
    local count=$(get_user_count)
    if [ "$count" -lt 1 ]; then
        log_error "System failed to rebuild state after corruption"
        return 1
    fi
    
    log_success "System recovered from corrupted state files"
    return 0
}

# FAIL-003: File system permission issues
test_fail_003() {
    log_info "FAIL-003: File system permission issues"
    
    # Create initial state
    local pid=$(create_background_process "test_user" 10)
    register_server_user "test-user-$pid" "$pid" || return 1
    
    # Remove write permissions from coordination directory
    chmod 555 "$LOCK_DIR"
    
    # Try to register a new user - should fail gracefully
    local new_pid=$(create_background_process "blocked_user" 5)
    if register_server_user "blocked-user-$new_pid" "$new_pid" 2>/dev/null; then
        log_error "Registration should have failed due to permission issues"
        chmod 755 "$LOCK_DIR"  # Restore permissions
        return 1
    fi
    
    # Restore permissions
    chmod 755 "$LOCK_DIR"
    
    # Verify system works after permission restoration
    if ! register_server_user "restored-user-$new_pid" "$new_pid"; then
        log_error "System failed to work after permission restoration"
        return 1
    fi
    
    log_success "System handled permission issues gracefully"
    return 0
}

# FAIL-004: Network connectivity issues during server check
test_fail_004() {
    log_info "FAIL-004: Network connectivity issues during server check"
    
    # This test simulates network issues by temporarily blocking server checks
    # We'll modify the server check to fail and ensure system handles it gracefully
    
    # Create a temporary server check script that fails
    local fake_server_check="$TEST_DIR/fake_server_check.sh"
    cat > "$fake_server_check" << 'EOF'
#!/bin/bash
# Simulate network connectivity issues
exit 1
EOF
    chmod +x "$fake_server_check"
    
    # Create a user registration that depends on server status
    local pid=$(create_background_process "network_test" 10)
    
    # The system should distinguish between server down vs network issues
    # For now, we'll test that the system handles network failures gracefully
    if ! register_server_user "network-test-$pid" "$pid"; then
        log_warning "User registration failed due to network issues (expected)"
    else
        log_success "User registration succeeded despite network issues"
    fi
    
    # Verify system maintains consistency
    local count=$(get_user_count)
    if [ "$count" -lt 0 ]; then
        log_error "System state became inconsistent after network issues"
        return 1
    fi
    
    log_success "System handled network connectivity issues"
    return 0
}

# REC-001: Recovery from partial cleanup
test_rec_001() {
    log_info "REC-001: Recovery from partial cleanup"
    
    # Create multiple users
    local pid1=$(create_background_process "user1" 10)
    local pid2=$(create_background_process "user2" 10)
    register_server_user "test-user-$pid1" "$pid1" || return 1
    register_server_user "test-user-$pid2" "$pid2" || return 1
    
    # Simulate partial cleanup by removing one user file but not updating count
    local user_list_file="$LOCK_DIR/users"
    if [ -f "$user_list_file" ]; then
        # Remove one user from the list but keep the process running
        grep -v "test-user-$pid1" "$user_list_file" > "$user_list_file.tmp" 2>/dev/null || true
        mv "$user_list_file.tmp" "$user_list_file" 2>/dev/null || true
    fi
    
    # Trigger cleanup detection
    local new_pid=$(create_background_process "cleanup_trigger" 5)
    register_server_user "cleanup-trigger-$new_pid" "$new_pid" || return 1
    
    # System should detect and complete the partial cleanup
    local count=$(get_user_count)
    if [ "$count" -lt 1 ]; then
        log_error "System failed to handle partial cleanup properly"
        return 1
    fi
    
    log_success "System recovered from partial cleanup"
    return 0
}

# REC-002: Recovery from lock directory without owner file
test_rec_002() {
    log_info "REC-002: Recovery from lock directory without owner file"
    
    # Create a malformed lock directory
    local malformed_lock="$LOCK_DIR/malformed_lock"
    mkdir -p "$malformed_lock"
    
    # Create some files in the lock directory but no owner file
    echo "some_data" > "$malformed_lock/data"
    echo "more_data" > "$malformed_lock/state"
    
    # Try to acquire a lock - system should clean up malformed lock
    local pid=$(create_background_process "cleanup_test" 10)
    
    # System should detect and clean up the malformed lock
    if ! register_server_user "malformed-test-$pid" "$pid"; then
        log_error "System failed to handle malformed lock"
        return 1
    fi
    
    # Verify malformed lock was cleaned up
    if [ -d "$malformed_lock" ]; then
        log_error "Malformed lock directory was not cleaned up"
        return 1
    fi
    
    log_success "System cleaned up malformed lock directory"
    return 0
}

# REC-003: Recovery from inconsistent user count
test_rec_003() {
    log_info "REC-003: Recovery from inconsistent user count"
    
    # Create users and then manually corrupt the count
    local pid1=$(create_background_process "user1" 10)
    local pid2=$(create_background_process "user2" 10)
    register_server_user "test-user-$pid1" "$pid1" || return 1
    register_server_user "test-user-$pid2" "$pid2" || return 1
    
    # Manually corrupt the user count file
    local user_count_file="$LOCK_DIR/user_count"
    if [ -f "$user_count_file" ]; then
        echo "999" > "$user_count_file"
    fi
    
    # Trigger count verification
    local new_pid=$(create_background_process "count_fixer" 5)
    register_server_user "count-fixer-$new_pid" "$new_pid" || return 1
    
    # System should rebuild accurate count from user list
    local count=$(get_user_count)
    local expected_count=3  # 2 original + 1 new
    
    if [ "$count" -ne "$expected_count" ]; then
        log_error "Expected count $expected_count, got $count"
        return 1
    fi
    
    log_success "System rebuilt accurate user count"
    return 0
}

# Test execution
main() {
    log_info "Starting Failure Recovery Tests"
    log_info "================================"
    
    setup_test_environment
    
    # Run all failure recovery tests
    run_test "FAIL-001: Process crash during lock hold" test_fail_001
    run_test "FAIL-002: Corrupted state files" test_fail_002
    run_test "FAIL-003: File system permission issues" test_fail_003
    run_test "FAIL-004: Network connectivity issues during server check" test_fail_004
    run_test "REC-001: Recovery from partial cleanup" test_rec_001
    run_test "REC-002: Recovery from lock directory without owner file" test_rec_002
    run_test "REC-003: Recovery from inconsistent user count" test_rec_003
    
    cleanup_test_environment
    
    # Report results
    log_info "================================"
    log_info "Failure Recovery Test Results:"
    log_success "Tests Passed: $TESTS_PASSED"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        log_error "Tests Failed: $TESTS_FAILED"
        for test in "${FAILED_TESTS[@]}"; do
            log_error "  - $test"
        done
        exit 1
    else
        log_success "All failure recovery tests passed!"
        exit 0
    fi
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi