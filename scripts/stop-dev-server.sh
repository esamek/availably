#!/bin/bash

# Stop Development Server
# Gracefully stop the development server with coordination
# Usage: ./scripts/stop-dev-server.sh [--force] [agent-id]

# Load coordination library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/server-coordination.sh"

# Configuration
FORCE_STOP=false
AGENT_ID="stop-agent-$$"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_STOP=true
            shift
            ;;
        *)
            AGENT_ID="$1"
            shift
            ;;
    esac
done

echo "🛑 Stopping development server..."
echo "   Agent ID: $AGENT_ID"
echo "   Force Stop: $FORCE_STOP"

# Acquire lock for server operations
if ! acquire_lock; then
    echo "❌ Failed to acquire server lock"
    exit 1
fi

# Clean up dead users
cleanup_dead_users

# Check if there are active users
if ! can_stop_server && [ "$FORCE_STOP" != true ]; then
    echo "⚠️  Other agents are still using the server:"
    list_server_users
    echo ""
    echo "💡 Options:"
    echo "   1. Wait for agents to finish: ./scripts/stop-dev-server.sh --wait"
    echo "   2. Force stop: ./scripts/stop-dev-server.sh --force"
    echo "   3. Let agents finish naturally"
    release_lock
    exit 1
fi

# Handle --wait option
if [ "$1" = "--wait" ]; then
    echo "🤝 Notifying other agents and waiting..."
    notify_server_stop "Graceful shutdown requested"
    
    # Release lock while waiting
    release_lock
    
    # Wait for users to finish
    if wait_for_users_to_finish 60; then
        # Re-acquire lock to proceed with shutdown
        if ! acquire_lock; then
            echo "❌ Failed to re-acquire lock after waiting"
            exit 1
        fi
    else
        echo "⏰ Timeout waiting for users - use --force to override"
        exit 1
    fi
fi

# Find and stop vite process
VITE_PID=$(pgrep -f "node.*vite.*--host.*--port 5173" 2>/dev/null)
if [ -n "$VITE_PID" ]; then
    echo "🔌 Stopping vite process (PID: $VITE_PID)..."
    
    # Try graceful shutdown first
    kill -TERM $VITE_PID 2>/dev/null
    
    # Wait for graceful shutdown
    waited=0
    while kill -0 $VITE_PID 2>/dev/null && [ $waited -lt 10 ]; do
        sleep 1
        waited=$((waited + 1))
    done
    
    # Force kill if still running
    if kill -0 $VITE_PID 2>/dev/null; then
        echo "⚡ Force killing vite process..."
        kill -KILL $VITE_PID 2>/dev/null
        sleep 1
    fi
    
    if ! kill -0 $VITE_PID 2>/dev/null; then
        echo "✅ Development server stopped successfully"
    else
        echo "❌ Failed to stop development server"
        release_lock
        exit 1
    fi
else
    echo "⚠️  No vite process found"
fi

# Clean up coordination files
cleanup_coordination_files

# Release lock
release_lock

echo "🧹 Server shutdown complete"
exit 0