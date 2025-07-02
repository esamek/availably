# App Requirements: Availably

## Vision Statement
A frictionless group scheduling app that makes it extremely simple to find dates when groups can meet, without requiring user accounts or complex interfaces.

## Core Problem
Coordinating schedules for group events (virtual or in-person) is unnecessarily complicated with existing tools that require logins, have complex UIs, or make it difficult to quickly see mutual availability.

## Target Audience
- Event organizers (social, professional, family)
- Teams coordinating meetings
- Friends planning gatherings
- Anyone who needs to schedule group activities

## Platform
**Web Application** - Cross-platform compatibility via browser

## Core Features

### 1. Event Creation
- Event name (required)
- Specific dates and time slots to choose from
- Optional: Event description, location, duration
- Creator can optionally add their availability during creation
- Generates shareable link immediately

### 2. No-Login Experience
- Anyone can create an event without registration
- Participants respond via shared link only
- No account creation required
- Simple name/identifier for each response

### 3. Availability Management
- Event creator adds availability via same link they share
- Participants add availability when visiting link
- Visual interface for selecting available time slots
- Real-time updates as responses come in

### 4. Shared Visibility
- All participants can see each other's availability
- Clear visualization of overlapping free times
- Anonymous or named participation (participant choice)
- **Important**: Each user can only edit their own availability responses

### 5. Data Integrity
- Participants can only modify their own availability entries
- Event creator cannot edit others' responses
- Responses are tied to participant names/identifiers

## Detailed User Flow

### Event Creator Journey
1. Visit webapp → "Create Event"
2. Enter event name (required)
3. Define possible dates and time slots
4. Optional: Add own availability immediately
5. Get shareable link
6. Send link to participants
7. Can add/edit own availability via same link
8. View all responses and pick final time

### Participant Journey
1. Receive and click shared link
2. View event details and possible times
3. See other participants' availability (if any entered)
4. Enter own name/identifier
5. Select available time slots
6. Submit availability
7. Can return to link to view updates or modify response

## Recommended Tech Stack

### Frontend
- **Framework**: React with Vite (fast development, modern tooling)
- **UI Components**: Mantine or Chakra UI (comprehensive, accessible, ready-to-use components)
- **Styling**: Built-in component styling + custom CSS modules
- **State Management**: React Context + useState/useReducer (simple, no external deps)
- **HTTP Client**: Fetch API or Axios

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js (lightweight, familiar)
- **Real-time**: Server-Sent Events (simpler than WebSockets for this use case)
- **Validation**: Zod or Joi for request validation

### Database & Hosting
- **Database**: Supabase PostgreSQL (low-effort, real-time features, generous free tier)
- **Frontend Hosting**: Vercel (seamless deployment, great DX)
- **Backend Hosting**: Railway or Render (simple Node.js deployment)
- **Alternative**: Full-stack on Vercel with Vercel Postgres

### Development Tools
- **Package Manager**: npm or pnpm
- **Code Quality**: ESLint + Prettier
- **TypeScript**: Optional but recommended for better DX

### Architecture Benefits
- Minimal setup and configuration
- Excellent free tiers for prototyping
- Real-time capabilities built-in
- Scales easily if needed
- Modern development experience

## Application Sitemap

```
Availably Webapp
├── / (Home/Landing)
│   ├── Hero section explaining the app
│   ├── "Create New Event" CTA button
│   └── Simple feature highlights
│
├── /create
│   ├── Event creation form
│   │   ├── Event name (required)
│   │   ├── Date selection interface
│   │   ├── Time slot definition
│   │   └── Optional: description, location
│   ├── Optional: Add creator availability
│   └── Generate shareable link
│
├── /event/[eventId]
│   ├── Event details display
│   ├── Participant availability grid/calendar
│   ├── Add/edit own availability interface
│   │   ├── Name/identifier input (if not set)
│   │   └── Time slot selection
│   ├── Real-time updates of all responses
│   └── Summary of best meeting times
│
└── /about (optional)
    ├── How it works
    ├── Privacy policy
    └── Simple help/FAQ
```

### Key Pages Detail

1. **Home (/)**: Landing page with clear value proposition and create event CTA
2. **Create Event (/create)**: Form to set up new event with dates/times
3. **Event Response (/event/[eventId])**: Main interaction page where all participants add availability and view results
4. **About (/about)**: Simple informational page (optional for MVP)

## Technical Requirements

### Performance
- Fast loading (< 2 seconds)
- Real-time updates as people respond
- Works on mobile and desktop
- Minimal data usage

### Accessibility
- Screen reader compatible
- Keyboard navigation
- High contrast options
- Clear visual hierarchy

### Data Privacy
- Minimal data collection
- No persistent user tracking
- Events auto-expire after completion
- Clear data retention policy

## Success Metrics
- Time to create event < 30 seconds
- Time for participant to respond < 60 seconds
- Mobile usage > 60%
- Event completion rate > 80%

## Nice-to-Have Features (Future)
- Calendar integration (Google, Outlook)
- Email notifications
- Multiple time zone display
- Recurring event templates
- Anonymous participation option
- Simple voting on proposed times

## Future Requirements (Not for Initial Implementation)

### Natural Language Availability Input
**Goal**: Allow users to input availability using natural language instead of clicking time slots.

**Examples of Natural Language Input**:
- "I'm free weekday mornings and Thursday evening"
- "Available Monday through Wednesday after 2pm"
- "Free all day Saturday and Sunday morning"
- "Mornings work best, but not before 9am"
- "Any time except Tuesday afternoon"

**Implementation Considerations**:
- Natural Language Processing (NLP) for time/date parsing
- Fallback to visual interface for unclear inputs
- Confirmation step showing parsed availability
- Integration with existing time slot system
- Support for relative dates ("next week", "this weekend")

**Benefits**:
- Faster input for users with consistent schedules
- More intuitive for mobile users
- Reduces cognitive load of calendar navigation
- Appeals to users who prefer text-based interaction

**Technical Requirements**:
- Date/time parsing library (chrono-node, date-fns, etc.)
- Pattern matching for common availability phrases
- Timezone-aware parsing
- Error handling and user feedback for ambiguous input

## Technical Considerations
- Progressive Web App (PWA) for mobile experience
- Real-time synchronization (WebSockets or Server-Sent Events)
- Responsive design
- Cross-browser compatibility
- Offline capability for viewing existing responses

## Competitive Advantage
- Zero friction: no logins, simple UI
- Speed: optimized for quick interactions
- Mobile-first design
- Privacy-focused approach