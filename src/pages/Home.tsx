import { Container, Title, Text, Button, Stack } from '@mantine/core'
import { Link } from 'react-router-dom'

export default function Home() {
  return (
    <Container size="md" py="xl">
      <Stack align="center" gap="xl">
        <Title order={1} ta="center">
          Availably
        </Title>
        
        <Text size="lg" ta="center" c="dimmed" maw={600}>
          Find the perfect time for your group to meet. No accounts, no hassle, 
          just simple scheduling that works.
        </Text>

        <Button 
          component={Link} 
          to="/create" 
          size="lg"
          variant="filled"
        >
          Create New Event
        </Button>

        <Stack gap="md" mt="xl">
          <Text size="sm" fw={500}>How it works:</Text>
          <Text size="sm" c="dimmed">1. Create an event with possible dates and times</Text>
          <Text size="sm" c="dimmed">2. Share the link with your group</Text>
          <Text size="sm" c="dimmed">3. Everyone adds their availability</Text>
          <Text size="sm" c="dimmed">4. See when everyone is free!</Text>
        </Stack>
      </Stack>
    </Container>
  )
}