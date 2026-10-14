import type { IconName } from '@/components/ui/icons'

export const APP_NAME = 'Ombrion AI'

// Placeholder until auth exists.
export const USER_NAME = 'Armando'

export interface Topic {
  label: string
  icon: IconName
  prompt: string
}

export const TOPICS: Topic[] = [
  { label: 'Parenting', icon: 'users', prompt: 'What do I need to register my newborn?' },
  { label: 'Current Events', icon: 'globe', prompt: 'What changed in public services this month?' },
  { label: 'Health', icon: 'heart', prompt: 'How do I renew my health insurance card?' },
  { label: 'Research', icon: 'flask', prompt: 'Explain this official document in plain language: ' },
  { label: 'Sports', icon: 'activity', prompt: 'How do I register a local sports club?' },
]
