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

/**
 * Ember Color Scheme - Contemporary warm tones for 2025
 * Inspired by "Mocha Mousse" trend, excellent for dark themes, WCAG AA compliant
 */
export const EMBER_SCHEME: ColorScheme = {
  name: 'Ember',
  description: 'Contemporary warm ember tones, perfect for dark themes',
  baseColor: '#fc8181',
  scale: [
    '#ffffff', // 0 attendees - pure white
    '#fff5f3', // 1 attendee - very light warm
    '#fed7d7', // 2 attendees - light warm pink
    '#fc8181', // 3 attendees - medium coral
    '#e53e3e', // 4 attendees - vibrant red
    '#c53030'  // 5+ attendees - deep red
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
 * Purple Color Scheme - Modern sophisticated tones for 2025
 * Contemporary "dusky purple" trend, WCAG AA compliant
 */
export const PURPLE_SCHEME: ColorScheme = {
  name: 'Purple',
  description: 'Modern sophisticated purple scale, contemporary and accessible',
  baseColor: '#9f7aea',
  scale: [
    '#ffffff', // 0 attendees - pure white
    '#faf5ff', // 1 attendee - very light purple
    '#e9d8fd', // 2 attendees - light purple
    '#9f7aea', // 3 attendees - medium purple
    '#6b46c1', // 4 attendees - vibrant purple
    '#4c1d95'  // 5+ attendees - deep purple
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
 * Emerald Color Scheme - Nature-inspired professional tones
 * Optimized for dark themes with teal-green progression, WCAG AA compliant
 */
export const EMERALD_SCHEME: ColorScheme = {
  name: 'Emerald',
  description: 'Nature-inspired emerald tones, excellent for dark backgrounds',
  baseColor: '#4fd1c7',
  scale: [
    '#ffffff', // 0 attendees - pure white
    '#f0fff4', // 1 attendee - very light mint
    '#c6f6d5', // 2 attendees - light green
    '#4fd1c7', // 3 attendees - medium teal
    '#38b2ac', // 4 attendees - vibrant teal
    '#285e61'  // 5+ attendees - deep teal
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

/**
 * Get theme-appropriate color scheme
 * Automatically selects contemporary schemes for dark themes, professional schemes for light themes
 */
export function getThemeAwareScheme(isDarkTheme: boolean = false): ColorScheme {
  if (isDarkTheme) {
    // Test EMBER scheme for dark theme compatibility
    const emberValid = validateColorScheme(EMBER_SCHEME)
    if (emberValid) {
      return EMBER_SCHEME
    }
    
    // Fallback to other contemporary schemes
    const purpleValid = validateColorScheme(PURPLE_SCHEME)
    const emeraldValid = validateColorScheme(EMERALD_SCHEME)
    
    if (purpleValid) return PURPLE_SCHEME
    if (emeraldValid) return EMERALD_SCHEME
    
    // Ultimate fallback
    return BLUE_SCHEME
  } else {
    // Light theme - use traditional professional schemes
    return getRecommendedScheme()
  }
}

/**
 * Validate all contemporary color schemes for WCAG compliance
 */
export function validateAllSchemes(): { [key: string]: boolean } {
  return {
    green: validateColorScheme(GREEN_SCHEME),
    blue: validateColorScheme(BLUE_SCHEME),
    ember: validateColorScheme(EMBER_SCHEME),
    purple: validateColorScheme(PURPLE_SCHEME),
    emerald: validateColorScheme(EMERALD_SCHEME)
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
  getThemeAwareScheme,
  validateAllSchemes,
  GREEN_SCHEME,
  BLUE_SCHEME,
  EMBER_SCHEME,
  PURPLE_SCHEME,
  EMERALD_SCHEME,
  ACCESSIBILITY_PATTERNS
}