export interface EventResponse {
  name: string
  availability: string[]
}

export interface EventData {
  name: string
  description?: string
  possibleDates: Array<{ date: string; label: string }>
  possibleTimes: string[]
  responses: EventResponse[]
}