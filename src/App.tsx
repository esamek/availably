import { Routes, Route } from 'react-router-dom'
import { AppShell, Container, Group, Text, Anchor } from '@mantine/core'
import { Link } from 'react-router-dom'
import Home from './pages/Home'
import Create from './pages/Create'
import Event from './pages/Event'
import About from './pages/About'
import EventLayoutComparison from './pages/EventLayoutComparison'

function App() {
  return (
    <AppShell
      header={{ height: 60 }}
      padding="md"
    >
      <AppShell.Header>
        <Container size="xl" h="100%">
          <Group h="100%" justify="space-between">
            <Text size="lg" fw={600} component={Link} to="/" style={{ textDecoration: 'none', color: 'inherit' }}>
              Availably
            </Text>
            <Group gap="md">
              <Anchor component={Link} to="/about" size="sm">
                About
              </Anchor>
            </Group>
          </Group>
        </Container>
      </AppShell.Header>

      <AppShell.Main>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/create" element={<Create />} />
          <Route path="/event/:eventId" element={<Event />} />
          <Route path="/event/sample/layouts" element={<EventLayoutComparison />} />
          <Route path="/about" element={<About />} />
        </Routes>
      </AppShell.Main>
    </AppShell>
  )
}

export default App
