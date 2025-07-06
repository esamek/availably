# Start Development Server Safely

Starts the development server with automatic conflict detection and cleanup.

## Usage

```bash
./scripts/start-dev-server.sh
```

## What it does

1. **Status Check**: Runs `scripts/check-dev-server.sh` to detect current state
2. **Conflict Resolution**: Automatically handles running/stuck servers
3. **Safe Start**: Only starts if no conflicts detected
4. **Feedback**: Provides clear status updates throughout process

## Scenarios handled

- **Server already running**: Exits with success message
- **No server running**: Starts fresh server
- **Stuck server**: Kills stuck process, then starts fresh
- **Multiple conflicts**: Handles edge cases gracefully

## Example output

```
🚀 Starting development server safely...
🔍 Checking development server status...
❌ No vite process found
✅ Safe to start development server with: npm run dev
⚡ Starting development server...

> availably-app@0.0.0 dev
> vite

  VITE v7.0.0  ready in 90 ms
  ➜  Local:   http://localhost:5173/
```

## When to use

- **Primary method** for starting development server
- When `npm run dev` times out or hangs
- Before running tests that need the server
- In automated scripts or CI/CD pipelines
- When multiple agents need server access

## Benefits over `npm run dev`

- Prevents timeout issues in tool environments
- Automatically detects and resolves conflicts
- Provides better feedback and error handling
- Safe for concurrent agent usage