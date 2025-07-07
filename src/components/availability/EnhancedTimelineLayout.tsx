import React, { useState, useCallback, useRef, useEffect } from 'react'
import { Box, Text, Card, Stack, Group, Badge, ActionIcon, Tooltip, useComputedColorScheme } from '@mantine/core'
import { IconAccessible } from '@tabler/icons-react'
import { 
  getAttendeeColor, 
  getAttendeeColorWithPattern, 
  checkContrast, 
  BLUE_SCHEME,
  getThemeAwareScheme,
  validateAllSchemes,
  validateColorScheme,
  type ColorResult,
  type ColorScheme
} from '../../utils/colorSystem'

interface EventResponse {
  name: string
  availability: string[]
}

interface EventData {
  name: string
  description?: string
  possibleDates: Array<{ date: string; label: string }>
  possibleTimes: string[]
  responses: EventResponse[]
}

interface EnhancedTimelineLayoutProps {
  eventData: EventData
  onSelectionChange?: (selectedSlots: string[]) => void
  disabled?: boolean
  colorblindFriendly?: boolean
  selectedSlots?: string[] // Add selectedSlots prop for real-time preview
}

// Generate full day hours with 30-minute increments for better mobile display
const generateFullDayHours = (): string[] => {
  const hours: string[] = []
  for (let hour = 8; hour <= 20; hour++) {
    for (let minute = 0; minute < 60; minute += 30) {
      const period = hour >= 12 ? 'PM' : 'AM'
      const displayHour = hour > 12 ? hour - 12 : hour === 0 ? 12 : hour
      const timeString = `${displayHour}:${minute.toString().padStart(2, '0')} ${period}`
      hours.push(timeString)
    }
  }
  return hours
}

const FULL_DAY_HOURS = generateFullDayHours()

// Check if a time slot is within the event's possible scope
const isTimeInEventScope = (time: string, eventTimes: string[]): boolean => {
  return eventTimes.includes(time)
}

// Removed getAvailabilityCount - using getAvailabilityCountWithPreview instead

// Get availability count including user's current preview selections
const getAvailabilityCountWithPreview = (
  dateTime: string, 
  responses: EventResponse[], 
  previewSelections: string[] = [],
  isSelected: boolean = false
): { count: number; includesUser: boolean } => {
  const baseCount = responses.filter(response => response.availability.includes(dateTime)).length
  const includesUser = previewSelections.includes(dateTime) || isSelected
  const totalCount = includesUser ? baseCount + 1 : baseCount
  return { count: totalCount, includesUser }
}

// Memoized color cache for performance optimization
const colorCache = new Map<string, ColorResult & { disabled: boolean }>()

// Get comprehensive color information using the colorSystem utilities
const getTimeSlotColors = (count: number, maxCount: number, disabled: boolean, isSelected: boolean, usePatterns: boolean = false, colorScheme: ColorScheme = BLUE_SCHEME): ColorResult & { disabled: boolean } => {
  // Create cache key for memoization including scheme name
  const cacheKey = `${count}-${maxCount}-${disabled}-${isSelected}-${usePatterns}-${colorScheme.name}`
  
  // Return cached result if available
  if (colorCache.has(cacheKey)) {
    return colorCache.get(cacheKey)!
  }
  
  let result: ColorResult & { disabled: boolean }
  
  if (disabled) {
    result = {
      backgroundColor: 'var(--mantine-color-gray-1)',
      textColor: 'var(--mantine-color-gray-6)',
      borderColor: 'var(--mantine-color-gray-4)',
      contrastRatio: 4.5, // Meets WCAG AA
      disabled: true
    }
  } else {
    // Use the colorSystem utility with pattern support for colorblind accessibility
    const colorResult = usePatterns 
      ? getAttendeeColorWithPattern(count, maxCount, colorScheme, isSelected, true)
      : getAttendeeColor(count, maxCount, colorScheme, isSelected)
    
    result = { ...colorResult, disabled: false }
  }
  
  // Cache the result for future use
  colorCache.set(cacheKey, result)
  return result
}

export const EnhancedTimelineLayout: React.FC<EnhancedTimelineLayoutProps> = ({
  eventData,
  onSelectionChange,
  disabled = false,
  colorblindFriendly = false,
  selectedSlots = [] // Use parent's selectedSlots for preview
}) => {
  // Use parent's selectedSlots directly instead of local state for real-time sync
  const [isDragging, setIsDragging] = useState(false)
  const [dragStart, setDragStart] = useState<string | null>(null)
  const [dragOperation, setDragOperation] = useState<'select' | 'deselect' | null>(null)
  const [isMobile, setIsMobile] = useState(false)
  const [, setAccessibilityWarnings] = useState<string[]>([])
  const [useColorblindMode, setUseColorblindMode] = useState(colorblindFriendly)
  const [visibleTimeCount, setVisibleTimeCount] = useState(12) // Show 12 times initially
  const containerRef = useRef<HTMLDivElement>(null)

  // Theme detection for color scheme selection
  const computedColorScheme = useComputedColorScheme('light', { getInitialValueInEffect: false })
  const isDarkTheme = computedColorScheme === 'dark'
  
  // Get theme-appropriate color scheme
  const currentColorScheme: ColorScheme = getThemeAwareScheme(isDarkTheme)

  const maxAttendees = eventData.responses.length + 1 // Include potential user in max count for color scaling

  // Validate color scheme accessibility on component mount and theme change
  useEffect(() => {
    // Validate all color schemes and log results
    const schemeValidation = validateAllSchemes()
    console.log('Color scheme validation results:', schemeValidation)
    
    const isCurrentSchemeValid = validateColorScheme(currentColorScheme)
    if (!isCurrentSchemeValid) {
      setAccessibilityWarnings(prev => [...prev, `${currentColorScheme.name} color scheme may not meet WCAG AA standards`])
    }
    
    // Test contrast ratios for various attendee counts with current scheme
    const warnings: string[] = []
    for (let i = 0; i <= maxAttendees; i++) {
      const colorInfo = getTimeSlotColors(i, maxAttendees, false, false, useColorblindMode, currentColorScheme)
      const contrast = checkContrast(colorInfo.backgroundColor, colorInfo.textColor)
      if (!contrast.passesAA) {
        warnings.push(`Low contrast for ${i} attendees: ${contrast.ratio.toFixed(1)}:1 (needs 4.5:1)`)
      }
    }
    
    if (warnings.length > 0) {
      setAccessibilityWarnings(warnings)
      console.warn(`Accessibility warnings for ${currentColorScheme.name} scheme:`, warnings)
    }
  }, [maxAttendees, currentColorScheme, useColorblindMode])

  // Handle responsive design with mobile-first breakpoints
  useEffect(() => {
    const checkMobile = () => {
      const width = window.innerWidth
      setIsMobile(width < 768) // Mobile-first: tablet and below
    }
    
    checkMobile()
    window.addEventListener('resize', checkMobile)
    window.addEventListener('orientationchange', checkMobile)
    
    return () => {
      window.removeEventListener('resize', checkMobile)
      window.removeEventListener('orientationchange', checkMobile)
    }
  }, [])

  // Removed handleSlotClick - functionality moved to handleMouseDown for unified drag/click behavior

  const handleMouseDown = useCallback((dateTime: string, isDisabled: boolean) => {
    if (disabled || isDisabled) return
    
    setIsDragging(true)
    setDragStart(dateTime)
    
    // Determine the drag operation based on initial slot state
    const wasSelected = selectedSlots.includes(dateTime)
    const operation = wasSelected ? 'deselect' : 'select'
    setDragOperation(operation)
    
    // Apply the operation to the first slot immediately
    const newSelection = operation === 'select'
      ? [...selectedSlots, dateTime]
      : selectedSlots.filter(slot => slot !== dateTime)
    
    onSelectionChange?.(newSelection)
  }, [disabled, selectedSlots, onSelectionChange])

  const handleMouseEnter = useCallback((dateTime: string, isDisabled: boolean) => {
    if (!isDragging || !dragStart || !dragOperation || disabled || isDisabled) return
    
    const isCurrentlySelected = selectedSlots.includes(dateTime)
    let newSelection: string[]
    
    if (dragOperation === 'select') {
      // Select mode: add slot if not already selected
      if (!isCurrentlySelected) {
        newSelection = [...selectedSlots, dateTime]
      } else {
        return // Already selected, no change needed
      }
    } else if (dragOperation === 'deselect') {
      // Deselect mode: remove slot if currently selected
      if (isCurrentlySelected) {
        newSelection = selectedSlots.filter(slot => slot !== dateTime)
      } else {
        return // Already deselected, no change needed
      }
    } else {
      return // No valid operation
    }
    
    onSelectionChange?.(newSelection)
  }, [isDragging, dragStart, dragOperation, disabled, selectedSlots, onSelectionChange])

  const handleMouseUp = useCallback(() => {
    setIsDragging(false)
    setDragStart(null)
    setDragOperation(null)
  }, [])

  const handleTouchStart = useCallback((dateTime: string, isDisabled: boolean) => {
    handleMouseDown(dateTime, isDisabled)
  }, [handleMouseDown])

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (!isDragging || !dragOperation) return
    
    e.preventDefault() // Prevent scrolling during drag
    
    const touch = e.touches[0]
    const element = document.elementFromPoint(touch.clientX, touch.clientY)
    const timeSlot = element?.getAttribute('data-datetime')
    const isDisabled = element?.getAttribute('data-disabled') === 'true'
    
    if (timeSlot && !isDisabled) {
      handleMouseEnter(timeSlot, false)
    }
  }, [isDragging, dragOperation, handleMouseEnter])

  return (
    <Card shadow="sm" padding={isMobile ? "md" : "lg"} radius="md" withBorder>
      <Stack gap={isMobile ? "sm" : "md"}>
        <Group justify="space-between" wrap={isMobile ? "wrap" : "nowrap"}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <Group gap="xs" align="center">
              <Text size={isMobile ? "md" : "lg"} fw={600} c="blue">Enhanced Timeline Layout</Text>
              <Badge size="xs" variant="light" color={isDarkTheme ? "red" : "blue"}>
                {currentColorScheme.name}
              </Badge>
            </Group>
            <Text size={isMobile ? "xs" : "sm"} c="dimmed" style={{ wordBreak: 'break-word' }}>
              {isMobile ? "Tap squares to toggle time slots" : "Click squares or drag to select/deselect multiple time slots"}
            </Text>
          </div>
          <Group gap="xs" style={{ flexShrink: 0 }}>
            <Tooltip label="Toggle patterns for colorblind accessibility">
              <ActionIcon
                size={isMobile ? "sm" : "md"}
                variant={useColorblindMode ? "filled" : "outline"}
                onClick={() => setUseColorblindMode(!useColorblindMode)}
                aria-label="Toggle patterns for colorblind accessibility"
              >
                <IconAccessible size={isMobile ? 16 : 18} />
              </ActionIcon>
            </Tooltip>
          </Group>
        </Group>

        <div
          ref={containerRef}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
          onTouchEnd={handleMouseUp}
          onTouchMove={handleTouchMove}
          style={{ 
            touchAction: 'none', // Prevent scrolling during drag
            // Mobile performance optimizations
            willChange: 'scroll-position',
            WebkitOverflowScrolling: 'touch'
          }}
        >
          {eventData.possibleDates.map(date => (
            <Box key={date.date} mb={isMobile ? "md" : "lg"}>
              <Group mb="sm" justify="space-between" wrap="nowrap">
                <Text fw={600} size={isMobile ? "sm" : "md"} style={{ 
                  overflow: 'hidden', 
                  textOverflow: 'ellipsis', 
                  whiteSpace: 'nowrap', 
                  flex: 1 
                }}>
                  📅 {date.label}
                </Text>
                <Badge size={isMobile ? "xs" : "sm"} variant="light" style={{ flexShrink: 0 }}>
                  {selectedSlots.filter(slot => slot.startsWith(date.date)).length} selected
                </Badge>
              </Group>
              
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: isMobile 
                    ? 'repeat(auto-fit, minmax(56px, 1fr))' // Optimized for mobile touch
                    : 'repeat(auto-fit, minmax(80px, 1fr))',
                  gap: isMobile ? '2px' : '3px', // Better spacing for touch
                  backgroundColor: 'var(--mantine-color-default-hover)',
                  padding: isMobile ? '4px' : '6px', // More padding for mobile
                  borderRadius: isMobile ? '6px' : '8px',
                  overflow: 'hidden',
                  maxWidth: '100%',
                  // Optimized for mobile performance
                  willChange: 'transform',
                  backfaceVisibility: 'hidden'
                }}
              >
                {FULL_DAY_HOURS.slice(0, visibleTimeCount).map(time => {
                  const dateTime = `${date.date}-${time}`
                  const isInScope = isTimeInEventScope(time, eventData.possibleTimes)
                  const isSelected = selectedSlots.includes(dateTime)
                  const isDisabled = !isInScope
                  
                  // Get count with real-time preview including user's selections
                  const { count: previewCount, includesUser } = getAvailabilityCountWithPreview(
                    dateTime, 
                    eventData.responses, 
                    selectedSlots, 
                    isSelected
                  )
                  
                  const colorInfo = getTimeSlotColors(previewCount, maxAttendees, isDisabled, isSelected, useColorblindMode, currentColorScheme)
                  const backgroundColor = colorInfo.backgroundColor
                  const textColor = colorInfo.textColor

                  const tooltipContent = previewCount > 0 
                    ? `${previewCount} people available${includesUser ? ' (including you)' : ''}`
                    : 'No one available for this time'

                  return (
                    <Tooltip
                      key={dateTime}
                      label={tooltipContent}
                      position="top"
                      withArrow
                      transitionProps={{ duration: 150 }}
                    >
                      <Box
                      data-datetime={dateTime}
                      data-disabled={isDisabled}
                      onMouseDown={() => handleMouseDown(dateTime, isDisabled)}
                      onMouseEnter={() => handleMouseEnter(dateTime, isDisabled)}
                      onTouchStart={(e) => {
                        if (!isDisabled && isMobile) {
                          const target = e.currentTarget as HTMLElement
                          const originalBg = target.style.backgroundColor
                          target.style.backgroundColor = '#2563eb' // Immediate visual feedback
                          setTimeout(() => {
                            target.style.backgroundColor = originalBg
                          }, 150)
                        }
                        handleTouchStart(dateTime, isDisabled)
                      }}
                      style={{
                        aspectRatio: '1',
                        backgroundColor,
                        backgroundImage: colorInfo.pattern || 'none',
                        backgroundSize: colorInfo.pattern ? '8px 8px' : 'auto',
                        cursor: isDisabled ? 'not-allowed' : 'pointer',
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'center',
                        position: 'relative',
                        userSelect: 'none',
                        WebkitUserSelect: 'none', // Better mobile support
                        WebkitTouchCallout: 'none', // Disable iOS callout
                        transition: isMobile ? 'background-color 0.2s ease' : 'all 0.15s ease',
                        opacity: isDisabled ? 0.4 : 1,
                        transform: isSelected ? 'scale(0.95)' : 'scale(1)',
                        // Mobile-first touch targets (iOS/Android guidelines)
                        minHeight: isMobile ? '48px' : '44px', // Larger on mobile
                        minWidth: isMobile ? '48px' : '44px',
                        border: isSelected ? `2px solid ${colorInfo.borderColor || '#1d4ed8'}` : `1px solid ${colorInfo.borderColor || 'transparent'}`,
                        borderRadius: isMobile ? '6px' : '4px', // Larger radius on mobile
                        fontSize: isMobile ? '10px' : '11px', // Better mobile readability
                        fontWeight: 500,
                        color: textColor,
                        // Mobile performance optimizations
                        willChange: 'transform, background-color',
                        backfaceVisibility: 'hidden',
                        // Better touch feedback
                        WebkitTapHighlightColor: 'transparent'
                      }}
                      onMouseOver={(e) => {
                        if (!isDisabled && !isMobile) { // Disable hover effects on mobile
                          e.currentTarget.style.transform = isSelected ? 'scale(0.95)' : 'scale(1.05)'
                        }
                      }}
                      onMouseOut={(e) => {
                        if (!isMobile) {
                          e.currentTarget.style.transform = isSelected ? 'scale(0.95)' : 'scale(1)'
                        }
                      }}
                    >
                      {/* Time label - optimized mobile typography */}
                      <div
                        style={{
                          position: 'absolute',
                          top: isMobile ? '2px' : '4px',
                          left: '50%',
                          transform: 'translateX(-50%)',
                          color: textColor,
                          fontWeight: 600,
                          lineHeight: isMobile ? 0.85 : 1,
                          textAlign: 'center',
                          whiteSpace: isMobile ? 'pre-line' : 'nowrap',
                          fontSize: '12px', // Larger font for better readability
                          textShadow: previewCount > 0 && !isSelected ? '0 0 2px rgba(255,255,255,0.5)' : 'none' // Better contrast
                        }}
                      >
                        {isMobile ? time.replace(' ', '\n') : time}
                      </div>
                      
                      {/* Attendee count moved to tooltip - cleaner interface */}
                      
                      {/* Preview indicator for user's selection */}
                      {includesUser && isSelected && (
                        <div
                          style={{
                            position: 'absolute',
                            top: isMobile ? '1px' : '2px',
                            right: isMobile ? '1px' : '2px',
                            width: isMobile ? '6px' : '8px',
                            height: isMobile ? '6px' : '8px',
                            backgroundColor: '#10b981', // Green dot for user's selection
                            borderRadius: '50%',
                            border: '1px solid white',
                            boxShadow: '0 0 2px rgba(0,0,0,0.3)'
                          }}
                        />
                      )}
                    </Box>
                    </Tooltip>
                  )
                })}
              </div>
              
              {/* Show More Times button */}
              {visibleTimeCount < FULL_DAY_HOURS.length && (
                <Group justify="center" mt="sm">
                  <Text
                    size="sm"
                    c="blue"
                    style={{ 
                      cursor: 'pointer',
                      textDecoration: 'underline'
                    }}
                    onClick={() => {
                      const increment = 12
                      setVisibleTimeCount(prev => 
                        Math.min(prev + increment, FULL_DAY_HOURS.length)
                      )
                    }}
                  >
                    Show More Times ({Math.min(12, FULL_DAY_HOURS.length - visibleTimeCount)} more)
                  </Text>
                </Group>
              )}
              
              {/* Show Fewer button when expanded */}
              {visibleTimeCount > 12 && (
                <Group justify="center" mt="xs">
                  <Text
                    size="sm"
                    c="gray"
                    style={{ 
                      cursor: 'pointer',
                      textDecoration: 'underline'
                    }}
                    onClick={() => setVisibleTimeCount(12)}
                  >
                    Show Fewer Times
                  </Text>
                </Group>
              )}
              
              {/* Time range summary */}
              <Group justify="space-between" mt="xs">
                <Text size="xs" c="dimmed">
                  {FULL_DAY_HOURS[0]} - {FULL_DAY_HOURS[Math.min(visibleTimeCount - 1, FULL_DAY_HOURS.length - 1)]}
                  {visibleTimeCount < FULL_DAY_HOURS.length && ` (${visibleTimeCount} of ${FULL_DAY_HOURS.length})`}
                </Text>
                <Text size="xs" c="dimmed">
                  30-minute intervals
                </Text>
              </Group>
            </Box>
          ))}
        </div>

        <Stack gap="xs">
          <Group justify="space-between" align="center">
            <Text size="sm" fw={500}>
              Selected: {selectedSlots.length} slots
            </Text>
            <Badge size="sm" variant="light" color="green">
              {selectedSlots.length > 0 ? 'Selection Active' : 'Ready to Select'}
            </Badge>
          </Group>
          
          <Text size={isMobile ? "xs" : "sm"} c="dimmed" style={{ lineHeight: 1.4 }}>
            {isMobile ? 'Tap to toggle time slots' : 'Click or drag to select/deselect time slots'}
            {isMobile && <br />}
            {!isMobile && ' | '}
            Numbers show attendee count
          </Text>
          
          <Group gap={isMobile ? "xs" : "sm"} wrap="wrap" style={{ justifyContent: isMobile ? 'center' : 'flex-start' }}>
            {/* Create legend using the actual color system */}
            {[0, 1, 2, 3, 4, 5].map(count => {
              const colorInfo = getTimeSlotColors(count, maxAttendees, false, false, useColorblindMode, currentColorScheme)
              const actualMaxResponses = eventData.responses.length
              const label = count === 0 ? 'None (0)' : 
                          count === 1 ? `Few (1)${count === 1 && actualMaxResponses >= 1 ? ' or You' : ''}` :
                          count === 2 ? `Some (2)` :
                          count === 3 ? `Many (3)` :
                          count === 4 ? `Most (4)` :
                          `All (${actualMaxResponses}+)`
              
              return (
                <Group key={count} gap="4px">
                  <Box 
                    style={{ 
                      width: isMobile ? 18 : 16, 
                      height: isMobile ? 18 : 16, 
                      backgroundColor: colorInfo.backgroundColor,
                      backgroundImage: colorInfo.pattern || 'none',
                      backgroundSize: colorInfo.pattern ? '8px 8px' : 'auto',
                      border: `1px solid ${colorInfo.borderColor}`,
                      borderRadius: isMobile ? 4 : 3,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0
                    }} 
                  >
                    {count > 0 && (
                      <Text 
                        size="10px" 
                        style={{ 
                          color: colorInfo.textColor, 
                          fontWeight: 600,
                          lineHeight: 1
                        }}
                      >
                        {count}
                      </Text>
                    )}
                  </Box>
                  <Text size="xs" c="dimmed">{label}</Text>
                </Group>
              )
            })}
            
            {/* Disabled state legend */}
            <Group gap="4px">
              <Box 
                style={{ 
                  width: isMobile ? 18 : 16, 
                  height: isMobile ? 18 : 16, 
                  backgroundColor: 'var(--mantine-color-gray-1)',
                  border: '1px solid var(--mantine-color-gray-4)',
                  borderRadius: isMobile ? 4 : 3,
                  opacity: 0.6,
                  flexShrink: 0
                }} 
              />
              <Text size="xs" c="dimmed">Out of scope</Text>
            </Group>
            
            {/* Selected state legend */}
            <Group gap="4px">
              <Box 
                style={{ 
                  width: isMobile ? 18 : 16, 
                  height: isMobile ? 18 : 16, 
                  backgroundColor: '#3b82f6',
                  border: '2px solid #1d4ed8',
                  borderRadius: isMobile ? 4 : 3,
                  transform: 'scale(0.9)',
                  flexShrink: 0
                }} 
              />
              <Text size="xs" c="dimmed">Your selection</Text>
            </Group>
          </Group>
        </Stack>
      </Stack>
    </Card>
  )
}

export default EnhancedTimelineLayout