#!/bin/bash

# Release Development Server
# Unregister as a user of the shared development server
# Usage: ./scripts/release-dev-server.sh [agent-id]

# Load coordination library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/server-coordination.sh"

# Configuration
AGENT_ID="${1:-agent-$$}"

echo "🔗 Releasing development server usage..."
echo "   Agent ID: $AGENT_ID"

# Unregister as server user
if unregister_server_user "$AGENT_ID"; then
    echo "✅ Successfully released server usage"
    
    # Show current status
    echo ""
    get_server_info
    
    # Check if server can be stopped
    if can_stop_server; then
        echo ""
        echo "💡 No users remaining - server can be safely stopped with:"
        echo "   ./scripts/stop-dev-server.sh"
    fi
    
    exit 0
else
    echo "❌ Failed to release server usage"
    exit 1
fi