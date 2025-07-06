#!/bin/bash

# Development Server Detection Script
# This script helps agents detect if the development server is already running
# Usage: ./scripts/check-dev-server.sh
# Exit codes: 0 = running, 1 = not running, 2 = stuck/needs restart

# Load coordination library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/server-coordination.sh"

echo "🔍 Checking development server status..."

# Show coordination info first
get_server_info
echo ""

# Check if vite process is running
VITE_PID=$(pgrep -f "node.*vite.*--host.*--port 5173" 2>/dev/null)
if [ -z "$VITE_PID" ]; then
    echo "❌ No vite process found"
    echo "✅ Safe to start development server with: ./scripts/start-dev-server.sh"
    exit 1
fi

echo "⚡ Found vite process (PID: $VITE_PID)"

# Test HTTP connectivity
if curl -s --max-time 3 http://localhost:5173/ >/dev/null 2>&1; then
    echo "✅ Development server is running and responding"
    echo "🌐 Available at: http://localhost:5173/"
    exit 0
else
    echo "⚠️  Vite process exists but server not responding"
    echo "🔧 Server appears stuck - use stop-dev-server.sh to clean up"
    exit 2
fi