# Parallel Subagent Server Management Analysis

## Problem Statement

When multiple subagents work in parallel, they need coordinated access to the development server without conflicts. Current scripts don't handle concurrent access safely.

## Parallel Subagent Scenarios

### 1. **Concurrent Development Tasks**
```
Agent A: UI Polish & Layout (needs server for testing)
Agent B: Algorithm Development (needs server for testing)  
Agent C: Real-time Features (needs server for testing)
Agent D: Interaction Enhancement (needs server for testing)
```

### 2. **Race Conditions**
- **Start Conflicts**: Multiple agents trying to start server simultaneously
- **Stop Conflicts**: One agent stops server while others are using it
- **Status Conflicts**: Agents making decisions based on stale server state
- **Port Conflicts**: Multiple server instances attempting to bind to same port

### 3. **Communication Gaps**
- **No Coordination**: Agents don't know about each other's server needs
- **State Assumptions**: Each agent assumes exclusive server access
- **Cleanup Confusion**: Unclear who should stop the server when done

## Design Solutions

### Option A: Shared Server with Coordination

#### **Lock-Based Coordination**
```bash
# Lock file approach
LOCK_FILE="/tmp/availably-dev-server.lock"
SERVER_STATE_FILE="/tmp/availably-dev-server.state"

# Acquire lock before server operations
acquire_lock() {
    local timeout=30
    local waited=0
    
    while ! mkdir "$LOCK_FILE" 2>/dev/null; do
        if [ $waited -ge $timeout ]; then
            echo "❌ Timeout waiting for server lock"
            return 1
        fi
        sleep 1
        waited=$((waited + 1))
    done
    
    # Store our process info
    echo "$$:$(date +%s):$USER" > "$LOCK_FILE/owner"
    return 0
}

release_lock() {
    rm -rf "$LOCK_FILE"
}
```

#### **Reference Counting**
```bash
# Track how many agents are using the server
increment_users() {
    local count_file="/tmp/availably-server-users.count"
    local current_count=0
    
    if [ -f "$count_file" ]; then
        current_count=$(cat "$count_file")
    fi
    
    echo $((current_count + 1)) > "$count_file"
    echo "📊 Server users: $((current_count + 1))"
}

decrement_users() {
    local count_file="/tmp/availably-server-users.count"
    local current_count=0
    
    if [ -f "$count_file" ]; then
        current_count=$(cat "$count_file")
    fi
    
    local new_count=$((current_count - 1))
    if [ $new_count -le 0 ]; then
        rm -f "$count_file"
        echo "📊 Server users: 0 (can safely stop)"
        return 0
    else
        echo $new_count > "$count_file"
        echo "📊 Server users: $new_count (keep running)"
        return 1
    fi
}
```

#### **State Management**
```bash
# Shared server state tracking
SERVER_STATE_FILE="/tmp/availably-dev-server.state"

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
```

### Option B: Agent-Specific Server Instances

#### **Port-Based Isolation**
```bash
# Each agent gets its own port
get_agent_port() {
    local agent_id="$1"
    local base_port=5173
    local port_offset=$(echo "$agent_id" | tr -d '[:alpha:]' | head -c 2)
    echo $((base_port + port_offset))
}

start_agent_server() {
    local agent_id="$1"
    local port=$(get_agent_port "$agent_id")
    
    echo "🚀 Starting server for $agent_id on port $port"
    VITE_PORT=$port npm run dev &
}
```

#### **Workspace Isolation**
```bash
# Each agent works in isolated directory
setup_agent_workspace() {
    local agent_id="$1"
    local workspace_dir="/tmp/availably-agent-$agent_id"
    
    if [ ! -d "$workspace_dir" ]; then
        cp -r . "$workspace_dir"
        cd "$workspace_dir"
    fi
}
```

## Recommended Approach: Shared Server with Coordination

### Justification
1. **Resource Efficiency**: Single server vs multiple instances
2. **Realistic Testing**: All agents test same server state
3. **Simpler Setup**: No port/workspace management complexity
4. **Better Integration**: Matches production environment

### Implementation Strategy

#### **Enhanced Script Architecture**
```
scripts/
├── check-dev-server.sh      # Status checking (lock-aware)
├── start-dev-server.sh      # Start with coordination
├── stop-dev-server.sh       # Stop with coordination  
├── use-dev-server.sh        # Register as server user
├── release-dev-server.sh    # Unregister as server user
└── lib/
    ├── server-coordination.sh # Shared coordination functions
    └── server-locking.sh      # Lock management functions
```

#### **Coordination Protocol**

**Agent Starting Work**:
```bash
1. ./scripts/use-dev-server.sh         # Register as user
2. ./scripts/check-dev-server.sh       # Check status
3. ./scripts/start-dev-server.sh       # Start if needed (respects locks)
4. # Do development work
5. ./scripts/release-dev-server.sh     # Unregister when done
```

**Server Lifecycle Management**:
```bash
# start-dev-server.sh (coordination-aware)
1. Acquire lock
2. Check if server already running
3. If not running: start server, update state
4. If running: verify health, register user
5. Release lock
6. Return server URL/status

# stop-dev-server.sh (coordination-aware)  
1. Acquire lock
2. Check user count
3. If users > 0: warn and exit (don't stop)
4. If users = 0: gracefully stop server
5. Clean up state files
6. Release lock
```

#### **Lock Management Details**
```bash
# Timeout handling
LOCK_TIMEOUT=30  # seconds
LOCK_RETRY_INTERVAL=1  # seconds

# Stale lock detection
MAX_LOCK_AGE=300  # 5 minutes
cleanup_stale_locks() {
    if [ -f "$LOCK_FILE/owner" ]; then
        local lock_time=$(cut -d: -f2 "$LOCK_FILE/owner")
        local current_time=$(date +%s)
        local age=$((current_time - lock_time))
        
        if [ $age -gt $MAX_LOCK_AGE ]; then
            echo "🧹 Cleaning up stale lock (age: ${age}s)"
            rm -rf "$LOCK_FILE"
        fi
    fi
}
```

### Agent Communication Patterns

#### **Status Sharing**
```bash
# Agents can see who else is using the server
list_server_users() {
    local users_file="/tmp/availably-server-users.list"
    if [ -f "$users_file" ]; then
        echo "👥 Current server users:"
        cat "$users_file"
    else
        echo "👤 No registered users"
    fi
}

register_user() {
    local agent_id="$1"
    local users_file="/tmp/availably-server-users.list"
    local timestamp=$(date +%s)
    echo "$agent_id:$$:$timestamp" >> "$users_file"
}
```

#### **Graceful Coordination**
```bash
# Polite server stopping
request_server_stop() {
    echo "🤝 Requesting other agents to finish..."
    local users_file="/tmp/availably-server-users.list"
    
    # Notify other users
    if [ -f "$users_file" ]; then
        echo "⏰ Server stop requested at $(date)" > "/tmp/availably-server-stop-request"
        # Wait for users to finish
        sleep 10
    fi
    
    # Then proceed with stop
    ./scripts/stop-dev-server.sh
}
```

## Error Handling & Recovery

### **Deadlock Prevention**
```bash
# Timeout-based lock acquisition
# Process death detection
# Stale lock cleanup
# Lock ownership verification
```

### **Consistency Guarantees**
```bash
# Atomic operations with proper error handling
# State file integrity checks
# Process validation
# Health monitoring
```

### **Failure Recovery**
```bash
# Automatic cleanup on process termination
# Lock recovery mechanisms
# State reconstruction from process inspection
# Graceful degradation
```

## Testing Strategy

### **Concurrent Access Tests**
```bash
# Simulate multiple agents starting simultaneously
# Test race conditions
# Verify lock behavior
# Validate state consistency
```

### **Failure Scenarios**
```bash
# Process crashes during lock hold
# Network interruptions
# File system issues
# Resource exhaustion
```

## Next Steps

1. **Implement coordination library** (`scripts/lib/server-coordination.sh`)
2. **Update existing scripts** to use coordination
3. **Add new scripts** (`use-dev-server.sh`, `release-dev-server.sh`)
4. **Test concurrent scenarios** with multiple agents
5. **Document coordination protocols** in Claude commands
6. **Update CLAUDE.md** with parallel agent workflows

This approach provides safe, efficient server sharing for parallel subagents while maintaining the benefits of a single shared development server.