import { Container, Title, Text, Card, Stack, Group, Button, Badge, Grid, TextInput } from '@mantine/core'
import { useParams, Link } from 'react-router-dom'
import { useState, useMemo, useCallback } from 'react'
// import { useDebouncedCallback } from '@mantine/hooks'
import { EnhancedTimelineLayout } from '../components/availability/EnhancedTimelineLayout'
import { BestTimesCard } from '../components/BestTimesCard'
import type { EventData, EventResponse } from '../types/event'
import { 
  findOptimalTimeRanges, 
  findOptimalTimeRangesWithPreview
} from '../utils/timeRangeAnalysis'
import { generatePreviewResponse, formatPreviewName } from '../utils/previewHelpers'

const SAMPLE_EVENT: EventData = {
  name: "Team Project Sync - All Day Scheduling",
  description: "Finding the best time for our team across different schedules and time zones. Select all times when you're available!",
  possibleDates: [
    { date: "2024-01-15", label: "Monday, Jan 15" },
    { date: "2024-01-16", label: "Tuesday, Jan 16" },
    { date: "2024-01-17", label: "Wednesday, Jan 17" },
  ],
  possibleTimes: [
    "12:00 AM", "12:15 AM", "12:30 AM", "12:45 AM",
    "1:00 AM", "1:15 AM", "1:30 AM", "1:45 AM",
    "2:00 AM", "2:15 AM", "2:30 AM", "2:45 AM",
    "3:00 AM", "3:15 AM", "3:30 AM", "3:45 AM",
    "4:00 AM", "4:15 AM", "4:30 AM", "4:45 AM",
    "5:00 AM", "5:15 AM", "5:30 AM", "5:45 AM",
    "6:00 AM", "6:15 AM", "6:30 AM", "6:45 AM",
    "7:00 AM", "7:15 AM", "7:30 AM", "7:45 AM",
    "8:00 AM", "8:15 AM", "8:30 AM", "8:45 AM",
    "9:00 AM", "9:15 AM", "9:30 AM", "9:45 AM",
    "10:00 AM", "10:15 AM", "10:30 AM", "10:45 AM",
    "11:00 AM", "11:15 AM", "11:30 AM", "11:45 AM",
    "12:00 PM", "12:15 PM", "12:30 PM", "12:45 PM",
    "1:00 PM", "1:15 PM", "1:30 PM", "1:45 PM",
    "2:00 PM", "2:15 PM", "2:30 PM", "2:45 PM",
    "3:00 PM", "3:15 PM", "3:30 PM", "3:45 PM",
    "4:00 PM", "4:15 PM", "4:30 PM", "4:45 PM",
    "5:00 PM", "5:15 PM", "5:30 PM", "5:45 PM",
    "6:00 PM", "6:15 PM", "6:30 PM", "6:45 PM",
    "7:00 PM", "7:15 PM", "7:30 PM", "7:45 PM",
    "8:00 PM", "8:15 PM", "8:30 PM", "8:45 PM",
    "9:00 PM", "9:15 PM", "9:30 PM", "9:45 PM",
    "10:00 PM", "10:15 PM", "10:30 PM", "10:45 PM",
    "11:00 PM", "11:15 PM", "11:30 PM", "11:45 PM"
  ],
  responses: [
    // Early Bird - 6 AM to 2 PM availability
    { 
      name: "Alice (Early Bird)", 
      availability: [
        // Monday
        "2024-01-15-6:00 AM", "2024-01-15-6:15 AM", "2024-01-15-6:30 AM", "2024-01-15-6:45 AM",
        "2024-01-15-7:00 AM", "2024-01-15-7:15 AM", "2024-01-15-7:30 AM", "2024-01-15-7:45 AM",
        "2024-01-15-8:00 AM", "2024-01-15-8:15 AM", "2024-01-15-8:30 AM", "2024-01-15-8:45 AM",
        "2024-01-15-9:00 AM", "2024-01-15-9:15 AM", "2024-01-15-9:30 AM", "2024-01-15-9:45 AM",
        "2024-01-15-10:00 AM", "2024-01-15-10:15 AM", "2024-01-15-10:30 AM", "2024-01-15-10:45 AM",
        "2024-01-15-11:00 AM", "2024-01-15-11:15 AM", "2024-01-15-11:30 AM", "2024-01-15-11:45 AM",
        "2024-01-15-12:00 PM", "2024-01-15-12:15 PM", "2024-01-15-12:30 PM", "2024-01-15-12:45 PM",
        "2024-01-15-1:00 PM", "2024-01-15-1:15 PM", "2024-01-15-1:30 PM", "2024-01-15-1:45 PM",
        // Tuesday
        "2024-01-16-6:00 AM", "2024-01-16-6:15 AM", "2024-01-16-6:30 AM", "2024-01-16-6:45 AM",
        "2024-01-16-7:00 AM", "2024-01-16-7:15 AM", "2024-01-16-7:30 AM", "2024-01-16-7:45 AM",
        "2024-01-16-8:00 AM", "2024-01-16-8:15 AM", "2024-01-16-8:30 AM", "2024-01-16-8:45 AM",
        "2024-01-16-9:00 AM", "2024-01-16-9:15 AM", "2024-01-16-9:30 AM", "2024-01-16-9:45 AM",
        "2024-01-16-10:00 AM", "2024-01-16-10:15 AM", "2024-01-16-10:30 AM", "2024-01-16-10:45 AM",
        "2024-01-16-11:00 AM", "2024-01-16-11:15 AM", "2024-01-16-11:30 AM", "2024-01-16-11:45 AM",
        "2024-01-16-12:00 PM", "2024-01-16-12:15 PM", "2024-01-16-12:30 PM", "2024-01-16-12:45 PM",
        "2024-01-16-1:00 PM", "2024-01-16-1:15 PM", "2024-01-16-1:30 PM", "2024-01-16-1:45 PM",
        // Wednesday - partial availability
        "2024-01-17-8:00 AM", "2024-01-17-8:15 AM", "2024-01-17-8:30 AM", "2024-01-17-8:45 AM",
        "2024-01-17-9:00 AM", "2024-01-17-9:15 AM", "2024-01-17-9:30 AM", "2024-01-17-9:45 AM",
        "2024-01-17-10:00 AM", "2024-01-17-10:15 AM", "2024-01-17-10:30 AM", "2024-01-17-10:45 AM"
      ]
    },
    // Standard Worker - 9 AM to 5 PM availability
    { 
      name: "Bob (Standard Hours)", 
      availability: [
        // Monday
        "2024-01-15-9:00 AM", "2024-01-15-9:15 AM", "2024-01-15-9:30 AM", "2024-01-15-9:45 AM",
        "2024-01-15-10:00 AM", "2024-01-15-10:15 AM", "2024-01-15-10:30 AM", "2024-01-15-10:45 AM",
        "2024-01-15-11:00 AM", "2024-01-15-11:15 AM", "2024-01-15-11:30 AM", "2024-01-15-11:45 AM",
        "2024-01-15-12:00 PM", "2024-01-15-12:15 PM", "2024-01-15-12:30 PM", "2024-01-15-12:45 PM",
        "2024-01-15-1:00 PM", "2024-01-15-1:15 PM", "2024-01-15-1:30 PM", "2024-01-15-1:45 PM",
        "2024-01-15-2:00 PM", "2024-01-15-2:15 PM", "2024-01-15-2:30 PM", "2024-01-15-2:45 PM",
        "2024-01-15-3:00 PM", "2024-01-15-3:15 PM", "2024-01-15-3:30 PM", "2024-01-15-3:45 PM",
        "2024-01-15-4:00 PM", "2024-01-15-4:15 PM", "2024-01-15-4:30 PM", "2024-01-15-4:45 PM",
        // Tuesday
        "2024-01-16-9:00 AM", "2024-01-16-9:15 AM", "2024-01-16-9:30 AM", "2024-01-16-9:45 AM",
        "2024-01-16-10:00 AM", "2024-01-16-10:15 AM", "2024-01-16-10:30 AM", "2024-01-16-10:45 AM",
        "2024-01-16-11:00 AM", "2024-01-16-11:15 AM", "2024-01-16-11:30 AM", "2024-01-16-11:45 AM",
        "2024-01-16-12:00 PM", "2024-01-16-12:15 PM", "2024-01-16-12:30 PM", "2024-01-16-12:45 PM",
        "2024-01-16-1:00 PM", "2024-01-16-1:15 PM", "2024-01-16-1:30 PM", "2024-01-16-1:45 PM",
        "2024-01-16-2:00 PM", "2024-01-16-2:15 PM", "2024-01-16-2:30 PM", "2024-01-16-2:45 PM",
        "2024-01-16-3:00 PM", "2024-01-16-3:15 PM", "2024-01-16-3:30 PM", "2024-01-16-3:45 PM",
        "2024-01-16-4:00 PM", "2024-01-16-4:15 PM", "2024-01-16-4:30 PM", "2024-01-16-4:45 PM",
        // Wednesday
        "2024-01-17-9:00 AM", "2024-01-17-9:15 AM", "2024-01-17-9:30 AM", "2024-01-17-9:45 AM",
        "2024-01-17-10:00 AM", "2024-01-17-10:15 AM", "2024-01-17-10:30 AM", "2024-01-17-10:45 AM",
        "2024-01-17-11:00 AM", "2024-01-17-11:15 AM", "2024-01-17-11:30 AM", "2024-01-17-11:45 AM",
        "2024-01-17-12:00 PM", "2024-01-17-12:15 PM", "2024-01-17-12:30 PM", "2024-01-17-12:45 PM",
        "2024-01-17-1:00 PM", "2024-01-17-1:15 PM", "2024-01-17-1:30 PM", "2024-01-17-1:45 PM",
        "2024-01-17-2:00 PM", "2024-01-17-2:15 PM", "2024-01-17-2:30 PM", "2024-01-17-2:45 PM",
        "2024-01-17-3:00 PM", "2024-01-17-3:15 PM", "2024-01-17-3:30 PM", "2024-01-17-3:45 PM",
        "2024-01-17-4:00 PM", "2024-01-17-4:15 PM", "2024-01-17-4:30 PM", "2024-01-17-4:45 PM"
      ]
    },
    // Night Owl - 2 PM to 10 PM availability
    { 
      name: "Carol (Night Owl)", 
      availability: [
        // Monday
        "2024-01-15-2:00 PM", "2024-01-15-2:15 PM", "2024-01-15-2:30 PM", "2024-01-15-2:45 PM",
        "2024-01-15-3:00 PM", "2024-01-15-3:15 PM", "2024-01-15-3:30 PM", "2024-01-15-3:45 PM",
        "2024-01-15-4:00 PM", "2024-01-15-4:15 PM", "2024-01-15-4:30 PM", "2024-01-15-4:45 PM",
        "2024-01-15-5:00 PM", "2024-01-15-5:15 PM", "2024-01-15-5:30 PM", "2024-01-15-5:45 PM",
        "2024-01-15-6:00 PM", "2024-01-15-6:15 PM", "2024-01-15-6:30 PM", "2024-01-15-6:45 PM",
        "2024-01-15-7:00 PM", "2024-01-15-7:15 PM", "2024-01-15-7:30 PM", "2024-01-15-7:45 PM",
        "2024-01-15-8:00 PM", "2024-01-15-8:15 PM", "2024-01-15-8:30 PM", "2024-01-15-8:45 PM",
        "2024-01-15-9:00 PM", "2024-01-15-9:15 PM", "2024-01-15-9:30 PM", "2024-01-15-9:45 PM",
        // Tuesday - limited availability
        "2024-01-16-3:00 PM", "2024-01-16-3:15 PM", "2024-01-16-3:30 PM", "2024-01-16-3:45 PM",
        "2024-01-16-4:00 PM", "2024-01-16-4:15 PM", "2024-01-16-4:30 PM", "2024-01-16-4:45 PM",
        "2024-01-16-7:00 PM", "2024-01-16-7:15 PM", "2024-01-16-7:30 PM", "2024-01-16-7:45 PM",
        "2024-01-16-8:00 PM", "2024-01-16-8:15 PM", "2024-01-16-8:30 PM", "2024-01-16-8:45 PM",
        // Wednesday
        "2024-01-17-2:00 PM", "2024-01-17-2:15 PM", "2024-01-17-2:30 PM", "2024-01-17-2:45 PM",
        "2024-01-17-3:00 PM", "2024-01-17-3:15 PM", "2024-01-17-3:30 PM", "2024-01-17-3:45 PM",
        "2024-01-17-4:00 PM", "2024-01-17-4:15 PM", "2024-01-17-4:30 PM", "2024-01-17-4:45 PM",
        "2024-01-17-5:00 PM", "2024-01-17-5:15 PM", "2024-01-17-5:30 PM", "2024-01-17-5:45 PM",
        "2024-01-17-6:00 PM", "2024-01-17-6:15 PM", "2024-01-17-6:30 PM", "2024-01-17-6:45 PM",
        "2024-01-17-7:00 PM", "2024-01-17-7:15 PM", "2024-01-17-7:30 PM", "2024-01-17-7:45 PM",
        "2024-01-17-8:00 PM", "2024-01-17-8:15 PM", "2024-01-17-8:30 PM", "2024-01-17-8:45 PM",
        "2024-01-17-9:00 PM", "2024-01-17-9:15 PM", "2024-01-17-9:30 PM", "2024-01-17-9:45 PM"
      ]
    },
    // Flexible Worker - varied patterns
    { 
      name: "David (Flexible)", 
      availability: [
        // Monday - morning and evening blocks
        "2024-01-15-7:00 AM", "2024-01-15-7:15 AM", "2024-01-15-7:30 AM", "2024-01-15-7:45 AM",
        "2024-01-15-8:00 AM", "2024-01-15-8:15 AM", "2024-01-15-8:30 AM", "2024-01-15-8:45 AM",
        "2024-01-15-6:00 PM", "2024-01-15-6:15 PM", "2024-01-15-6:30 PM", "2024-01-15-6:45 PM",
        "2024-01-15-7:00 PM", "2024-01-15-7:15 PM", "2024-01-15-7:30 PM", "2024-01-15-7:45 PM",
        // Tuesday - midday availability
        "2024-01-16-11:00 AM", "2024-01-16-11:15 AM", "2024-01-16-11:30 AM", "2024-01-16-11:45 AM",
        "2024-01-16-12:00 PM", "2024-01-16-12:15 PM", "2024-01-16-12:30 PM", "2024-01-16-12:45 PM",
        "2024-01-16-1:00 PM", "2024-01-16-1:15 PM", "2024-01-16-1:30 PM", "2024-01-16-1:45 PM",
        "2024-01-16-2:00 PM", "2024-01-16-2:15 PM", "2024-01-16-2:30 PM", "2024-01-16-2:45 PM",
        // Wednesday - scattered availability
        "2024-01-17-9:00 AM", "2024-01-17-9:15 AM", "2024-01-17-9:30 AM", "2024-01-17-9:45 AM",
        "2024-01-17-2:00 PM", "2024-01-17-2:15 PM", "2024-01-17-2:30 PM", "2024-01-17-2:45 PM",
        "2024-01-17-5:00 PM", "2024-01-17-5:15 PM", "2024-01-17-5:30 PM", "2024-01-17-5:45 PM",
        "2024-01-17-8:00 PM", "2024-01-17-8:15 PM", "2024-01-17-8:30 PM", "2024-01-17-8:45 PM"
      ]
    },
    // International Worker - different time zone pattern
    { 
      name: "Emma (International)", 
      availability: [
        // Monday - early morning and late evening
        "2024-01-15-5:00 AM", "2024-01-15-5:15 AM", "2024-01-15-5:30 AM", "2024-01-15-5:45 AM",
        "2024-01-15-6:00 AM", "2024-01-15-6:15 AM", "2024-01-15-6:30 AM", "2024-01-15-6:45 AM",
        "2024-01-15-10:00 PM", "2024-01-15-10:15 PM", "2024-01-15-10:30 PM", "2024-01-15-10:45 PM",
        "2024-01-15-11:00 PM", "2024-01-15-11:15 PM", "2024-01-15-11:30 PM", "2024-01-15-11:45 PM",
        // Tuesday - midday overlap
        "2024-01-16-11:00 AM", "2024-01-16-11:15 AM", "2024-01-16-11:30 AM", "2024-01-16-11:45 AM",
        "2024-01-16-12:00 PM", "2024-01-16-12:15 PM", "2024-01-16-12:30 PM", "2024-01-16-12:45 PM",
        "2024-01-16-1:00 PM", "2024-01-16-1:15 PM", "2024-01-16-1:30 PM", "2024-01-16-1:45 PM",
        // Wednesday - varied times
        "2024-01-17-6:00 AM", "2024-01-17-6:15 AM", "2024-01-17-6:30 AM", "2024-01-17-6:45 AM",
        "2024-01-17-3:00 PM", "2024-01-17-3:15 PM", "2024-01-17-3:30 PM", "2024-01-17-3:45 PM",
        "2024-01-17-9:00 PM", "2024-01-17-9:15 PM", "2024-01-17-9:30 PM", "2024-01-17-9:45 PM"
      ]
    }
  ]
}

export default function Event() {
  const { eventId } = useParams<{ eventId: string }>()
  const [participantName, setParticipantName] = useState('')
  const [selectedSlots, setSelectedSlots] = useState<string[]>([])
  const [hasSubmitted, setHasSubmitted] = useState(false)
  const [previewMode, setPreviewMode] = useState(true)

  const isSampleEvent = eventId?.includes('sample')
  const event = isSampleEvent ? SAMPLE_EVENT : null

  // Generate preview response when user has selections
  const previewResponse = useMemo(() => {
    if (!previewMode || selectedSlots.length === 0 || hasSubmitted) {
      return null
    }
    return generatePreviewResponse(participantName || 'You', selectedSlots)
  }, [participantName, selectedSlots, previewMode, hasSubmitted])

  // Create responses array including preview
  const responsesWithPreview = useMemo(() => {
    if (!event) return []
    return previewResponse ? [...event.responses, previewResponse] : event.responses
  }, [event, previewResponse])

  // Calculate optimal time ranges including preview - debounced for performance
  const calculateOptimalRanges = useCallback((
    eventData: EventData | null, 
    preview: EventResponse | null
  ) => {
    if (!eventData) return []
    
    if (preview) {
      return findOptimalTimeRangesWithPreview(eventData, [preview], 5)
    } else {
      return findOptimalTimeRanges(eventData, 5)
    }
  }, [])

  // Debounced calculation to prevent excessive recalculation during drag (for future use)
  // const debouncedCalculateRanges = useDebouncedCallback(calculateOptimalRanges, 250)

  // Calculate optimal time ranges with real-time preview
  const optimalTimeRanges = useMemo(() => {
    return calculateOptimalRanges(event, previewResponse)
  }, [event, previewResponse, calculateOptimalRanges])

  const handleSubmit = () => {
    if (!participantName.trim() || selectedSlots.length === 0) return
    setHasSubmitted(true)
    setPreviewMode(false) // Disable preview mode after submission
    alert(`Thanks ${participantName}! Your availability has been recorded.`)
  }

  // Type guard to ensure event exists for the sample event case
  if (!event) {
    return (
      <Container size="lg" py="xl">
        <Stack gap="lg">
          <Title order={1}>Event Not Found</Title>
          <Text c="dimmed">Event ID: {eventId}</Text>
          <Text>This event doesn't exist or hasn't been created yet.</Text>
          <Button component={Link} to="/create" variant="outline">
            Create a New Event
          </Button>
        </Stack>
      </Container>
    )
  }


  return (
    <Container size="lg" py="xl">
      <Stack gap="xl">
        <div>
          <Title order={1} mb="md">{event.name}</Title>
          {event.description && (
            <Text c="dimmed" mb="sm">{event.description}</Text>
          )}
          <Badge mt="sm" color="blue">Demo Event</Badge>
        </div>

        <Grid>
          <Grid.Col span={{ base: 12, md: 8 }}>
            <Card shadow="sm" padding="lg" radius="md" withBorder>
              <Stack gap="lg">
                <Title order={2} size="h3">When are you available?</Title>
                
                {!hasSubmitted && (
                  <TextInput
                    label="Your Name"
                    placeholder="Enter your name"
                    value={participantName}
                    onChange={(e) => setParticipantName(e.target.value)}
                    required
                  />
                )}

                <div>
                  <Text fw={500} mb="md">Select your available times:</Text>
                  <EnhancedTimelineLayout
                    eventData={event}
                    onSelectionChange={setSelectedSlots}
                    disabled={hasSubmitted}
                    selectedSlots={selectedSlots}
                  />
                </div>

              </Stack>
            </Card>
          </Grid.Col>

          <Grid.Col span={{ base: 12, md: 4 }}>
            {!hasSubmitted && (
              <Card shadow="sm" padding="lg" radius="md" withBorder mb="md">
                <Button
                  onClick={handleSubmit}
                  disabled={!participantName.trim() || selectedSlots.length === 0}
                  variant={selectedSlots.length > 0 && participantName.trim() ? "filled" : "outline"}
                  color={selectedSlots.length > 0 && participantName.trim() ? "blue" : "gray"}
                  size="lg"
                  fullWidth
                  style={{
                    transition: 'all 0.2s ease',
                    opacity: (!participantName.trim() || selectedSlots.length === 0) ? 0.6 : 1
                  }}
                >
                  {!participantName.trim() 
                    ? "Enter your name to continue"
                    : selectedSlots.length === 0 
                      ? "Select time slots to submit"
                      : "Submit Availability"
                  }
                </Button>
              </Card>
            )}
            
            <BestTimesCard 
              ranges={optimalTimeRanges}
              hasPreview={!!previewResponse}
              maxVisible={3}
            />

            <Card shadow="sm" padding="lg" radius="md" withBorder mt="md">
              <Stack gap="md">
                <Group justify="space-between" align="center">
                  <Title order={3} size="h4">Current Responses</Title>
                  {selectedSlots.length > 0 && !hasSubmitted && (
                    <Text 
                      size="sm" 
                      c="blue" 
                      style={{ cursor: 'pointer', textDecoration: 'underline' }}
                      onClick={() => setSelectedSlots([])}
                      aria-label="Clear all selected time slots"
                    >
                      Clear my selections
                    </Text>
                  )}
                </Group>
                {responsesWithPreview.map(response => (
                  <div key={response.name} style={{ 
                    opacity: response.isPreview ? 0.9 : 1,
                    borderLeft: response.isPreview ? '3px solid var(--mantine-color-orange-4)' : 'none',
                    paddingLeft: response.isPreview ? '8px' : '0'
                  }}>
                    <Group gap="xs" align="center">
                      <Text size="sm" fw={500}>
                        {formatPreviewName(response)}
                      </Text>
                      {response.isPreview && (
                        <Badge size="xs" variant="outline" color="orange">
                          Preview
                        </Badge>
                      )}
                    </Group>
                    <Text size="xs" c="dimmed">
                      {response.availability.length} time slot{response.availability.length !== 1 ? 's' : ''} selected
                    </Text>
                  </div>
                ))}
                {hasSubmitted && !previewResponse && (
                  <div>
                    <Text size="sm" fw={500}>{participantName}</Text>
                    <Text size="xs" c="dimmed">
                      {selectedSlots.length} time slot{selectedSlots.length !== 1 ? 's' : ''} selected
                    </Text>
                  </div>
                )}
              </Stack>
            </Card>
          </Grid.Col>
        </Grid>

        <Group justify="center" gap="md">
          <Button component={Link} to="/event/sample/layouts" variant="outline">
            Compare Interface Layouts
          </Button>
          <Button component={Link} to="/" variant="subtle">
            Create Your Own Event
          </Button>
        </Group>
      </Stack>
    </Container>
  )
}