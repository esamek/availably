# Development Server Startup Fixes

## Problem Analysis

### Root Cause Identified
- **Working Command**: `node node_modules/vite/bin/vite.js --host 0.0.0.0 --port 5173 &`
- **Failing Command**: `npm run dev` (exits immediately in tool environments)
- **Current Scripts**: Use `(npm run dev) &` which fails silently

### Technical Details
1. **npm run dev** translates to `vite` command
2. In tool environments, `vite` command exits immediately after printing startup message
3. **Direct node command** works correctly and keeps server running
4. Scripts rely on `npm run dev` causing coordination system to fail

## Proposed Changes

### 1. Update Script Commands
**File**: `scripts/start-dev-server.sh`
- **Current**: `(npm run dev) &`
- **New**: `(node node_modules/vite/bin/vite.js --host 0.0.0.0 --port 5173) &`

### 2. Update Package.json Scripts
**File**: `package.json`
- **Current**: `"dev": "vite"`
- **New**: `"dev": "node node_modules/vite/bin/vite.js --host 0.0.0.0 --port 5173"`

### 3. Update Check Script
**File**: `scripts/check-dev-server.sh`
- Ensure it properly detects the new node-based process
- Update process detection patterns

### 4. Update Documentation
**File**: `CLAUDE.md`
- Document the working command
- Update troubleshooting section
- Add notes about tool environment compatibility

## Implementation Plan

### Phase 1: Core Script Updates
1. Update `scripts/start-dev-server.sh` to use direct node command
2. Update `package.json` dev script
3. Test basic functionality

### Phase 2: Coordination System
1. Update `scripts/check-dev-server.sh` process detection
2. Test coordination system works with new command
3. Verify all agent scenarios work

### Phase 3: Documentation
1. Update `CLAUDE.md` with correct commands
2. Update command documentation in `.claude/commands/`
3. Test all documented workflows

## Testing Strategy

### Manual Tests
1. `./scripts/start-dev-server.sh` starts server successfully
2. `./scripts/check-dev-server.sh` detects running server
3. `npm run dev` works for direct usage
4. Server responds to HTTP requests at http://localhost:5173/

### Agent Coordination Tests
1. Multiple agents can detect server status
2. Server startup coordination works correctly
3. No conflicts with background processes

## Success Criteria
- ✅ Development server starts reliably in tool environments
- ✅ All scripts work consistently
- ✅ Server responds to HTTP requests
- ✅ Agent coordination system functions properly
- ✅ Documentation is accurate and up-to-date

## Files to Modify
1. `scripts/start-dev-server.sh` - Primary server startup script
2. `scripts/check-dev-server.sh` - Process detection update
3. `package.json` - Update dev script
4. `CLAUDE.md` - Documentation updates
5. `.claude/commands/start-dev-server.md` - Command documentation
6. `.claude/commands/check-dev-server.md` - Command documentation

## Rollback Plan
If changes cause issues:
1. Revert to previous branch
2. Use simple `npm run dev` for direct usage
3. Disable coordination scripts temporarily