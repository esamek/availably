#!/bin/bash

# Safe Development Server Starter
# This script ensures the development server starts properly without conflicts
# Usage: ./scripts/start-dev-server.sh [agent-id]

# Load coordination library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/server-coordination.sh"

# Configuration
AGENT_ID="${1:-agent-$$}"

echo "🚀 Starting development server safely..."
echo "   Agent ID: $AGENT_ID"

# Acquire lock for server operations
if ! acquire_lock; then
    echo "❌ Failed to acquire server lock"
    exit 1
fi

# Clean up dead users
cleanup_dead_users

# Check if server is already running
VITE_PID=$(pgrep -f "vite" 2>/dev/null)
if [ -n "$VITE_PID" ]; then
    # Test if server is responding
    if curl -s --max-time 3 http://localhost:5173/ >/dev/null 2>&1; then
        echo "✅ Development server is already running and responding"
        echo "🌐 Available at: http://localhost:5173/"
        set_server_state "running" "$VITE_PID"
        release_lock
        exit 0
    else
        echo "⚠️  Found stuck vite process, cleaning up..."
        kill $VITE_PID 2>/dev/null
        sleep 2
    fi
fi

# Start the development server
echo "⚡ Starting development server..."
release_lock  # Release lock before starting server (which blocks)

# Start server in background and capture PID
nohup node node_modules/vite/bin/vite.js --host 0.0.0.0 --port 5173 >/dev/null 2>&1 &
SERVER_PID=$!
disown

# Wait a moment for server to start
sleep 3

# Verify server started successfully
if curl -s --max-time 5 http://localhost:5173/ >/dev/null 2>&1; then
    echo "✅ Development server started successfully"
    echo "🌐 Available at: http://localhost:5173/"
    exit 0
else
    echo "❌ Failed to start development server"
    kill $SERVER_PID 2>/dev/null
    exit 1
fi