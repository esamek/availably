# Check Development Server Status

Checks if the development server is running and responds correctly.

## Usage

```bash
./scripts/check-dev-server.sh
```

## What it does

1. **Process Detection**: Looks for running vite processes
2. **HTTP Test**: Verifies server responds on port 5173
3. **Auto-cleanup**: Kills stuck processes that aren't responding
4. **Status Report**: Provides clear feedback with emojis

## Exit codes

- `0`: Server is running and responding correctly
- `1`: No server running (safe to start)
- `2`: Server process was stuck and has been cleaned up

## Example output

```
🔍 Checking development server status...
✅ Development server is running and responding
🌐 Available at: http://localhost:5173/
```

## When to use

- Before starting development work
- When `npm run dev` times out
- To debug server connection issues
- Before running other agents that need the server