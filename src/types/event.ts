export interface EventResponse {
  name: string
  availability: string[]
  isPreview?: boolean
  isTemporary?: boolean
  timestamp?: Date
}

export interface EventData {
  name: string
  description?: string
  possibleDates: Array<{ date: string; label: string }>
  possibleTimes: string[]
  responses: EventResponse[]
}