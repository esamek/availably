#!/bin/bash

# Server Coordination Library
# Provides reference counting and state management for shared development server

# Load locking library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/server-locking.sh"

# Configuration (use environment variables if set, otherwise use defaults)
SERVER_STATE_FILE="${SERVER_STATE_FILE:-/tmp/availably-dev-server.state}"
USERS_COUNT_FILE="${USERS_COUNT_FILE:-/tmp/availably-server-users.count}" 
USERS_LIST_FILE="${USERS_LIST_FILE:-/tmp/availably-server-users.list}"

# Server state management
get_server_state() {
    if [ -f "$SERVER_STATE_FILE" ]; then
        cat "$SERVER_STATE_FILE"
    else
        echo "unknown"
    fi
}

set_server_state() {
    local state="$1"
    local pid="$2"
    local timestamp=$(date +%s)
    echo "$state:$pid:$timestamp" > "$SERVER_STATE_FILE"
}

get_server_pid() {
    local state=$(get_server_state)
    if [ "$state" != "unknown" ]; then
        echo "$state" | cut -d: -f2
    fi
}

get_server_status() {
    local state=$(get_server_state)
    if [ "$state" != "unknown" ]; then
        echo "$state" | cut -d: -f1
    else
        echo "unknown"
    fi
}

# User reference counting
get_user_count() {
    if [ -f "$USERS_COUNT_FILE" ]; then
        cat "$USERS_COUNT_FILE"
    else
        echo "0"
    fi
}

increment_users() {
    local agent_id="${1:-agent-$$}"
    local current_count=$(get_user_count)
    local new_count=$((current_count + 1))
    
    echo "$new_count" > "$USERS_COUNT_FILE"
    
    # Add to users list
    local timestamp=$(date +%s)
    echo "$agent_id:$$:$timestamp:$(whoami)" >> "$USERS_LIST_FILE"
    
    echo "📊 Server users: $new_count (added: $agent_id)"
    return $new_count
}

decrement_users() {
    local agent_id="${1:-agent-$$}"
    local current_count=$(get_user_count)
    
    if [ $current_count -le 0 ]; then
        echo "⚠️  User count already at 0"
        return 0
    fi
    
    local new_count=$((current_count - 1))
    
    if [ $new_count -le 0 ]; then
        rm -f "$USERS_COUNT_FILE"
        rm -f "$USERS_LIST_FILE"
        echo "📊 Server users: 0 (removed: $agent_id) - can safely stop"
        return 0
    else
        echo "$new_count" > "$USERS_COUNT_FILE"
        
        # Remove from users list
        if [ -f "$USERS_LIST_FILE" ]; then
            grep -v "^$agent_id:" "$USERS_LIST_FILE" > "$USERS_LIST_FILE.tmp" && mv "$USERS_LIST_FILE.tmp" "$USERS_LIST_FILE"
        fi
        
        echo "📊 Server users: $new_count (removed: $agent_id) - keep running"
        return $new_count
    fi
}

# List current users
list_server_users() {
    if [ ! -f "$USERS_LIST_FILE" ]; then
        echo "👤 No registered users"
        return 0
    fi
    
    echo "👥 Current server users:"
    while IFS=: read -r list_agent_id list_pid list_timestamp list_user; do
        local age=$(($(date +%s) - list_timestamp))
        echo "  - $list_agent_id (PID: $list_pid, User: $list_user, Age: ${age}s)"
    done < "$USERS_LIST_FILE"
}

# Clean up dead user registrations
cleanup_dead_users() {
    if [ ! -f "$USERS_LIST_FILE" ]; then
        return 0
    fi
    
    local temp_file="$USERS_LIST_FILE.cleanup"
    local cleaned=false
    
    while IFS=: read -r cleanup_agent_id cleanup_pid cleanup_timestamp cleanup_user; do
        # Check if process still exists
        if kill -0 "$cleanup_pid" 2>/dev/null; then
            echo "$cleanup_agent_id:$cleanup_pid:$cleanup_timestamp:$cleanup_user" >> "$temp_file"
        else
            echo "🧹 Cleaning up dead user registration: $cleanup_agent_id (PID: $cleanup_pid)"
            cleaned=true
        fi
    done < "$USERS_LIST_FILE"
    
    if [ "$cleaned" = true ]; then
        if [ -f "$temp_file" ]; then
            mv "$temp_file" "$USERS_LIST_FILE"
            # Update count
            local new_count=$(wc -l < "$USERS_LIST_FILE" 2>/dev/null || echo "0")
            echo "$new_count" > "$USERS_COUNT_FILE"
            echo "📊 Updated user count after cleanup: $new_count"
        else
            # No users left
            rm -f "$USERS_LIST_FILE" "$USERS_COUNT_FILE"
            echo "📊 No users remaining after cleanup"
        fi
    else
        rm -f "$temp_file"
    fi
}

# Register as server user
register_server_user() {
    local agent_id="${1:-agent-$$}"
    
    if ! acquire_lock; then
        echo "❌ Failed to acquire lock for user registration"
        return 1
    fi
    
    # Clean up dead users first
    cleanup_dead_users
    
    # Check if already registered
    if [ -f "$USERS_LIST_FILE" ] && grep -q "^$agent_id:" "$USERS_LIST_FILE"; then
        echo "⚠️  Agent $agent_id already registered"
        release_lock
        return 0
    fi
    
    # Register user
    increment_users "$agent_id"
    
    release_lock
    echo "✅ Registered as server user: $agent_id"
    return 0
}

# Unregister as server user
unregister_server_user() {
    local agent_id="${1:-agent-$$}"
    
    if ! acquire_lock; then
        echo "❌ Failed to acquire lock for user unregistration"
        return 1
    fi
    
    # Clean up dead users first
    cleanup_dead_users
    
    # Check if registered
    if [ ! -f "$USERS_LIST_FILE" ] || ! grep -q "^$agent_id:" "$USERS_LIST_FILE"; then
        echo "⚠️  Agent $agent_id not registered"
        release_lock
        return 0
    fi
    
    # Unregister user
    decrement_users "$agent_id"
    local remaining_users=$?
    
    release_lock
    echo "✅ Unregistered server user: $agent_id"
    return $remaining_users
}

# Check if server should be stopped (no users)
can_stop_server() {
    cleanup_dead_users
    local user_count=$(get_user_count)
    return $user_count  # Returns 0 (true) if count is 0
}

# Wait for all users to finish
wait_for_users_to_finish() {
    local timeout=${1:-60}
    local waited=0
    
    echo "🤝 Waiting for other agents to finish..."
    
    while ! can_stop_server; do
        if [ $waited -ge $timeout ]; then
            echo "⏰ Timeout waiting for users to finish"
            list_server_users
            return 1
        fi
        
        local user_count=$(get_user_count)
        echo "⏳ Waiting for $user_count users to finish... (${waited}s)"
        list_server_users
        
        sleep 5
        waited=$((waited + 5))
        cleanup_dead_users
    done
    
    echo "✅ All users finished"
    return 0
}

# Notify users of impending server stop
notify_server_stop() {
    local stop_reason="${1:-Server stop requested}"
    local stop_file="/tmp/availably-server-stop-request"
    
    echo "$stop_reason at $(date)" > "$stop_file"
    echo "📢 Notified users of server stop request"
}

# Check if server stop was requested
is_server_stop_requested() {
    local stop_file="/tmp/availably-server-stop-request"
    [ -f "$stop_file" ]
}

# Clear server stop request
clear_server_stop_request() {
    local stop_file="/tmp/availably-server-stop-request"
    rm -f "$stop_file"
}

# Get comprehensive server info
get_server_info() {
    echo "🔍 Development Server Status:"
    echo "  State: $(get_server_status)"
    echo "  PID: $(get_server_pid)"
    echo "  Users: $(get_user_count)"
    echo "  Lock: $(is_locked && echo "Held" || echo "Free")"
    
    if is_locked; then
        echo "  Lock Owner: $(get_lock_owner)"
    fi
    
    if is_server_stop_requested; then
        echo "  Stop Requested: Yes"
    fi
    
    echo ""
    list_server_users
}

# Clean up all coordination files
cleanup_coordination_files() {
    echo "🧹 Cleaning up coordination files..."
    rm -f "$SERVER_STATE_FILE" "$USERS_COUNT_FILE" "$USERS_LIST_FILE"
    rm -f "/tmp/availably-server-stop-request"
    rm -rf "$LOCK_FILE"
    echo "✅ Coordination cleanup complete"
}