import React, { useState } from 'react'
import { Card, Text, Stack, Button, Group, Badge, Collapse, useComputedColorScheme } from '@mantine/core'
import type { OptimalTimeRange } from '../utils/timeRangeAnalysis'
import { getBestTimeColors, validateBestTimesColors } from '../utils/colorSystem'

interface BestTimesCardProps {
  ranges: OptimalTimeRange[]
  hasPreview?: boolean
  maxVisible?: number
}

export const BestTimesCard: React.FC<BestTimesCardProps> = ({
  ranges,
  hasPreview = false,
  maxVisible = 3
}) => {
  const [showAll, setShowAll] = useState(false)
  const computedColorScheme = useComputedColorScheme('light', { getInitialValueInEffect: false })
  const isDarkTheme = computedColorScheme === 'dark'

  // Validate colors on mount (development only)
  React.useEffect(() => {
    if (import.meta.env.DEV) {
      const validation = validateBestTimesColors()
      if (!validation.light || !validation.dark) {
        console.warn('Best Times color scheme validation failed:', validation)
      }
    }
  }, [])

  const visibleRanges = showAll ? ranges.slice(0, 10) : ranges.slice(0, maxVisible)
  const remainingCount = Math.min(ranges.length - maxVisible, 10 - maxVisible)
  const hasMore = ranges.length > maxVisible && !showAll

  if (ranges.length === 0) {
    return (
      <Card shadow="sm" padding="lg" radius="md" withBorder>
        <Stack gap="md">
          <Group justify="space-between" align="center">
            <Text fw={600} size="lg">Best Times</Text>
          </Group>
          <Text size="sm" c="dimmed">
            Time ranges when most people are available
          </Text>
          <Text size="sm" c="dimmed" style={{ fontStyle: 'italic' }}>
            No overlapping availability found. Add more responses to see optimal times.
          </Text>
        </Stack>
      </Card>
    )
  }

  return (
    <Card shadow="sm" padding="lg" radius="md" withBorder>
      <Stack gap="md">
        <Group justify="space-between" align="center">
          <Text fw={600} size="lg">Best Times</Text>
          {hasPreview && (
            <Badge size="xs" variant="light" color="teal">
              Includes Your Responses
            </Badge>
          )}
        </Group>
        
        <Text size="sm" c="dimmed">
          Time ranges when most people are available
          {hasPreview && " (including your current selection)"}
        </Text>

        <Stack gap="xs">
          {visibleRanges.map((range, index) => {
            const colors = getBestTimeColors(index, isDarkTheme, range.hasPreview || false)
            
            return (
              <Card
                key={`${range.date}-${range.startTime}`}
                padding="sm"
                radius="md"
                style={{
                  backgroundColor: colors.backgroundColor,
                  borderLeft: range.hasPreview ? `3px solid ${colors.borderColor}` : 'none',
                  transition: 'all 0.2s ease'
                }}
              >
                <Stack gap={2}>
                  <Text 
                    size="sm" 
                    fw={600} 
                    style={{ color: colors.color }}
                  >
                    {range.dayLabel}
                  </Text>
                  <Text 
                    size="xs" 
                    c="dimmed"
                  >
                    {range.startTime}–{range.endTime}
                  </Text>
                  <Group gap="xs" align="center">
                    <Text 
                      size="xs" 
                      fw={500}
                      style={{ color: colors.color }}
                    >
                      {range.attendeeCount} people available
                    </Text>
                    {range.hasPreview && range.previewDelta !== undefined && range.previewDelta !== 0 && (
                      <Badge 
                        size="xs" 
                        variant="light" 
                        color={range.previewDelta > 0 ? "teal" : "orange"}
                      >
                        {range.previewDelta > 0 ? '+' : ''}{range.previewDelta}
                      </Badge>
                    )}
                  </Group>
                </Stack>
              </Card>
            )
          })}
        </Stack>

        {hasMore && (
          <Button
            variant="subtle"
            size="xs"
            onClick={() => setShowAll(true)}
            style={{ alignSelf: 'flex-start' }}
          >
            Show More Times ({remainingCount} more)
          </Button>
        )}

        {showAll && ranges.length > maxVisible && (
          <Collapse in={showAll} transitionDuration={200}>
            <Stack gap="xs">
              {ranges.slice(maxVisible, 10).map((range, index) => {
                const actualIndex = index + maxVisible
                const colors = getBestTimeColors(actualIndex, isDarkTheme, range.hasPreview || false)
                
                return (
                  <Card
                    key={`${range.date}-${range.startTime}`}
                    padding="sm"
                    radius="md"
                    style={{
                      backgroundColor: colors.backgroundColor,
                      borderLeft: range.hasPreview ? `3px solid ${colors.borderColor}` : 'none',
                      transition: 'all 0.2s ease'
                    }}
                  >
                    <Stack gap={2}>
                      <Text 
                        size="sm" 
                        fw={600} 
                        style={{ color: colors.color }}
                      >
                        {range.dayLabel}
                      </Text>
                      <Text 
                        size="xs" 
                        c="dimmed"
                      >
                        {range.startTime}–{range.endTime}
                      </Text>
                      <Group gap="xs" align="center">
                        <Text 
                          size="xs" 
                          fw={500}
                          style={{ color: colors.color }}
                        >
                          {range.attendeeCount} people available
                        </Text>
                        {range.hasPreview && range.previewDelta !== undefined && range.previewDelta !== 0 && (
                          <Badge 
                            size="xs" 
                            variant="light" 
                            color={range.previewDelta > 0 ? "teal" : "orange"}
                          >
                            {range.previewDelta > 0 ? '+' : ''}{range.previewDelta}
                          </Badge>
                        )}
                      </Group>
                    </Stack>
                  </Card>
                )
              })}
            </Stack>
          </Collapse>
        )}

        {showAll && (
          <Button
            variant="subtle"
            size="xs"
            onClick={() => setShowAll(false)}
            style={{ alignSelf: 'flex-start' }}
          >
            Show Fewer Times
          </Button>
        )}
      </Stack>
    </Card>
  )
}

export default BestTimesCard