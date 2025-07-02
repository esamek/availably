import { 
  Container, 
  Title, 
  Text, 
  Card, 
  Stack, 
  Group, 
  Button, 
  Badge, 
  Grid, 
  Box,
  Progress,
  SimpleGrid,
  Divider
} from '@mantine/core'
import { Link } from 'react-router-dom'
import { useState } from 'react'
import { EnhancedTimelineLayout } from '../components/availability/EnhancedTimelineLayout'

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

// Sample event data with 15-minute increments
const SAMPLE_EVENT: EventData = {
  name: "Team Lunch Planning",
  description: "Let's find a good time for everyone to grab lunch together!",
  possibleDates: [
    { date: "2024-01-15", label: "Monday, Jan 15" },
    { date: "2024-01-16", label: "Tuesday, Jan 16" },
    { date: "2024-01-17", label: "Wednesday, Jan 17" },
  ],
  possibleTimes: [
    "12:00 PM", "12:15 PM", "12:30 PM", "12:45 PM",
    "1:00 PM", "1:15 PM", "1:30 PM", "1:45 PM"
  ],
  responses: [
    { 
      name: "Alice", 
      availability: [
        "2024-01-15-12:00 PM", "2024-01-15-12:15 PM", "2024-01-15-12:30 PM",
        "2024-01-16-1:00 PM", "2024-01-16-1:15 PM"
      ] 
    },
    { 
      name: "Bob", 
      availability: [
        "2024-01-15-12:30 PM", "2024-01-15-12:45 PM",
        "2024-01-16-12:00 PM", "2024-01-16-1:00 PM", "2024-01-16-1:15 PM"
      ] 
    },
  ]
}

// Layout A: Calendar Grid with Drag-Select
function LayoutA() {
  const [selectedSlots, setSelectedSlots] = useState<string[]>([])
  const [isDragging, setIsDragging] = useState(false)
  const [dragStart, setDragStart] = useState<string | null>(null)

  const handleMouseDown = (dateTime: string) => {
    setIsDragging(true)
    setDragStart(dateTime)
    setSelectedSlots(prev => 
      prev.includes(dateTime) 
        ? prev.filter(slot => slot !== dateTime)
        : [...prev, dateTime]
    )
  }

  const handleMouseEnter = (dateTime: string) => {
    if (isDragging && dragStart) {
      setSelectedSlots(prev => 
        prev.includes(dateTime) 
          ? prev 
          : [...prev, dateTime]
      )
    }
  }

  const handleMouseUp = () => {
    setIsDragging(false)
    setDragStart(null)
  }

  const getSlotCount = (dateTime: string) => {
    return SAMPLE_EVENT.responses.filter(r => r.availability.includes(dateTime)).length
  }

  return (
    <Card shadow="sm" padding="lg" radius="md" withBorder>
      <Stack gap="md">
        <Group justify="space-between">
          <Title order={3} c="blue">Layout A: Calendar Grid with Drag-Select</Title>
          <Badge variant="light" color="blue">Interactive</Badge>
        </Group>
        
        <Text size="sm" c="dimmed">
          Click and drag to select multiple time slots. Visual grid shows coordinator availability.
        </Text>

        <div onMouseUp={handleMouseUp} onMouseLeave={handleMouseUp}>
          <SimpleGrid cols={4} spacing="xs">
            <Box></Box>
            {SAMPLE_EVENT.possibleDates.map(date => (
              <Text key={date.date} size="xs" fw={500} ta="center">
                {date.label.split(',')[0]}
              </Text>
            ))}
            
            {SAMPLE_EVENT.possibleTimes.map(time => (
              <Box key={time}>
                <Text size="xs" fw={500} style={{ whiteSpace: 'nowrap' }}>
                  {time}
                </Text>
                {SAMPLE_EVENT.possibleDates.map(date => {
                  const dateTime = `${date.date}-${time}`
                  const count = getSlotCount(dateTime)
                  const isSelected = selectedSlots.includes(dateTime)
                  
                  return (
                    <Box
                      key={dateTime}
                      onMouseDown={() => handleMouseDown(dateTime)}
                      onMouseEnter={() => handleMouseEnter(dateTime)}
                      style={{
                        width: '100%',
                        height: 30,
                        backgroundColor: isSelected 
                          ? '#228be6' 
                          : count > 0 
                            ? `rgba(34, 139, 230, ${count * 0.3})` 
                            : '#f8f9fa',
                        border: '1px solid #dee2e6',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        userSelect: 'none',
                        borderRadius: 4,
                        margin: '2px 0'
                      }}
                    >
                      {count > 0 && (
                        <Text size="xs" c={isSelected ? 'white' : 'dark'}>
                          {count}
                        </Text>
                      )}
                    </Box>
                  )
                })}
              </Box>
            ))}
          </SimpleGrid>
        </div>

        <Text size="xs" c="dimmed">
          Selected: {selectedSlots.length} slots | Numbers show participant count
        </Text>
      </Stack>
    </Card>
  )
}

// Layout B: Timeline with Visual Blocks
function LayoutB() {
  const [selectedRanges, setSelectedRanges] = useState<{[key: string]: boolean}>({})

  const handleBlockClick = (dateTime: string) => {
    setSelectedRanges(prev => ({
      ...prev,
      [dateTime]: !prev[dateTime]
    }))
  }

  const getSlotCount = (dateTime: string) => {
    return SAMPLE_EVENT.responses.filter(r => r.availability.includes(dateTime)).length
  }

  return (
    <Card shadow="sm" padding="lg" radius="md" withBorder>
      <Stack gap="md">
        <Group justify="space-between">
          <Title order={3} c="green">Layout B: Timeline with Visual Blocks</Title>
          <Badge variant="light" color="green">Visual</Badge>
        </Group>
        
        <Text size="sm" c="dimmed">
          Click time blocks to select availability. Visual timeline shows overlapping responses.
        </Text>

        {SAMPLE_EVENT.possibleDates.map(date => (
          <Box key={date.date}>
            <Group mb="xs">
              <Text fw={500} size="sm">📅 {date.label}</Text>
            </Group>
            
            <Group gap={2} wrap="nowrap">
              {SAMPLE_EVENT.possibleTimes.map(time => {
                const dateTime = `${date.date}-${time}`
                const count = getSlotCount(dateTime)
                const isSelected = selectedRanges[dateTime]
                
                return (
                  <Box
                    key={dateTime}
                    onClick={() => handleBlockClick(dateTime)}
                    style={{
                      flex: 1,
                      height: 40,
                      backgroundColor: isSelected 
                        ? '#51cf66' 
                        : count > 0 
                          ? `rgba(81, 207, 102, ${count * 0.4})` 
                          : '#f8f9fa',
                      border: '1px solid #dee2e6',
                      cursor: 'pointer',
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      justifyContent: 'center',
                      borderRadius: 4,
                      transition: 'all 0.2s ease'
                    }}
                  >
                    <Text size="xs" fw={500}>
                      {time.split(' ')[0]}
                    </Text>
                    {count > 0 && (
                      <Text size="xs" c="dimmed">
                        {count}
                      </Text>
                    )}
                  </Box>
                )
              })}
            </Group>
          </Box>
        ))}

        <Text size="xs" c="dimmed">
          Timeline view | Click blocks to select | Numbers show availability overlap
        </Text>
      </Stack>
    </Card>
  )
}

// Layout C: Data Visualization Focused
function LayoutC() {
  const [participantView, setParticipantView] = useState<string[]>([])

  const handleSlotClick = (dateTime: string) => {
    setParticipantView(prev => 
      prev.includes(dateTime) 
        ? prev.filter(slot => slot !== dateTime)
        : [...prev, dateTime]
    )
  }

  const getSlotCount = (dateTime: string) => {
    return SAMPLE_EVENT.responses.filter(r => r.availability.includes(dateTime)).length
  }

  const getParticipantNames = (dateTime: string) => {
    return SAMPLE_EVENT.responses
      .filter(r => r.availability.includes(dateTime))
      .map(r => r.name)
  }

  const totalSlots = SAMPLE_EVENT.possibleDates.length * SAMPLE_EVENT.possibleTimes.length
  const popularSlots = SAMPLE_EVENT.possibleDates.flatMap(date => 
    SAMPLE_EVENT.possibleTimes.map(time => {
      const dateTime = `${date.date}-${time}`
      return { dateTime, count: getSlotCount(dateTime) }
    })
  ).filter(slot => slot.count > 0).sort((a, b) => b.count - a.count)

  return (
    <Card shadow="sm" padding="lg" radius="md" withBorder>
      <Stack gap="md">
        <Group justify="space-between">
          <Title order={3} c="orange">Layout C: Data Visualization Focused</Title>
          <Badge variant="light" color="orange">Analytics</Badge>
        </Group>
        
        <Text size="sm" c="dimmed">
          Data-driven interface showing availability analytics and response patterns.
        </Text>

        <SimpleGrid cols={3} spacing="md">
          <Box>
            <Group gap="xs" mb="xs">
              <Text size="sm" fw={500}>👥 Response Rate</Text>
            </Group>
            <Progress value={66.7} size="lg" color="blue" />
            <Text size="xs" c="dimmed" mt="xs">2 of 3 participants responded</Text>
          </Box>

          <Box>
            <Group gap="xs" mb="xs">
              <Text size="sm" fw={500}>✅ Best Options</Text>
            </Group>
            <Text size="lg" fw={700} c="green">{popularSlots.length}</Text>
            <Text size="xs" c="dimmed">time slots with overlap</Text>
          </Box>

          <Box>
            <Group gap="xs" mb="xs">
              <Text size="sm" fw={500}>🕒 Coverage</Text>
            </Group>
            <Text size="lg" fw={700} c="orange">
              {Math.round((popularSlots.length / totalSlots) * 100)}%
            </Text>
            <Text size="xs" c="dimmed">of time slots covered</Text>
          </Box>
        </SimpleGrid>

        <Divider />

        <Box>
          <Text fw={500} size="sm" mb="md">Popular Time Slots</Text>
          <Stack gap="xs">
            {popularSlots.slice(0, 4).map(slot => {
              const [date, time] = slot.dateTime.split('-')
              const dateLabel = SAMPLE_EVENT.possibleDates.find(d => d.date === date)?.label || date
              const participants = getParticipantNames(slot.dateTime)
              const isSelected = participantView.includes(slot.dateTime)
              
              return (
                <Box
                  key={slot.dateTime}
                  onClick={() => handleSlotClick(slot.dateTime)}
                  style={{
                    padding: '8px 12px',
                    backgroundColor: isSelected ? '#fff3cd' : '#f8f9fa',
                    border: '1px solid #dee2e6',
                    borderRadius: 6,
                    cursor: 'pointer'
                  }}
                >
                  <Group justify="space-between">
                    <Box>
                      <Text size="sm" fw={500}>
                        {dateLabel.split(',')[0]} at {time}
                      </Text>
                      <Text size="xs" c="dimmed">
                        Available: {participants.join(', ')}
                      </Text>
                    </Box>
                    <Badge variant="filled" color="orange" size="sm">
                      {slot.count} people
                    </Badge>
                  </Group>
                </Box>
              )
            })}
          </Stack>
        </Box>

        <Text size="xs" c="dimmed">
          Click time slots to add to your availability | Data shows real-time analytics
        </Text>
      </Stack>
    </Card>
  )
}

// Layout D: Mobile-First Compact Design
function LayoutD() {
  const [expandedDate, setExpandedDate] = useState<string | null>(null)
  const [selectedSlots, setSelectedSlots] = useState<string[]>([])

  const handleDateToggle = (date: string) => {
    setExpandedDate(expandedDate === date ? null : date)
  }

  const handleSlotTap = (dateTime: string) => {
    setSelectedSlots(prev => 
      prev.includes(dateTime) 
        ? prev.filter(slot => slot !== dateTime)
        : [...prev, dateTime]
    )
  }

  const getSlotCount = (dateTime: string) => {
    return SAMPLE_EVENT.responses.filter(r => r.availability.includes(dateTime)).length
  }

  const getDateAvailability = (date: string) => {
    const dateSlots = SAMPLE_EVENT.possibleTimes.map(time => `${date}-${time}`)
    return dateSlots.filter(slot => getSlotCount(slot) > 0).length
  }

  return (
    <Card shadow="sm" padding="lg" radius="md" withBorder>
      <Stack gap="md">
        <Group justify="space-between">
          <Title order={3} c="violet">Layout D: Mobile-First Compact</Title>
          <Badge variant="light" color="violet">Touch-Friendly</Badge>
        </Group>
        
        <Text size="sm" c="dimmed">
          Accordion-style interface optimized for mobile interaction with large touch targets.
        </Text>

        <Stack gap="xs">
          {SAMPLE_EVENT.possibleDates.map(date => {
            const availableCount = getDateAvailability(date.date)
            const isExpanded = expandedDate === date.date
            
            return (
              <Box key={date.date}>
                <Box
                  onClick={() => handleDateToggle(date.date)}
                  style={{
                    padding: '12px 16px',
                    backgroundColor: isExpanded ? '#e7f5ff' : '#f8f9fa',
                    border: '1px solid #dee2e6',
                    borderRadius: 8,
                    cursor: 'pointer',
                    transition: 'all 0.2s ease'
                  }}
                >
                  <Group justify="space-between">
                    <Box>
                      <Text fw={500}>{date.label}</Text>
                      <Text size="sm" c="dimmed">
                        {availableCount} of {SAMPLE_EVENT.possibleTimes.length} slots available
                      </Text>
                    </Box>
                    <Group gap="xs">
                      <Badge variant="light" color="blue">
                        {availableCount} available
                      </Badge>
                      <Text size="sm" c="dimmed">
                        {isExpanded ? '▼' : '▶'}
                      </Text>
                    </Group>
                  </Group>
                </Box>

                {isExpanded && (
                  <Box mt="xs" style={{ paddingLeft: 16 }}>
                    <SimpleGrid cols={2} spacing="xs">
                      {SAMPLE_EVENT.possibleTimes.map(time => {
                        const dateTime = `${date.date}-${time}`
                        const count = getSlotCount(dateTime)
                        const isSelected = selectedSlots.includes(dateTime)
                        
                        return (
                          <Box
                            key={dateTime}
                            onClick={() => handleSlotTap(dateTime)}
                            style={{
                              padding: '12px 8px',
                              backgroundColor: isSelected 
                                ? '#d0bfff' 
                                : count > 0 
                                  ? `rgba(208, 191, 255, ${count * 0.3})` 
                                  : '#ffffff',
                              border: '1px solid #dee2e6',
                              borderRadius: 6,
                              cursor: 'pointer',
                              textAlign: 'center',
                              minHeight: 48
                            }}
                          >
                            <Text size="sm" fw={500}>{time}</Text>
                            {count > 0 && (
                              <Text size="xs" c="dimmed">
                                {count} available
                              </Text>
                            )}
                          </Box>
                        )
                      })}
                    </SimpleGrid>
                  </Box>
                )}
              </Box>
            )
          })}
        </Stack>

        <Text size="xs" c="dimmed">
          Tap dates to expand | Large touch targets | Selected: {selectedSlots.length} slots
        </Text>
      </Stack>
    </Card>
  )
}

export default function EventLayoutComparison() {
  return (
    <Container size="xl" py="xl">
      <Stack gap="xl">
        <div>
          <Title order={1} mb="md">Event Response Interface Layouts</Title>
          <Text c="dimmed" mb="sm">
            Comparison of 4 different interface approaches for participant availability selection
          </Text>
          <Group gap="md">
            <Badge color="blue">Sample Event: {SAMPLE_EVENT.name}</Badge>
            <Badge variant="light">15-minute increments</Badge>
            <Badge variant="light">2 existing responses</Badge>
          </Group>
        </div>

        {/* Enhanced Layout B - Full Width */}
        <EnhancedTimelineLayout 
          eventData={SAMPLE_EVENT} 
          onSelectionChange={(selectedSlots) => {
            console.log('Selected slots:', selectedSlots)
          }}
        />

        <Grid>
          <Grid.Col span={{ base: 12, lg: 6 }}>
            <LayoutA />
          </Grid.Col>
          <Grid.Col span={{ base: 12, lg: 6 }}>
            <LayoutB />
          </Grid.Col>
          <Grid.Col span={{ base: 12, lg: 6 }}>
            <LayoutC />
          </Grid.Col>
          <Grid.Col span={{ base: 12, lg: 6 }}>
            <LayoutD />
          </Grid.Col>
        </Grid>

        <Card shadow="sm" padding="lg" radius="md" withBorder>
          <Stack gap="md">
            <Title order={3}>Layout Comparison Summary</Title>
            <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} spacing="md">
              <Box>
                <Text fw={500} c="blue" mb="xs">Layout A: Grid + Drag</Text>
                <Text size="sm" c="dimmed">
                  • Mouse/touch drag selection<br/>
                  • Dense calendar grid view<br/>
                  • Visual availability density<br/>
                  • Best for: Desktop power users
                </Text>
              </Box>
              <Box>
                <Text fw={500} c="green" mb="xs">Layout B: Timeline Blocks</Text>
                <Text size="sm" c="dimmed">
                  • Visual time blocks<br/>
                  • Clear daily organization<br/>
                  • Individual block selection<br/>
                  • Best for: Visual learners
                </Text>
              </Box>
              <Box>
                <Text fw={500} c="orange" mb="xs">Layout C: Data Focused</Text>
                <Text size="sm" c="dimmed">
                  • Analytics and insights<br/>
                  • Response rate metrics<br/>
                  • Popular slot ranking<br/>
                  • Best for: Data-driven decisions
                </Text>
              </Box>
              <Box>
                <Text fw={500} c="violet" mb="xs">Layout D: Mobile First</Text>
                <Text size="sm" c="dimmed">
                  • Accordion expansion<br/>
                  • Large touch targets<br/>
                  • Progressive disclosure<br/>
                  • Best for: Mobile devices
                </Text>
              </Box>
            </SimpleGrid>
          </Stack>
        </Card>

        <Group justify="center" gap="md">
          <Button component={Link} to="/event/sample" variant="outline">
            View Current Event Interface
          </Button>
          <Button component={Link} to="/" variant="subtle">
            Create Your Own Event
          </Button>
        </Group>
      </Stack>
    </Container>
  )
}