# CLAUDE.md - Availably Development Guide

This file provides guidance to Claude Code when working on the Availably group scheduling webapp.

## Core Development Principles

### Always Demo-Ready Development
- Every development phase must produce a working, demonstrable application
- Code should always be testable and interactive, even with incomplete features
- Use mock data and placeholders to make features testable before full implementation
- Maintain "always deployable" state - app should build and run at any time

### Progressive Enhancement
- Start with basic functionality, then enhance with advanced features
- Each feature should work independently before integrating with others
- Use TypeScript for better development experience and fewer runtime errors
- Follow existing patterns and conventions established in the codebase

## Development Commands

### Running the Application
```bash
# RECOMMENDED: Check if dev server is already running (prevents conflicts)
./scripts/check-dev-server.sh

# RECOMMENDED: Start development server safely (auto-detects conflicts)
./scripts/start-dev-server.sh

# ALTERNATIVE: Start development server directly (now reliable with node command)
npm run dev
# Opens at http://localhost:5173/

# Build for production (test before major commits)
npm run build

# Preview production build
npm run preview

# Run linting (fix issues before committing)
npm run lint
```

### Development Server Management
**IMPORTANT**: The development server runs in the foreground and will cause `npm run dev` to timeout in tool environments. Use these helper scripts to avoid conflicts:

- `./scripts/check-dev-server.sh` - Check if server is running/stuck
- `./scripts/start-dev-server.sh` - Start server safely (auto-detects conflicts)

**Claude Commands**: These are also available as documented commands:
- See `.claude/commands/check-dev-server.md` for detailed usage
- See `.claude/commands/start-dev-server.md` for detailed usage

**For Agents**: Always use `./scripts/check-dev-server.sh` before attempting to start the server to prevent timeout issues. Note: npm run dev now uses the reliable node command internally.

### Testing Workflow
Always test changes using these steps:
1. Run `./scripts/check-dev-server.sh` to verify server status
2. If server not running, start with `./scripts/start-dev-server.sh`
3. Navigate to `/event/sample` to test timeline component
4. Test responsive design by resizing browser window (320px, 375px, 768px)
5. Test mobile touch interactions (drag selection, real-time feedback)
6. Test accessibility features (colorblind patterns, screen reader)
7. Check browser console for any errors
8. Verify TypeScript compilation with `npm run build`

### Agent-Based Development Approach
This project successfully uses multi-agent development for complex features:
- **Agent 1**: UI Polish & Layout
- **Agent 2**: Algorithm Development (Best Times, Time Ranges)
- **Agent 3**: Real-time Features (Selection Feedback)
- **Agent 4**: Interaction Enhancement (Drag, Submit Logic)

This approach allows parallel development of complex features while maintaining code quality.

## Current Development Status

### Phase 1: Foundation (✅ COMPLETED)
- [x] Home page loads with proper styling and navigation
- [x] All routes work (/, /create, /event/:id, /about)
- [x] Header navigation functions correctly
- [x] Responsive design works on mobile and desktop
- [x] No TypeScript or console errors

### Phase 2: Event Creation (✅ COMPLETED)
- [x] Create form accepts event name and basic details
- [x] Date/time selection interface works
- [x] Form validation provides helpful feedback
- [x] Successfully creates mock event and redirects
- [x] Event URL generation works

### Phase 3: Event Response (✅ COMPLETED)
- [x] Event display shows all relevant details
- [x] Enhanced timeline component with heat mapping
- [x] Participant can add their name and availability
- [x] Real-time selection feedback with immediate updates
- [x] Smart Best Times algorithm with time ranges

### Phase 5: Enhanced Timeline Component (✅ COMPLETED)
- [x] Time squares display proper time labels
- [x] Heat mapping shows varied colors based on attendee count
- [x] Mobile-first layout with proper touch targets (48px)
- [x] Full day (24-hour) selection capability
- [x] WCAG AA accessibility compliance
- [x] Colorblind-friendly pattern toggle

### Phase 6: User Experience Refinements (✅ COMPLETED)
- [x] Removed unnecessary "INTERACTIVE" labels
- [x] Pure white background for empty slots
- [x] Accessibility icon with tooltip
- [x] Best Times shows time ranges above Current Responses
- [x] Real-time selection feedback with count updates
- [x] Drag-to-deselect functionality
- [x] Smart submit button activation

### Phase 4: Integration & Polish (🔄 IN PROGRESS)
- [ ] Database persistence functions correctly
- [ ] Production deployment setup
- [ ] End-to-end flow optimization
- [ ] Performance monitoring and optimization

## Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── availability/    # Timeline and scheduling components
│   │   ├── EnhancedTimelineLayout.tsx  # Main timeline component
│   │   ├── LayoutComparison.tsx        # Layout testing component
│   │   └── TimelineComparison.tsx      # Timeline comparison views
│   ├── layout/         # Layout components
│   │   └── Header.tsx  # Navigation header
│   └── ui/            # Generic UI components
├── pages/              # Route-level page components
│   ├── Home.tsx        # Landing page with app intro
│   ├── Create.tsx      # Event creation form
│   ├── Event.tsx       # Event response/viewing page
│   └── About.tsx       # Information about the app
├── types/              # TypeScript type definitions
│   └── event.ts        # Event and time range types
├── utils/              # Helper functions and utilities
│   ├── colorSystem.ts  # WCAG-compliant color utilities
│   └── timeRangeAnalysis.ts  # Best times algorithm
└── App.tsx             # Main app component with routing
```

## Architecture Guidelines

### Component Design
- Use Mantine UI components consistently
- Follow TypeScript best practices with proper typing
- Keep components focused and single-purpose
- Use React hooks appropriately (useState, useEffect, etc.)

### State Management
- Use React Context for global application state
- Local component state for UI-only concerns
- Consider optimistic updates for better user experience
- Plan for real-time data synchronization

### Data Flow
- Event creation → Generate unique ID → Store in database
- Event response → Update participant data → Broadcast changes
- Use proper error handling and loading states
- Implement offline-capable design where possible

## Current Tech Stack

### Frontend
- **React 19** with **TypeScript** for type safety
- **Vite** for fast development and building
- **Mantine UI** for consistent, accessible components
- **React Router** for client-side routing
- **Tabler Icons** for accessibility and UI icons
- **Framer Motion** for smooth animations
- **Day.js** for date/time manipulation

### Development Tools
- **ESLint** for code quality
- **TypeScript** compiler for type checking
- **Vite dev server** with hot module replacement

### Key Features Implemented
- **Enhanced Timeline Component**: Drag selection, heat mapping, real-time feedback
- **Mobile-First Design**: 48px touch targets, responsive grid system
- **Accessibility**: WCAG AA compliance, colorblind patterns, screen reader support
- **Smart Algorithms**: Best times analysis, time range grouping
- **Real-time Updates**: Immediate visual feedback for user selections

## Testing Strategy

### Manual Testing
- Always test in development server before marking features complete
- Test responsive design using browser dev tools
- Verify all navigation and user flows work
- Check for accessibility issues

### Demo Preparation
1. **Prepare sample data** for realistic testing
2. **Document user flows** for stakeholder demos
3. **Test edge cases** like empty states and errors
4. **Verify mobile experience** on actual devices when possible

## Future Enhancements
- Database integration (Supabase PostgreSQL)
- Real-time updates (Server-Sent Events or WebSockets)
- Production deployment (Vercel)
- Natural language availability input
- Calendar integrations

## Development Notes
- Keep the app simple and fast
- Prioritize user experience over complex features
- Maintain zero-login requirement
- Focus on mobile-first responsive design
- Ensure privacy and data minimization
- Use multi-agent development for complex features
- Always maintain demo-ready state
- Test extensively on mobile devices (320px+ widths)
- Implement WCAG AA accessibility standards
- Use TypeScript for type safety and better DX

## Planning Document Strategy

### Planning Document Location
All planning documents are stored in `.claude/planning/` directory for better organization and integration with Claude Code workflows.

### Document Organization Structure
```
.claude/
└── planning/
    ├── initial-planning/              # Pre-git planning documents
    │   ├── 2025-07-02-app-requirements.md
    │   ├── 2025-07-02-implementation-plan.md
    │   ├── 2025-07-02-ui-feedback-session.md
    │   └── 2025-07-02-ui-improvements-plan.md
    ├── pr-001-[branch-name]/          # PR-specific planning (sorted chronologically)
    │   └── YYYY-MM-DD-[meaningful-description].md
    ├── pr-002-[branch-name]/          # Next PR planning
    │   └── YYYY-MM-DD-[meaningful-description].md
    └── main/                          # Main branch planning
        └── YYYY-MM-DD-[meaningful-description].md
```

### Naming Convention
Planning documents should follow this format:
- **Date**: `YYYY-MM-DD` (ISO format for proper sorting)
- **Description**: Short, meaningful description of the planning session
- **Example**: `2025-07-02-database-integration-plan.md`

### Guidelines for Future Agents
When creating planning documents:
1. **For new work**: Always place them in `.claude/planning/pr-XXX-[branch-name]/`
   - Use PR number format: `pr-001-`, `pr-002-`, etc. (with leading zeros)
   - Include the original branch name after the PR number
   - This organizes folders chronologically while preserving context
2. Use the current date and a meaningful description for document names
3. Keep descriptions concise but descriptive (3-5 words)
4. Focus on what the plan addresses, not generic terms
5. Examples of good folder names:
   - `pr-001-update-claude-docs/`
   - `pr-002-debug-dev-server-timeout/`
   - `pr-003-fix-dev-server-startup/`
6. Examples of good document names:
   - `2025-07-03-auth-implementation-plan.md`
   - `2025-07-03-mobile-responsive-fixes.md`
   - `2025-07-03-performance-optimization-strategy.md`

## Common Commands Reference
```bash
# Quick development cycle (RECOMMENDED)
./scripts/check-dev-server.sh    # Check server status
./scripts/start-dev-server.sh    # Start development safely
npm run lint            # Check code quality
npm run build           # Test production build

# Alternative development (may timeout)
npm run dev              # Start development directly

# Debugging
npm run preview         # Test production build locally
npx tsc --noEmit        # Type check without building
```

Remember: Every change should result in a working, demonstrable application that can be tested and reviewed.