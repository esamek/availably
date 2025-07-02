/**
 * Accessible Color System for Availably Timeline Component
 * 
 * This module provides WCAG AA compliant color scales for visualizing attendee counts
 * in the timeline component. Includes both green and blue color schemes with 
 * accessibility features like contrast checking and colorblind-friendly fallbacks.
 */

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

export interface ColorScheme {
  name: string
  description: string
  baseColor: string
  scale: string[]
  textColors: string[]
  patterns?: string[]
}

export interface ColorResult {
  backgroundColor: string
  textColor: string
  borderColor?: string
  pattern?: string
  contrastRatio: number
}

export interface ContrastResult {
  ratio: number
  passesAA: boolean
  passesAAA: boolean
  wcagLevel: 'AA' | 'AAA' | 'FAIL'
}

// ============================================================================
// COLOR SCALES - WCAG AA COMPLIANT
// ============================================================================

/**
 * Green Color Scheme - Optimized for accessibility
 * Uses a 6-step scale from neutral to fully saturated, WCAG AA compliant
 */
export const GREEN_SCHEME: ColorScheme = {
  name: 'Green',
  description: 'Nature-inspired green scale with excellent readability',
  baseColor: '#51cf66',
  scale: [
    '#ffffff', // 0 attendees - pure white
    '#e7f5e7', // 1 attendee - very light green
    '#c3f0c3', // 2 attendees - light green
    '#51cf66', // 3 attendees - medium green (keep original)
    '#1b5930', // 4 attendees - bright green (darker)
    '#0d3018'  // 5+ attendees - deep green (darkest)
  ],
  textColors: [
    '#343a40', // Dark text for light backgrounds (0-2 attendees)
    '#343a40', 
    '#343a40',
    '#000000', // Black text for medium colors (better contrast)
    '#ffffff', // White text for darker backgrounds
    '#ffffff'
  ]
}

/**
 * Blue Color Scheme - Professional and accessible
 * Uses a 6-step scale optimized for various screen types, WCAG AA compliant
 */
export const BLUE_SCHEME: ColorScheme = {
  name: 'Blue',
  description: 'Professional blue scale with superior contrast',
  baseColor: '#339af0',
  scale: [
    '#ffffff', // 0 attendees - pure white
    '#e7f5ff', // 1 attendee - very light blue
    '#d0ebff', // 2 attendees - light blue
    '#339af0', // 3 attendees - medium blue (keep original)
    '#1864ab', // 4 attendees - bright blue (darker)
    '#0b4d7a'  // 5+ attendees - deep blue (darkest)
  ],
  textColors: [
    '#343a40', // Dark text for light backgrounds (0-2 attendees)
    '#343a40',
    '#343a40', 
    '#000000', // Black text for medium colors (better contrast)
    '#ffffff', // White text for darker backgrounds
    '#ffffff'
  ]
}

// ============================================================================
// CONTRAST CALCULATION UTILITIES
// ============================================================================

/**
 * Convert hex color to RGB values
 */
function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : null
}

/**
 * Calculate relative luminance of a color
 * Based on WCAG 2.1 guidelines
 */
function getLuminance(r: number, g: number, b: number): number {
  const [rs, gs, bs] = [r, g, b].map(c => {
    c = c / 255
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
  })
  return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs
}

/**
 * Calculate contrast ratio between two colors
 * Returns ratio from 1 (no contrast) to 21 (maximum contrast)
 */
export function calculateContrastRatio(color1: string, color2: string): number {
  const rgb1 = hexToRgb(color1)
  const rgb2 = hexToRgb(color2)
  
  if (!rgb1 || !rgb2) return 1
  
  const lum1 = getLuminance(rgb1.r, rgb1.g, rgb1.b)
  const lum2 = getLuminance(rgb2.r, rgb2.g, rgb2.b)
  
  const brightest = Math.max(lum1, lum2)
  const darkest = Math.min(lum1, lum2)
  
  return (brightest + 0.05) / (darkest + 0.05)
}

/**
 * Check if color combination meets WCAG standards
 */
export function checkContrast(backgroundColor: string, textColor: string): ContrastResult {
  const ratio = calculateContrastRatio(backgroundColor, textColor)
  const passesAA = ratio >= 4.5
  const passesAAA = ratio >= 7.0
  
  return {
    ratio: Math.round(ratio * 100) / 100,
    passesAA,
    passesAAA,
    wcagLevel: passesAAA ? 'AAA' : passesAA ? 'AA' : 'FAIL'
  }
}

// ============================================================================
// MAIN COLOR FUNCTIONS
// ============================================================================

/**
 * Get appropriate color for attendee count using specified scheme
 * 
 * @param attendeeCount - Number of attendees (0-5+)
 * @param maxAttendees - Maximum number of attendees for scaling
 * @param scheme - Color scheme to use (GREEN_SCHEME or BLUE_SCHEME)
 * @param isSelected - Whether the time slot is selected by current user
 * @returns ColorResult with background, text colors and accessibility info
 */
export function getAttendeeColor(
  attendeeCount: number,
  maxAttendees: number = 5,
  scheme: ColorScheme = BLUE_SCHEME,
  isSelected: boolean = false
): ColorResult {
  // Handle selected state with increased saturation
  if (isSelected) {
    const selectedIndex = Math.min(scheme.scale.length - 1, Math.max(2, Math.ceil(attendeeCount / maxAttendees * (scheme.scale.length - 1))))
    const backgroundColor = scheme.scale[selectedIndex]
    const textColor = scheme.textColors[selectedIndex]
    
    return {
      backgroundColor,
      textColor,
      borderColor: '#495057',
      contrastRatio: calculateContrastRatio(backgroundColor, textColor)
    }
  }
  
  // Calculate color index based on attendee count
  const normalizedCount = Math.min(attendeeCount, maxAttendees)
  const colorIndex = normalizedCount === 0 ? 0 : Math.min(scheme.scale.length - 1, Math.ceil(normalizedCount / maxAttendees * (scheme.scale.length - 1)))
  
  const backgroundColor = scheme.scale[colorIndex]
  const textColor = scheme.textColors[colorIndex]
  
  return {
    backgroundColor,
    textColor,
    borderColor: '#dee2e6',
    contrastRatio: calculateContrastRatio(backgroundColor, textColor)
  }
}

/**
 * Get color for specific attendee count with automatic scheme selection
 * Automatically chooses the scheme with better contrast for the given scenario
 */
export function getOptimalAttendeeColor(
  attendeeCount: number,
  maxAttendees: number = 5,
  isSelected: boolean = false
): ColorResult & { schemeName: string } {
  const greenResult = getAttendeeColor(attendeeCount, maxAttendees, GREEN_SCHEME, isSelected)
  const blueResult = getAttendeeColor(attendeeCount, maxAttendees, BLUE_SCHEME, isSelected)
  
  // Choose scheme with better contrast ratio
  const optimalResult = greenResult.contrastRatio > blueResult.contrastRatio ? greenResult : blueResult
  const schemeName = greenResult.contrastRatio > blueResult.contrastRatio ? 'Green' : 'Blue'
  
  return {
    ...optimalResult,
    schemeName
  }
}

// ============================================================================
// COLORBLIND ACCESSIBILITY FEATURES
// ============================================================================

/**
 * Pattern indicators for colorblind accessibility
 * These can be used as CSS background patterns or border styles
 */
export const ACCESSIBILITY_PATTERNS = {
  none: 'none',
  dots: 'radial-gradient(circle at 2px 2px, rgba(0,0,0,0.15) 1px, transparent 0)',
  stripes: 'repeating-linear-gradient(45deg, transparent, transparent 2px, rgba(0,0,0,0.1) 2px, rgba(0,0,0,0.1) 4px)',
  grid: 'linear-gradient(rgba(0,0,0,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(0,0,0,0.1) 1px, transparent 1px)'
}

/**
 * Get color with pattern fallback for colorblind users
 */
export function getAttendeeColorWithPattern(
  attendeeCount: number,
  maxAttendees: number = 5,
  scheme: ColorScheme = BLUE_SCHEME,
  isSelected: boolean = false,
  usePatterns: boolean = false
): ColorResult {
  const result = getAttendeeColor(attendeeCount, maxAttendees, scheme, isSelected)
  
  if (usePatterns && attendeeCount > 0) {
    const patternIndex = Math.min(attendeeCount - 1, Object.keys(ACCESSIBILITY_PATTERNS).length - 2)
    const patterns = Object.values(ACCESSIBILITY_PATTERNS)
    result.pattern = patterns[patternIndex + 1] // Skip 'none' pattern
  }
  
  return result
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Generate CSS styles object from color result
 */
export function generateCSSStyles(colorResult: ColorResult): React.CSSProperties {
  const styles: React.CSSProperties = {
    backgroundColor: colorResult.backgroundColor,
    color: colorResult.textColor,
    borderColor: colorResult.borderColor || '#dee2e6'
  }
  
  if (colorResult.pattern) {
    styles.backgroundImage = colorResult.pattern
    styles.backgroundSize = '8px 8px'
  }
  
  return styles
}

/**
 * Validate all colors in a scheme meet WCAG AA standards
 */
export function validateColorScheme(scheme: ColorScheme): boolean {
  for (let i = 0; i < scheme.scale.length; i++) {
    const contrast = checkContrast(scheme.scale[i], scheme.textColors[i])
    if (!contrast.passesAA) {
      console.warn(`Color scheme ${scheme.name} fails WCAG AA at index ${i}: ${contrast.ratio.toFixed(2)}:1`)
      return false
    }
  }
  return true
}

/**
 * Get recommended scheme based on accessibility testing
 */
export function getRecommendedScheme(): ColorScheme {
  const greenValid = validateColorScheme(GREEN_SCHEME)
  const blueValid = validateColorScheme(BLUE_SCHEME)
  
  if (blueValid && greenValid) {
    // Both valid - return blue as it's more professional
    return BLUE_SCHEME
  } else if (blueValid) {
    return BLUE_SCHEME
  } else if (greenValid) {
    return GREEN_SCHEME
  } else {
    console.warn('Neither color scheme fully passes WCAG AA standards')
    return BLUE_SCHEME // Fallback
  }
}

// ============================================================================
// EXPORTS
// ============================================================================


export default {
  getAttendeeColor,
  getOptimalAttendeeColor,
  getAttendeeColorWithPattern,
  calculateContrastRatio,
  checkContrast,
  generateCSSStyles,
  validateColorScheme,
  getRecommendedScheme,
  GREEN_SCHEME,
  BLUE_SCHEME,
  ACCESSIBILITY_PATTERNS
}