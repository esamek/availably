# Availably - Group Scheduling Made Simple

> **⚠️ Work in Progress** - This is an active development project showcasing modern React development practices and user experience design.

A modern, mobile-first group scheduling webapp that makes finding the perfect meeting time effortless. Built with React 19, TypeScript, and Mantine UI.

## 🌟 Features

### ✅ Currently Implemented
- **Enhanced Timeline Component** with drag-and-drop time selection
- **Real-time Heat Mapping** showing availability overlap with color intensity
- **Mobile-First Design** with 48px touch targets and responsive layouts
- **Smart Best Times Algorithm** that groups consecutive time slots into readable ranges
- **Real-time Selection Feedback** with immediate visual updates
- **Accessibility Features** including WCAG AA compliance and colorblind-friendly patterns
- **Drag-to-Deselect** functionality for intuitive time slot management

### 🚧 In Development
- Database integration with Supabase
- Real-time synchronization between participants
- Production deployment pipeline
- Natural language availability input
- Calendar integrations

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ and npm

### Installation
```bash
# Clone the repository
git clone <repo-url>
cd availably

# Install dependencies
npm install

# Start development server
npm run dev
```

Visit `http://localhost:5173` to see the app, or go directly to `http://localhost:5173/event/sample` to see the enhanced timeline component in action.

## 🛠 Tech Stack

### Core Technologies
- **React 19** with **TypeScript** for type-safe component development
- **Vite** for lightning-fast development and building
- **Mantine UI** for consistent, accessible components
- **React Router** for client-side routing

### Enhanced Features
- **Tabler Icons** for accessibility and UI iconography  
- **Framer Motion** for smooth animations
- **Day.js** for robust date/time manipulation
- **Custom Color System** with WCAG AA compliance

## 📱 Mobile Experience

Availably is designed mobile-first with:
- **Responsive breakpoints**: 320px, 375px, 414px, 768px+
- **Touch-optimized interactions**: 48px minimum touch targets
- **Drag selection**: Works smoothly on both desktop and mobile
- **Real-time feedback**: Immediate visual response to user actions

## 🎨 User Experience Highlights

### Timeline Component
- **Heat Mapping**: Visual intensity shows where most people are available
- **Drag Selection**: Click and drag to select multiple time slots
- **Real-time Updates**: See changes immediately as you make selections
- **Smart Submit**: Button activates only when ready to submit

### Best Times Algorithm
- **Time Range Grouping**: Shows "Monday: 9:00-11:30 AM (4 people)" instead of individual slots
- **Multiple Ranges**: Supports multiple optimal time ranges per day
- **Dynamic Thresholds**: Automatically determines what constitutes "optimal" times

### Accessibility
- **WCAG AA Compliant**: All color combinations meet contrast requirements
- **Colorblind Support**: Toggle patterns for enhanced visual distinction
- **Screen Reader Friendly**: Proper ARIA labels and semantic markup
- **Keyboard Navigation**: Full functionality without mouse/touch

## 🧪 Testing

### Manual Testing Workflow
```bash
# Run the comprehensive test command
npm run test

# Or run individual commands
npm run lint     # Code quality check
npm run build    # Production build test
npm run dev      # Start development server
```

### Test the Timeline Component
1. Navigate to `/event/sample`  
2. Test drag selection across different time slots
3. Verify heat mapping shows different colors for different attendee counts
4. Test mobile responsiveness by resizing browser window
5. Try the colorblind accessibility toggle
6. Test real-time selection feedback

### Mobile Testing Checklist
- [ ] All interactions work with finger/thumb on 320px+ screens
- [ ] Text is readable without zooming
- [ ] Drag selection works smoothly on touch devices
- [ ] Submit button provides clear guidance
- [ ] Heat mapping colors are distinguishable on mobile

## 🏗 Architecture

### Component Structure
```
src/components/availability/
├── EnhancedTimelineLayout.tsx    # Main timeline component
├── LayoutComparison.tsx          # Development testing component
└── TimelineComparison.tsx        # Layout comparison views
```

### Utilities & Types
```
src/utils/
├── colorSystem.ts               # WCAG-compliant color utilities
└── timeRangeAnalysis.ts         # Best times algorithm

src/types/
└── event.ts                     # TypeScript type definitions
```

### Development Approach
This project uses a multi-agent development methodology for complex features:
- **Agent-based development** for parallel feature implementation
- **Always demo-ready** - every commit maintains working functionality
- **Mobile-first** responsive design principles
- **Accessibility-first** with WCAG AA compliance from the start

## 📋 Available Scripts

```bash
npm run dev       # Start development server
npm run build     # Build for production
npm run lint      # Run ESLint
npm run preview   # Preview production build
npm run test      # Comprehensive testing workflow
```

## 🎯 Project Goals

1. **Zero-login experience** - No user accounts required
2. **Mobile-first design** - Optimized for smartphones and tablets  
3. **Accessibility** - WCAG AA compliant for inclusive design
4. **Performance** - Sub-2 second load times, smooth interactions
5. **Privacy** - Minimal data collection, privacy by design

## 🤝 Contributing

This is currently a work-in-progress project. The codebase demonstrates:
- Modern React development patterns
- TypeScript best practices
- Mobile-first responsive design
- Accessibility-focused development
- Multi-agent development workflows

## 📝 License

This project is currently in development. License to be determined.

---

**Note**: This is an active development project showcasing modern web development practices. Features and functionality are continuously being enhanced and expanded.