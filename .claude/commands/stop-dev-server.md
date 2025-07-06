# Stop Development Server

Safely stops the development server with automatic coordination and cleanup.

## Usage

```bash
./scripts/stop-dev-server.sh [--force] [--wait] [agent-id]
```

## Options

- `--force` - Force stop even if other agents are using the server
- `--wait` - Wait for other agents to finish before stopping
- `agent-id` - Custom agent identifier (optional)

## What it does

1. **Coordination Check**: Verifies if other agents are using the server
2. **Graceful Shutdown**: Attempts SIGTERM first, then SIGKILL if needed
3. **Process Detection**: Finds the correct vite process using updated patterns
4. **Cleanup**: Removes coordination files and releases locks
5. **Status Reporting**: Provides clear feedback throughout the process

## Examples

### Basic stop (respects other users)
```bash
./scripts/stop-dev-server.sh
```

### Force stop (ignores other users)
```bash
./scripts/stop-dev-server.sh --force
```

### Wait for other agents to finish
```bash
./scripts/stop-dev-server.sh --wait
```

### Stop with custom agent ID
```bash
./scripts/stop-dev-server.sh my-agent-123
```

## Scenarios handled

- **No server running**: Reports status and exits cleanly
- **Other agents active**: Warns and suggests options (unless --force)
- **Graceful shutdown**: Tries SIGTERM first, waits up to 10 seconds
- **Stuck process**: Uses SIGKILL as fallback
- **Coordination cleanup**: Removes all temporary files and locks

## Example output

```
🛑 Stopping development server...
   Agent ID: stop-agent-12345
   Force Stop: false
🔒 Lock acquired (PID: 12345)
🧹 Cleaning up dead user registrations: agent-98765 (PID: 98765)
📊 Updated user count after cleanup: 0
🔌 Stopping vite process (PID: 78982)...
✅ Development server stopped successfully
🧹 Cleaning up coordination files...
✅ Coordination cleanup complete
🔓 Lock released
🧹 Server shutdown complete
```

## When to use

- **After development**: Clean shutdown when done coding
- **Before system restart**: Ensure clean process termination
- **Debugging server issues**: Force stop stuck servers
- **Multi-agent scenarios**: Coordinate shutdown with other agents
- **CI/CD pipelines**: Reliable server cleanup in automated environments

## Safety features

- **Lock-based coordination**: Prevents conflicts between multiple stop attempts
- **User reference counting**: Protects against stopping server in use by others
- **Graceful shutdown**: Allows vite to clean up properly before force kill
- **Process verification**: Confirms server actually stopped
- **Comprehensive cleanup**: Removes all coordination artifacts

## Troubleshooting

### Server won't stop
```bash
# Force kill the process
./scripts/stop-dev-server.sh --force
```

### Other agents preventing stop
```bash
# Wait for them to finish
./scripts/stop-dev-server.sh --wait

# Or force stop anyway
./scripts/stop-dev-server.sh --force
```

### Cleanup coordination files manually
```bash
# If script fails, manual cleanup
rm -f /tmp/availably-*
```