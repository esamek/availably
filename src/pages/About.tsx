import { Container, Title, Text, Stack, Button } from '@mantine/core'
import { Link } from 'react-router-dom'

export default function About() {
  return (
    <Container size="md" py="xl">
      <Stack gap="lg">
        <Title order={1}>About Availably</Title>
        
        <Text>
          Availably makes group scheduling simple and friction-free. No accounts required,
          no complex interfaces - just easy coordination for when your group can meet.
        </Text>

        <Title order={2} size="h3">How It Works</Title>
        <Text>
          Create an event, define possible meeting times, and share a link with your group.
          Everyone can quickly add their availability and see when others are free.
        </Text>

        <Title order={2} size="h3">Privacy</Title>
        <Text>
          We collect minimal data and don't require user accounts. Events automatically
          expire after completion to protect your privacy.
        </Text>

        <Button 
          component={Link} 
          to="/" 
          variant="subtle"
          mt="xl"
        >
          Back to Home
        </Button>
      </Stack>
    </Container>
  )
}