/**
 * Preview Response Utilities for Real-Time Updates
 * 
 * This module provides utilities for creating and managing preview responses
 * that show real-time user selections before they submit their availability.
 */

import type { EventResponse } from '../types/event'

/**
 * Generate a preview response from user's current selections
 * 
 * @param name - User's name (defaults to "You" if empty)
 * @param selections - Array of selected time slot strings
 * @returns EventResponse object marked as preview
 */
export const generatePreviewResponse = (
  name: string, 
  selections: string[]
): EventResponse => ({
  name: name.trim() || 'You',
  availability: selections,
  isPreview: true,
  isTemporary: true,
  timestamp: new Date()
})

/**
 * Combine existing responses with preview response
 * 
 * @param responses - Array of existing submitted responses
 * @param previewSelections - User's current selections
 * @param userName - User's name for preview
 * @returns Combined array with preview response added
 */
export const combineResponsesWithPreview = (
  responses: EventResponse[],
  previewSelections: string[],
  userName: string
): EventResponse[] => {
  if (previewSelections.length === 0) {
    return responses
  }
  
  const previewResponse = generatePreviewResponse(userName, previewSelections)
  return [...responses, previewResponse]
}

/**
 * Filter out preview responses from response array
 * 
 * @param responses - Array of responses including potential previews
 * @returns Array with only submitted (non-preview) responses
 */
export const filterSubmittedResponses = (responses: EventResponse[]): EventResponse[] => {
  return responses.filter(response => !response.isPreview)
}

/**
 * Get only preview responses from response array
 * 
 * @param responses - Array of responses including potential previews
 * @returns Array with only preview responses
 */
export const getPreviewResponses = (responses: EventResponse[]): EventResponse[] => {
  return responses.filter(response => response.isPreview)
}

/**
 * Format preview response name for display
 * 
 * @param response - EventResponse object
 * @returns Formatted name with preview indicator
 */
export const formatPreviewName = (response: EventResponse): string => {
  if (!response.isPreview) {
    return response.name
  }
  
  return `${response.name} (Preview)`
}

/**
 * Check if user has active preview selections
 * 
 * @param responses - Array of responses to check
 * @returns True if there are active preview responses
 */
export const hasActivePreview = (responses: EventResponse[]): boolean => {
  return responses.some(response => response.isPreview && response.availability.length > 0)
}

/**
 * Get preview selection count for display
 * 
 * @param responses - Array of responses to check
 * @returns Number of selected time slots in preview, or 0 if no preview
 */
export const getPreviewSelectionCount = (responses: EventResponse[]): number => {
  const previewResponse = responses.find(response => response.isPreview)
  return previewResponse?.availability.length ?? 0
}

export default {
  generatePreviewResponse,
  combineResponsesWithPreview,
  filterSubmittedResponses,
  getPreviewResponses,
  formatPreviewName,
  hasActivePreview,
  getPreviewSelectionCount
}