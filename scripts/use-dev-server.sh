#!/bin/bash

# Use Development Server
# Register as a user of the shared development server
# Usage: ./scripts/use-dev-server.sh [agent-id]

# Load coordination library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/server-coordination.sh"

# Configuration
AGENT_ID="${1:-agent-$$}"

echo "🔗 Registering to use development server..."
echo "   Agent ID: $AGENT_ID"

# Register as server user
if register_server_user "$AGENT_ID"; then
    echo "✅ Successfully registered as server user"
    
    # Show current status
    echo ""
    get_server_info
    
    exit 0
else
    echo "❌ Failed to register as server user"
    exit 1
fi