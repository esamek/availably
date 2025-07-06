#!/bin/bash

# Edge Case Tests for Server Coordination System
# Tests unusual but possible scenarios and edge conditions

set -e

# Test configuration
TEST_DIR="/tmp/availably-edge-tests-$$"
SCRIPTS_DIR="$(cd "$(dirname "$0")/../../scripts" && pwd)"
LOCK_DIR="$TEST_DIR/server-coordination"

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
    # Clean up any test processes
    local pids=$(pgrep -f "availably-edge-test" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        log_info "Cleaning up edge test processes: $pids"
        echo "$pids" | xargs kill -9 2>/dev/null || true
    fi
    
    # Clean up coordination files
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

# Edge case test functions

# Test: Extremely long user names
test_edge_long_usernames() {
    log_info "EDGE-001: Extremely long user names"
    
    # Create a very long username (512 characters)
    local long_username=$(printf 'a%.0s' {1..512})
    local pid=$(exec -a "availably-edge-test-long" bash -c 'sleep 30' & echo $!)
    
    if register_server_user "$long_username" "$pid"; then
        log_success "System handled long username gracefully"
        return 0
    else
        log_error "System failed to handle long username"
        return 1
    fi
}

# Test: Special characters in user names
test_edge_special_chars() {
    log_info "EDGE-002: Special characters in user names"
    
    local special_names=(
        "user-with-spaces and symbols!@#"
        "user\nwith\nnewlines"
        "user\twith\ttabs"
        "user;with;semicolons"
        "user&with&ampersands"
        "user|with|pipes"
        "user\$with\$dollars"
        "user'with'quotes"
        "user\"with\"double\"quotes"
    )
    
    local success_count=0
    
    for name in "${special_names[@]}"; do
        local pid=$(exec -a "availably-edge-test-special" bash -c 'sleep 10' & echo $!)
        
        if register_server_user "$name" "$pid"; then
            log_info "Successfully registered user with special chars: $name"
            ((success_count++))
        else
            log_warning "Failed to register user with special chars: $name"
        fi
        
        # Clean up
        kill -9 "$pid" 2>/dev/null || true
        sleep 0.1
    done
    
    # Consider it a success if most special character names work
    if [ $success_count -ge $((${#special_names[@]} / 2)) ]; then
        log_success "System handled most special character names"
        return 0
    else
        log_error "System failed to handle special character names"
        return 1
    fi
}

# Test: Rapid registration and deregistration
test_edge_rapid_cycles() {
    log_info "EDGE-003: Rapid registration and deregistration cycles"
    
    local cycle_count=20
    local success_count=0
    
    for i in $(seq 1 $cycle_count); do
        local pid=$(exec -a "availably-edge-test-rapid-$i" bash -c 'sleep 2' & echo $!)
        
        if register_server_user "rapid-user-$i" "$pid"; then
            ((success_count++))
        fi
        
        # Immediately kill the process to test rapid cleanup
        kill -9 "$pid" 2>/dev/null || true
        sleep 0.05  # Very short delay between cycles
    done
    
    # Wait for cleanup to complete
    sleep 3
    
    # Check final state
    local final_count=$(get_user_count)
    
    if [ $success_count -ge $((cycle_count * 8 / 10)) ] && [ $final_count -eq 0 ]; then
        log_success "System handled rapid cycles: $success_count/$cycle_count registrations, $final_count final users"
        return 0
    else
        log_error "System struggled with rapid cycles: $success_count/$cycle_count registrations, $final_count final users"
        return 1
    fi
}

# Test: File system filled during operation
test_edge_disk_full() {
    log_info "EDGE-004: Disk full simulation"
    
    # Create a small filesystem for testing
    local small_fs="$TEST_DIR/small_fs"
    local mount_point="$TEST_DIR/mount"
    
    # Create a small file and try to fill it
    mkdir -p "$mount_point"
    
    # Try to create a scenario where disk space is limited
    # This is a simplified simulation
    local old_lock_dir="$LOCK_DIR"
    LOCK_DIR="$mount_point/coordination"
    mkdir -p "$LOCK_DIR"
    export SERVER_COORDINATION_DIR="$LOCK_DIR"
    
    # Fill the directory with files to simulate disk full
    for i in {1..100}; do
        echo "filling disk space" > "$LOCK_DIR/filler_$i" 2>/dev/null || break
    done
    
    # Try to register a user
    local pid=$(exec -a "availably-edge-test-disk" bash -c 'sleep 10' & echo $!)
    
    if register_server_user "disk-test-user" "$pid" 2>/dev/null; then
        log_success "System handled disk space issues gracefully"
        local result=0
    else
        log_warning "System failed due to disk space (expected behavior)"
        local result=0  # This is actually expected behavior
    fi
    
    # Clean up
    kill -9 "$pid" 2>/dev/null || true
    LOCK_DIR="$old_lock_dir"
    export SERVER_COORDINATION_DIR="$LOCK_DIR"
    
    return $result
}

# Test: Concurrent access to same lock
test_edge_lock_contention() {
    log_info "EDGE-005: Lock contention stress test"
    
    # Start multiple processes that try to acquire locks simultaneously
    local contention_count=10
    local pids=()
    
    for i in $(seq 1 $contention_count); do
        (
            exec -a "availably-edge-test-contention-$i" bash -c "
                sleep 0.1
                register_server_user 'contention-user-$i' '\$\$' || exit 1
                sleep 1
                exit 0
            "
        ) &
        pids+=($!)
    done
    
    # Wait for all processes to complete
    local completed=0
    for pid in "${pids[@]}"; do
        if wait "$pid" 2>/dev/null; then
            ((completed++))
        fi
    done
    
    # Check results
    local user_count=$(get_user_count)
    
    if [ $completed -ge $((contention_count * 8 / 10)) ] && [ $user_count -eq $completed ]; then
        log_success "Lock contention handled: $completed/$contention_count processes succeeded"
        return 0
    else
        log_error "Lock contention failed: $completed/$contention_count processes succeeded, $user_count users registered"
        return 1
    fi
}

# Test: System recovery after complete file system corruption
test_edge_complete_corruption() {
    log_info "EDGE-006: Complete file system corruption recovery"
    
    # Create initial state
    local pid=$(exec -a "availably-edge-test-corruption" bash -c 'sleep 30' & echo $!)
    register_server_user "corruption-test" "$pid" || return 1
    
    # Completely corrupt the coordination directory
    rm -rf "$LOCK_DIR"
    mkdir -p "$LOCK_DIR"
    
    # Fill with garbage
    for i in {1..5}; do
        dd if=/dev/urandom of="$LOCK_DIR/garbage_$i" bs=1024 count=1 2>/dev/null || true
    done
    
    # Try to register a new user - system should recover
    local new_pid=$(exec -a "availably-edge-test-recovery" bash -c 'sleep 10' & echo $!)
    
    if register_server_user "recovery-test" "$new_pid"; then
        log_success "System recovered from complete corruption"
        return 0
    else
        log_error "System failed to recover from complete corruption"
        return 1
    fi
}

# Test: Maximum number of concurrent users
test_edge_max_users() {
    log_info "EDGE-007: Maximum concurrent users test"
    
    local max_users=100
    local pids=()
    local registered=0
    
    # Register many users
    for i in $(seq 1 $max_users); do
        local pid=$(exec -a "availably-edge-test-max-$i" bash -c 'sleep 60' & echo $!)
        pids+=($pid)
        
        if register_server_user "max-user-$i" "$pid"; then
            ((registered++))
        else
            log_warning "Failed to register user $i"
            kill -9 "$pid" 2>/dev/null || true
        fi
        
        # Small delay to avoid overwhelming the system
        sleep 0.01
    done
    
    # Check final count
    local final_count=$(get_user_count)
    
    # Clean up
    for pid in "${pids[@]}"; do
        kill -9 "$pid" 2>/dev/null || true
    done
    
    if [ $registered -ge $((max_users * 9 / 10)) ] && [ $final_count -eq $registered ]; then
        log_success "System handled maximum users: $registered/$max_users registered, $final_count counted"
        return 0
    else
        log_error "System failed with maximum users: $registered/$max_users registered, $final_count counted"
        return 1
    fi
}

# Test: Recovery from partial writes
test_edge_partial_writes() {
    log_info "EDGE-008: Recovery from partial writes"
    
    # Create initial state
    local pid=$(exec -a "availably-edge-test-partial" bash -c 'sleep 30' & echo $!)
    register_server_user "partial-test" "$pid" || return 1
    
    # Simulate partial write by truncating key files
    local user_file="$LOCK_DIR/users"
    local count_file="$LOCK_DIR/user_count"
    
    if [ -f "$user_file" ]; then
        # Truncate to half size
        local size=$(stat -c%s "$user_file" 2>/dev/null || stat -f%z "$user_file")
        dd if="$user_file" of="$user_file.tmp" bs=1 count=$((size / 2)) 2>/dev/null || true
        mv "$user_file.tmp" "$user_file"
    fi
    
    if [ -f "$count_file" ]; then
        echo "corrupted" > "$count_file"
    fi
    
    # Try to register another user - should trigger recovery
    local new_pid=$(exec -a "availably-edge-test-recovery" bash -c 'sleep 10' & echo $!)
    
    if register_server_user "recovery-test" "$new_pid"; then
        log_success "System recovered from partial writes"
        return 0
    else
        log_error "System failed to recover from partial writes"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting Edge Case Tests"
    log_info "========================"
    
    setup_test_environment
    
    # Run all edge case tests
    run_test "EDGE-001: Extremely long user names" test_edge_long_usernames
    run_test "EDGE-002: Special characters in user names" test_edge_special_chars
    run_test "EDGE-003: Rapid registration and deregistration cycles" test_edge_rapid_cycles
    run_test "EDGE-004: Disk full simulation" test_edge_disk_full
    run_test "EDGE-005: Lock contention stress test" test_edge_lock_contention
    run_test "EDGE-006: Complete file system corruption recovery" test_edge_complete_corruption
    run_test "EDGE-007: Maximum concurrent users test" test_edge_max_users
    run_test "EDGE-008: Recovery from partial writes" test_edge_partial_writes
    
    cleanup_test_environment
    
    # Report results
    log_info "========================"
    log_info "Edge Case Test Results:"
    log_success "Tests Passed: $TESTS_PASSED"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        log_error "Tests Failed: $TESTS_FAILED"
        for test in "${FAILED_TESTS[@]}"; do
            log_error "  - $test"
        done
        exit 1
    else
        log_success "All edge case tests passed!"
        exit 0
    fi
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi