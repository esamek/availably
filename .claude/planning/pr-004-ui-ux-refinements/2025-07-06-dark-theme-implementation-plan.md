# Dark Theme Implementation Plan
**Date:** July 6, 2025  
**PR:** pr-004-ui-ux-refinements  
**Branch:** pr-004-ui-ux-refinements

## Overview
Implement dark theme support for the Availably scheduling webapp using Mantine's built-in dark theme system with automatic system preference detection.

## Current State Analysis
- **Theme Setup**: Basic `MantineProvider` with no custom theme configuration
- **Color Scheme**: No color scheme management currently implemented
- **Components**: Using default Mantine components that auto-support dark mode
- **Custom Styling**: Timeline component and other custom colors may need review

## Implementation Strategy

### Phase 1: Core Theme Infrastructure
**Goal**: Set up foundation for dark theme support

**Tasks**:
1. Create custom theme configuration with `createTheme()`
2. Configure `defaultColorScheme="auto"` for system preference detection
3. Add `ColorSchemeScript` to `index.html` for proper SSR support
4. Update `MantineProvider` in `main.tsx` with theme configuration

**Files to Modify**:
- `src/main.tsx` - Theme provider setup
- `index.html` - Add ColorSchemeScript
- `src/theme.ts` - New theme configuration file

### Phase 2: Theme Toggle Component
**Goal**: Provide user control over theme preference

**Tasks**:
1. Create `ThemeToggle` component with moon/sun icons
2. Implement toggle logic using `useMantineColorScheme` hook
3. Use `useComputedColorScheme` for reliable light/dark detection
4. Add smooth transition animations
5. Integrate toggle into header navigation

**Files to Create**:
- `src/components/ui/ThemeToggle.tsx` - Theme toggle component

**Files to Modify**:
- `src/App.tsx` - Add theme toggle to header

### Phase 3: Component Review & Updates
**Goal**: Ensure all components work properly with dark theme

**Tasks**:
1. Review timeline component colors and heat mapping
2. Check form components and validation styles
3. Verify accessibility compliance (WCAG AA) in both themes
4. Test custom CSS variables and color usage
5. Update any hardcoded colors to theme-aware values

**Files to Review**:
- `src/components/availability/EnhancedTimelineLayout.tsx`
- `src/utils/colorSystem.ts`
- `src/pages/*.tsx`
- Custom CSS files

### Phase 4: Testing & Refinement
**Goal**: Ensure robust dark theme experience

**Tasks**:
1. Test theme switching across all pages
2. Verify system preference detection works
3. Check theme persistence across sessions
4. Test accessibility features in both themes
5. Validate responsive design in dark mode
6. Performance testing for theme transitions

## Technical Implementation Details

### Theme Configuration
```typescript
// src/theme.ts
import { createTheme } from '@mantine/core';

export const theme = createTheme({
  primaryColor: 'blue',
  // Additional customizations as needed
});
```

### Main Provider Setup
```typescript
// src/main.tsx
import { ColorSchemeScript, MantineProvider } from '@mantine/core';
import { theme } from './theme';

// Add ColorSchemeScript to index.html head
// Configure MantineProvider with theme and defaultColorScheme="auto"
```

### Theme Toggle Component
```typescript
// src/components/ui/ThemeToggle.tsx
import { useComputedColorScheme, useMantineColorScheme } from '@mantine/core';

// Implement toggle with moon/sun icons
// Use computedColorScheme for reliable toggling
```

## Expected Benefits
1. **User Experience**: Matches system preferences automatically
2. **Accessibility**: Reduces eye strain in low-light conditions
3. **Modern UX**: Follows current design trends
4. **Mantine Integration**: Leverages built-in dark theme support
5. **Minimal Custom Code**: Most components auto-adapt

## Potential Challenges
1. **Custom Colors**: Timeline heat mapping may need color adjustments
2. **Accessibility**: Ensuring contrast ratios remain WCAG AA compliant
3. **Testing**: Comprehensive testing across all components and states
4. **Performance**: Smooth theme transitions without flicker

## Success Criteria
- [ ] Theme toggle works smoothly with visual feedback
- [ ] System preference detection functions correctly
- [ ] All existing components display properly in dark mode
- [ ] Timeline component maintains readability and heat mapping
- [ ] Accessibility standards maintained (WCAG AA)
- [ ] Theme preference persists across sessions
- [ ] No performance degradation from theme switching
- [ ] Mobile experience remains optimal in both themes

## Timeline
- **Phase 1**: 30 minutes - Core infrastructure
- **Phase 2**: 45 minutes - Theme toggle component
- **Phase 3**: 60 minutes - Component review and updates
- **Phase 4**: 30 minutes - Testing and refinement

**Total Estimated Time**: 2.5 hours

## Notes
- Mantine provides excellent built-in dark theme support
- Most existing components should work without modification
- Focus on timeline component as it has custom styling
- Maintain existing accessibility features (colorblind patterns, etc.)
- Consider adding theme preview in settings if needed later