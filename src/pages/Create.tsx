import { Container, Title, Text, TextInput, Textarea, Button, Stack, Card, Group } from '@mantine/core'
import { Link } from 'react-router-dom'
import { useState } from 'react'

export default function Create() {
  const [eventName, setEventName] = useState('')
  const [eventDescription, setEventDescription] = useState('')
  const [isCreating, setIsCreating] = useState(false)

  const handleCreateEvent = () => {
    if (!eventName.trim()) return
    setIsCreating(true)
    
    // Simulate event creation
    setTimeout(() => {
      setIsCreating(false)
      // In real app, this would redirect to the actual event URL
      const descriptionText = eventDescription.trim() ? `\nDescription: ${eventDescription}` : ''
      alert(`Event "${eventName}" created!${descriptionText}\nURL: /event/sample-${eventName.toLowerCase().replace(/\s+/g, '-')}`)
    }, 1000)
  }

  return (
    <Container size="md" py="xl">
      <Stack gap="xl">
        <div>
          <Title order={1} mb="md">Create New Event</Title>
          <Text c="dimmed">Set up a new scheduling event for your group</Text>
        </div>

        <Card shadow="sm" padding="lg" radius="md" withBorder>
          <Stack gap="lg">
            <TextInput
              label="Event Name"
              placeholder="Team lunch, Project meeting, Birthday party..."
              value={eventName}
              onChange={(e) => setEventName(e.target.value)}
              required
            />

            <Textarea
              label="Event Description"
              placeholder="Add details about your event (optional)"
              value={eventDescription}
              onChange={(e) => setEventDescription(e.target.value)}
              minRows={3}
            />

            <Group justify="space-between">
              <Button 
                component={Link} 
                to="/" 
                variant="subtle"
              >
                Back to Home
              </Button>
              
              <Button 
                onClick={handleCreateEvent}
                disabled={!eventName.trim() || isCreating}
                loading={isCreating}
              >
                {isCreating ? 'Creating Event...' : 'Create Event'}
              </Button>
            </Group>
          </Stack>
        </Card>

        <Group justify="center">
          <Text size="sm" c="dimmed">
            Want to try it out? <Button 
              component={Link} 
              to="/event/sample-team-lunch"
              variant="subtle"
              size="compact-xs"
              p={0}
              style={{ textDecoration: 'underline' }}
            >
              View demo event
            </Button>
          </Text>
        </Group>
      </Stack>
    </Container>
  )
}