import type { EventData, EventResponse } from '../types/event'

export interface TimeSlotAnalysis {
  dateTime: string
  date: string
  time: string
  attendeeCount: number
  attendees: string[]
}

export interface OptimalTimeRange {
  date: string
  dayLabel: string
  startTime: string
  endTime: string
  attendeeCount: number
  attendees: string[]
  duration: number // in minutes
  hasPreview?: boolean
  previewDelta?: number // Change in attendance due to preview
}

/**
 * Analyzes all time slots and returns attendance data for each slot
 */
export function analyzeTimeSlots(eventData: EventData): TimeSlotAnalysis[] {
  const slotAnalysis = new Map<string, TimeSlotAnalysis>()
  
  // Initialize all possible slots with zero attendance
  for (const dateObj of eventData.possibleDates) {
    for (const time of eventData.possibleTimes) {
      const dateTime = `${dateObj.date}-${time}`
      slotAnalysis.set(dateTime, {
        dateTime,
        date: dateObj.date,
        time,
        attendeeCount: 0,
        attendees: []
      })
    }
  }
  
  // Count attendance for each slot
  for (const response of eventData.responses) {
    for (const availableSlot of response.availability) {
      const existing = slotAnalysis.get(availableSlot)
      if (existing) {
        existing.attendeeCount++
        existing.attendees.push(response.name)
      }
    }
  }
  
  return Array.from(slotAnalysis.values())
}

/**
 * Determines the threshold for "high attendance" based on the distribution
 */
function calculateAttendanceThreshold(slots: TimeSlotAnalysis[]): number {
  const attendanceCounts = slots.map(slot => slot.attendeeCount).filter(count => count > 0)
  
  if (attendanceCounts.length === 0) return 0
  
  // Sort attendance counts in descending order
  attendanceCounts.sort((a, b) => b - a)
  
  // Use the top 30% threshold, but ensure at least 2 people minimum
  const topThirtyPercentIndex = Math.floor(attendanceCounts.length * 0.3)
  const threshold = Math.max(2, attendanceCounts[topThirtyPercentIndex] || 2)
  
  return threshold
}

/**
 * Groups consecutive high-attendance time slots into ranges
 */
function groupConsecutiveSlots(slots: TimeSlotAnalysis[], threshold: number): OptimalTimeRange[] {
  // Group slots by date
  const slotsByDate = new Map<string, TimeSlotAnalysis[]>()
  
  for (const slot of slots) {
    if (slot.attendeeCount >= threshold) {
      if (!slotsByDate.has(slot.date)) {
        slotsByDate.set(slot.date, [])
      }
      slotsByDate.get(slot.date)!.push(slot)
    }
  }
  
  const ranges: OptimalTimeRange[] = []
  
  // Process each date
  for (const [date, dateSlots] of slotsByDate) {
    // Sort slots by time
    dateSlots.sort((a, b) => {
      const timeA = convertTo24Hour(a.time)
      const timeB = convertTo24Hour(b.time)
      return timeA.localeCompare(timeB)
    })
    
    if (dateSlots.length === 0) continue
    
    // Group consecutive slots
    let currentRange: TimeSlotAnalysis[] = [dateSlots[0]]
    
    for (let i = 1; i < dateSlots.length; i++) {
      const current = dateSlots[i]
      const previous = dateSlots[i - 1]
      
      // Check if slots are consecutive (15-minute intervals)
      if (areConsecutiveTimeSlots(previous.time, current.time)) {
        currentRange.push(current)
      } else {
        // End current range and start new one
        if (currentRange.length > 0) {
          ranges.push(createTimeRange(date, currentRange))
        }
        currentRange = [current]
      }
    }
    
    // Add the final range
    if (currentRange.length > 0) {
      ranges.push(createTimeRange(date, currentRange))
    }
  }
  
  return ranges
}

/**
 * Converts time to 24-hour format for comparison
 */
function convertTo24Hour(time12h: string): string {
  const [time, modifier] = time12h.split(' ')
  let [hours] = time.split(':').map(Number)
  const [, minutes] = time.split(':').map(Number)
  
  if (modifier === 'PM' && hours !== 12) {
    hours += 12
  } else if (modifier === 'AM' && hours === 12) {
    hours = 0
  }
  
  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`
}

/**
 * Checks if two time slots are consecutive (15-minute intervals)
 */
function areConsecutiveTimeSlots(time1: string, time2: string): boolean {
  const time1_24 = convertTo24Hour(time1)
  const time2_24 = convertTo24Hour(time2)
  
  const [h1, m1] = time1_24.split(':').map(Number)
  const [h2, m2] = time2_24.split(':').map(Number)
  
  const minutes1 = h1 * 60 + m1
  const minutes2 = h2 * 60 + m2
  
  return minutes2 - minutes1 === 15
}

/**
 * Creates a time range from consecutive slots
 */
function createTimeRange(date: string, slots: TimeSlotAnalysis[]): OptimalTimeRange {
  if (slots.length === 0) {
    throw new Error('Cannot create time range from empty slots array')
  }
  
  const startTime = slots[0].time
  const endTime = addMinutesToTime(slots[slots.length - 1].time, 15)
  
  // Find the date label
  const dateObj = new Date(date)
  const dayLabel = dateObj.toLocaleDateString('en-US', { 
    weekday: 'long', 
    month: 'short', 
    day: 'numeric' 
  })
  
  // Note: We use unique attendees count instead of average attendance
  
  // Get unique attendees across the range
  const uniqueAttendees = Array.from(new Set(
    slots.flatMap(slot => slot.attendees)
  ))
  
  return {
    date,
    dayLabel,
    startTime,
    endTime,
    attendeeCount: uniqueAttendees.length, // Use unique count
    attendees: uniqueAttendees,
    duration: slots.length * 15 // 15 minutes per slot
  }
}

/**
 * Adds minutes to a time string
 */
function addMinutesToTime(timeStr: string, minutesToAdd: number): string {
  const time24 = convertTo24Hour(timeStr)
  const [hours, minutes] = time24.split(':').map(Number)
  
  const totalMinutes = hours * 60 + minutes + minutesToAdd
  const newHours = Math.floor(totalMinutes / 60) % 24
  const newMinutes = totalMinutes % 60
  
  // Convert back to 12-hour format
  let displayHours = newHours
  const ampm = newHours >= 12 ? 'PM' : 'AM'
  
  if (newHours === 0) {
    displayHours = 12
  } else if (newHours > 12) {
    displayHours = newHours - 12
  }
  
  return `${displayHours}:${newMinutes.toString().padStart(2, '0')} ${ampm}`
}

/**
 * Main function to find optimal time ranges
 */
export function findOptimalTimeRanges(eventData: EventData, maxRanges: number = 5): OptimalTimeRange[] {
  const slotAnalysis = analyzeTimeSlots(eventData)
  const threshold = calculateAttendanceThreshold(slotAnalysis)
  const ranges = groupConsecutiveSlots(slotAnalysis, threshold)
  
  // Sort by attendance count (descending) and then by duration (descending)
  ranges.sort((a, b) => {
    if (b.attendeeCount !== a.attendeeCount) {
      return b.attendeeCount - a.attendeeCount
    }
    return b.duration - a.duration
  })
  
  // Return top N ranges
  return ranges.slice(0, maxRanges)
}

/**
 * Formats a time range for display
 */
export function formatTimeRange(range: OptimalTimeRange): string {
  return `${range.dayLabel}: ${range.startTime}–${range.endTime} (${range.attendeeCount} people)`
}

// ============================================================================
// PREVIEW-AWARE ANALYSIS FUNCTIONS
// ============================================================================

/**
 * Analyzes time slots including preview responses
 */
export function analyzeTimeSlotsWithPreview(
  eventData: EventData, 
  previewResponses: EventResponse[] = []
): TimeSlotAnalysis[] {
  const slotAnalysis = new Map<string, TimeSlotAnalysis>()
  
  // Initialize all possible slots with zero attendance
  for (const dateObj of eventData.possibleDates) {
    for (const time of eventData.possibleTimes) {
      const dateTime = `${dateObj.date}-${time}`
      slotAnalysis.set(dateTime, {
        dateTime,
        date: dateObj.date,
        time,
        attendeeCount: 0,
        attendees: []
      })
    }
  }
  
  // Count attendance from both submitted and preview responses
  const allResponses = [...eventData.responses, ...previewResponses]
  
  for (const response of allResponses) {
    for (const availableSlot of response.availability) {
      const existing = slotAnalysis.get(availableSlot)
      if (existing) {
        existing.attendeeCount++
        existing.attendees.push(response.name)
      }
    }
  }
  
  return Array.from(slotAnalysis.values())
}

/**
 * Find optimal time ranges including preview data
 */
export function findOptimalTimeRangesWithPreview(
  eventData: EventData, 
  previewResponses: EventResponse[] = [],
  maxRanges: number = 5
): OptimalTimeRange[] {
  // Calculate original ranges without preview
  const originalSlots = analyzeTimeSlots(eventData)
  const originalThreshold = calculateAttendanceThreshold(originalSlots)
  const originalRanges = groupConsecutiveSlots(originalSlots, originalThreshold)
  
  // Calculate ranges with preview
  const previewSlots = analyzeTimeSlotsWithPreview(eventData, previewResponses)
  const previewThreshold = calculateAttendanceThreshold(previewSlots)
  const previewRanges = groupConsecutiveSlots(previewSlots, previewThreshold)
  
  // Add preview metadata to ranges
  const enhancedRanges = previewRanges.map(previewRange => {
    const originalRange = originalRanges.find(orig => 
      orig.date === previewRange.date && 
      orig.startTime === previewRange.startTime &&
      orig.endTime === previewRange.endTime
    )
    
    const previewDelta = originalRange 
      ? previewRange.attendeeCount - originalRange.attendeeCount
      : previewRange.attendeeCount
    
    return {
      ...previewRange,
      hasPreview: previewResponses.length > 0 && previewDelta !== 0,
      previewDelta
    }
  })
  
  // Sort by attendance count (descending) and then by duration (descending)
  enhancedRanges.sort((a, b) => {
    if (b.attendeeCount !== a.attendeeCount) {
      return b.attendeeCount - a.attendeeCount
    }
    return b.duration - a.duration
  })
  
  return enhancedRanges.slice(0, maxRanges)
}

/**
 * Formats a time range with preview indicator for display
 */
export function formatTimeRangeWithPreview(range: OptimalTimeRange): string {
  const baseText = `${range.dayLabel}: ${range.startTime}–${range.endTime} (${range.attendeeCount} people)`
  
  if (range.hasPreview && range.previewDelta !== undefined) {
    const deltaText = range.previewDelta > 0 
      ? ` ↑ +${range.previewDelta}` 
      : ` ↓ ${range.previewDelta}`
    return `${baseText}${deltaText}`
  }
  
  return baseText
}

/**
 * Create a combined response array including preview data
 */
export function createPreviewEventData(
  eventData: EventData,
  previewSelections: string[],
  userName: string
): EventData {
  if (previewSelections.length === 0) {
    return eventData
  }
  
  const previewResponse: EventResponse = {
    name: userName.trim() || 'You',
    availability: previewSelections,
    isPreview: true,
    isTemporary: true,
    timestamp: new Date()
  }
  
  return {
    ...eventData,
    responses: [...eventData.responses, previewResponse]
  }
}