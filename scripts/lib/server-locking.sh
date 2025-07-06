#!/bin/bash

# Server Locking Library
# Provides file-based locking for development server coordination

# Configuration (use environment variables if set, otherwise use defaults)
LOCK_FILE="${LOCK_FILE:-/tmp/availably-dev-server.lock}"
LOCK_TIMEOUT=30  # seconds
LOCK_RETRY_INTERVAL=1  # seconds
MAX_LOCK_AGE=300  # 5 minutes

# Acquire exclusive lock on server operations
# Returns: 0 on success, 1 on timeout, 2 on error
acquire_lock() {
    local timeout=${1:-$LOCK_TIMEOUT}
    local waited=0
    
    # Clean up stale locks first
    cleanup_stale_locks
    
    while ! mkdir "$LOCK_FILE" 2>/dev/null; do
        if [ $waited -ge $timeout ]; then
            echo "❌ Timeout waiting for server lock after ${timeout}s"
            return 1
        fi
        
        echo "⏳ Waiting for server lock... (${waited}s)"
        sleep $LOCK_RETRY_INTERVAL
        waited=$((waited + LOCK_RETRY_INTERVAL))
        
        # Check for stale locks periodically
        if [ $((waited % 10)) -eq 0 ]; then
            cleanup_stale_locks
        fi
    done
    
    # Store lock owner information
    local timestamp=$(date +%s)
    local owner_info="$$:$timestamp:$USER:$(hostname)"
    echo "$owner_info" > "$LOCK_FILE/owner"
    
    echo "🔒 Lock acquired (PID: $$)"
    return 0
}

# Release lock
# Returns: 0 on success, 1 on error
release_lock() {
    if [ ! -d "$LOCK_FILE" ]; then
        echo "⚠️  No lock to release"
        return 0
    fi
    
    # Verify we own the lock
    if [ -f "$LOCK_FILE/owner" ]; then
        local lock_pid=$(cut -d: -f1 "$LOCK_FILE/owner")
        if [ "$lock_pid" != "$$" ]; then
            echo "⚠️  Lock owned by different process (PID: $lock_pid)"
            return 1
        fi
    fi
    
    rm -rf "$LOCK_FILE"
    echo "🔓 Lock released"
    return 0
}

# Clean up stale locks (older than MAX_LOCK_AGE)
cleanup_stale_locks() {
    if [ ! -d "$LOCK_FILE" ]; then
        return 0
    fi
    
    if [ ! -f "$LOCK_FILE/owner" ]; then
        echo "🧹 Cleaning up malformed lock"
        rm -rf "$LOCK_FILE"
        return 0
    fi
    
    local owner_info=$(cat "$LOCK_FILE/owner")
    local lock_pid=$(echo "$owner_info" | cut -d: -f1)
    local lock_time=$(echo "$owner_info" | cut -d: -f2)
    local current_time=$(date +%s)
    local age=$((current_time - lock_time))
    
    # Check if process still exists
    if ! kill -0 "$lock_pid" 2>/dev/null; then
        echo "🧹 Cleaning up lock from dead process (PID: $lock_pid)"
        rm -rf "$LOCK_FILE"
        return 0
    fi
    
    # Check if lock is too old
    if [ $age -gt $MAX_LOCK_AGE ]; then
        echo "🧹 Cleaning up stale lock (age: ${age}s, max: ${MAX_LOCK_AGE}s)"
        rm -rf "$LOCK_FILE"
        return 0
    fi
    
    return 1  # Lock is valid
}

# Check if lock is currently held
# Returns: 0 if locked, 1 if not locked
is_locked() {
    if [ ! -d "$LOCK_FILE" ]; then
        return 1
    fi
    
    # Clean up stale locks first
    if cleanup_stale_locks; then
        return 1  # Lock was stale and cleaned up
    fi
    
    return 0  # Lock is valid and held
}

# Get lock owner information
get_lock_owner() {
    if [ ! -f "$LOCK_FILE/owner" ]; then
        echo "unknown"
        return 1
    fi
    
    local owner_info=$(cat "$LOCK_FILE/owner")
    local lock_pid=$(echo "$owner_info" | cut -d: -f1)
    local lock_time=$(echo "$owner_info" | cut -d: -f2)
    local lock_user=$(echo "$owner_info" | cut -d: -f3)
    local lock_host=$(echo "$owner_info" | cut -d: -f4)
    
    echo "PID: $lock_pid, User: $lock_user, Host: $lock_host, Time: $(date -d @$lock_time 2>/dev/null || date -r $lock_time 2>/dev/null || echo $lock_time)"
    return 0
}

# Wait for lock to be released
# Returns: 0 when lock is released, 1 on timeout
wait_for_lock_release() {
    local timeout=${1:-$LOCK_TIMEOUT}
    local waited=0
    
    while is_locked; do
        if [ $waited -ge $timeout ]; then
            echo "❌ Timeout waiting for lock release after ${timeout}s"
            return 1
        fi
        
        echo "⏳ Waiting for lock release... (${waited}s)"
        sleep $LOCK_RETRY_INTERVAL
        waited=$((waited + LOCK_RETRY_INTERVAL))
    done
    
    echo "✅ Lock released"
    return 0
}

# Execute command with lock held
# Usage: with_lock "command to execute"
with_lock() {
    local command="$1"
    local timeout=${2:-$LOCK_TIMEOUT}
    
    if ! acquire_lock "$timeout"; then
        return 1
    fi
    
    # Execute command
    eval "$command"
    local exit_code=$?
    
    # Always release lock
    release_lock
    
    return $exit_code
}