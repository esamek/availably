# Availably Color System Usage Guide

## Overview

The Availably color system provides WCAG AA compliant colors for visualizing attendee availability in timeline components. Both Green and Blue color schemes are fully accessible and ready for production use.

## Quick Start

```typescript
import { getAttendeeColor, BLUE_SCHEME, GREEN_SCHEME } from './colorSystem'

// Get color for 3 attendees out of max 5
const colorResult = getAttendeeColor(3, 5, BLUE_SCHEME)

// Apply to your component
const styles = {
  backgroundColor: colorResult.backgroundColor,
  color: colorResult.textColor,
  border: `1px solid ${colorResult.borderColor}`
}
```

## API Reference

### Color Schemes

#### BLUE_SCHEME (Recommended)
Professional blue scale with excellent accessibility:
- **0 attendees**: `#f8f9fa` (neutral gray) with dark text
- **1 attendee**: `#e7f5ff` (very light blue) with dark text
- **2 attendees**: `#d0ebff` (light blue) with dark text
- **3 attendees**: `#339af0` (medium blue) with black text
- **4 attendees**: `#1864ab` (bright blue) with white text
- **5+ attendees**: `#0b4d7a` (deep blue) with white text

#### GREEN_SCHEME
Nature-inspired green scale with superior contrast:
- **0 attendees**: `#f8f9fa` (neutral gray) with dark text
- **1 attendee**: `#e7f5e7` (very light green) with dark text
- **2 attendees**: `#c3f0c3` (light green) with dark text
- **3 attendees**: `#51cf66` (medium green) with black text
- **4 attendees**: `#1b5930` (bright green) with white text
- **5+ attendees**: `#0d3018` (deep green) with white text

### Main Functions

#### `getAttendeeColor(attendeeCount, maxAttendees, scheme, isSelected)`

Returns color information for a given attendee count.

**Parameters:**
- `attendeeCount: number` - Number of attendees (0-5+)
- `maxAttendees: number` - Maximum attendees for scaling (default: 5)
- `scheme: ColorScheme` - Color scheme to use (default: BLUE_SCHEME)
- `isSelected: boolean` - Whether the slot is selected (default: false)

**Returns:** `ColorResult`
```typescript
{
  backgroundColor: string,
  textColor: string,
  borderColor: string,
  contrastRatio: number
}
```

**Example:**
```typescript
// Basic usage
const result = getAttendeeColor(2, 5)
// Returns: { backgroundColor: '#d0ebff', textColor: '#343a40', ... }

// With green scheme
const greenResult = getAttendeeColor(2, 5, GREEN_SCHEME)
// Returns: { backgroundColor: '#c3f0c3', textColor: '#343a40', ... }

// Selected state
const selectedResult = getAttendeeColor(2, 5, BLUE_SCHEME, true)
// Returns enhanced colors for selected state
```

#### `getOptimalAttendeeColor(attendeeCount, maxAttendees, isSelected)`

Automatically selects the best color scheme for optimal contrast.

**Example:**
```typescript
const optimal = getOptimalAttendeeColor(3, 5)
console.log(optimal.schemeName) // 'Blue' or 'Green'
```

#### `generateCSSStyles(colorResult)`

Converts ColorResult to React CSS properties object.

**Example:**
```typescript
const colorResult = getAttendeeColor(3, 5)
const styles = generateCSSStyles(colorResult)

// Use in React component
<div style={styles}>3 attendees available</div>
```

## Usage in Timeline Components

### Basic Timeline Block

```typescript
import { getAttendeeColor, BLUE_SCHEME } from './utils/colorSystem'

function TimelineBlock({ attendeeCount, maxAttendees, isSelected, onClick }) {
  const colorResult = getAttendeeColor(attendeeCount, maxAttendees, BLUE_SCHEME, isSelected)
  
  return (
    <div
      onClick={onClick}
      style={{
        backgroundColor: colorResult.backgroundColor,
        color: colorResult.textColor,
        border: `1px solid ${colorResult.borderColor}`,
        padding: '8px 12px',
        borderRadius: '4px',
        cursor: 'pointer',
        transition: 'all 0.2s ease'
      }}
    >
      <div>{timeLabel}</div>
      {attendeeCount > 0 && (
        <div style={{ fontSize: '12px', opacity: 0.8 }}>
          {attendeeCount} available
        </div>
      )}
    </div>
  )
}
```

### Enhanced Layout B Integration

```typescript
import { getAttendeeColor, GREEN_SCHEME } from '../utils/colorSystem'

function EnhancedTimelineLayout() {
  const getSlotColor = (dateTime: string, isSelected: boolean) => {
    const count = getSlotCount(dateTime)
    return getAttendeeColor(count, maxAttendees, GREEN_SCHEME, isSelected)
  }

  return (
    <div>
      {SAMPLE_EVENT.possibleTimes.map(time => {
        const dateTime = `${date.date}-${time}`
        const colorResult = getSlotColor(dateTime, selectedRanges[dateTime])
        
        return (
          <Box
            key={dateTime}
            onClick={() => handleBlockClick(dateTime)}
            style={{
              backgroundColor: colorResult.backgroundColor,
              color: colorResult.textColor,
              border: `1px solid ${colorResult.borderColor}`,
              // ... other styles
            }}
          >
            {/* content */}
          </Box>
        )
      })}
    </div>
  )
}
```

## Accessibility Features

### WCAG AA Compliance
- All color combinations meet 4.5:1 contrast ratio minimum
- Many combinations exceed 7:1 for AAA compliance
- Tested across multiple screen types and conditions

### Colorblind Support
```typescript
import { getAttendeeColorWithPattern, ACCESSIBILITY_PATTERNS } from './colorSystem'

// Enable patterns for colorblind users
const colorWithPattern = getAttendeeColorWithPattern(3, 5, BLUE_SCHEME, false, true)

// Apply pattern as background image
const styles = {
  backgroundColor: colorWithPattern.backgroundColor,
  backgroundImage: colorWithPattern.pattern,
  backgroundSize: '8px 8px'
}
```

### Available Patterns
- `dots`: Subtle dot pattern
- `stripes`: Diagonal stripe pattern  
- `grid`: Grid pattern
- `none`: No pattern (default)

## Testing & Validation

### Contrast Testing
```typescript
import { checkContrast, calculateContrastRatio } from './colorSystem'

const contrast = checkContrast('#339af0', '#000000')
console.log(contrast.ratio) // 7.02
console.log(contrast.wcagLevel) // 'AAA'
console.log(contrast.passesAA) // true
```

### Scheme Validation
```typescript
import { validateColorScheme, getRecommendedScheme } from './colorSystem'

const isValid = validateColorScheme(BLUE_SCHEME) // true
const recommended = getRecommendedScheme() // Returns best scheme
```

## Best Practices

### 1. Choose Appropriate Scheme
- **Blue**: Professional contexts, corporate applications
- **Green**: Nature/health themes, positive associations
- **Auto**: Use `getOptimalAttendeeColor()` for automatic selection

### 2. Handle Selected States
```typescript
// Always indicate selected state for better UX
const colorResult = getAttendeeColor(count, max, scheme, isSelected)
```

### 3. Responsive Design
```typescript
// Adjust max attendees based on screen size
const maxAttendees = isMobile ? 3 : 5
const colorResult = getAttendeeColor(count, maxAttendees)
```

### 4. Loading States
```typescript
// Use neutral color for loading
const loadingColor = getAttendeeColor(0, 5) // Always neutral gray
```

## Implementation Checklist

- [ ] Import color system utilities
- [ ] Choose appropriate color scheme (Blue/Green)  
- [ ] Implement `getAttendeeColor()` in timeline blocks
- [ ] Handle selected state styling
- [ ] Add hover/focus states for interactivity
- [ ] Test with screen readers and accessibility tools
- [ ] Verify contrast ratios in production
- [ ] Consider colorblind patterns if needed

## Migration from Hardcoded Colors

### Before:
```typescript
// Old hardcoded approach
backgroundColor: isSelected 
  ? '#51cf66' 
  : count > 0 
    ? `rgba(81, 207, 102, ${count * 0.4})` 
    : '#f8f9fa'
```

### After:
```typescript
// New accessible approach
const colorResult = getAttendeeColor(count, maxAttendees, GREEN_SCHEME, isSelected)
backgroundColor: colorResult.backgroundColor
color: colorResult.textColor
```

## Performance Notes

- Color calculations are lightweight (< 1ms)
- Colors are pure functions (safe to memoize)
- No external dependencies required
- TypeScript provides full type safety

## Support

The color system is fully self-contained and documented. All functions include TypeScript types and JSDoc comments for IDE support.