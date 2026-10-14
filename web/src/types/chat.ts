import type { ApplicationForm } from './application'

export type ChatRole = 'user' | 'assistant'

// ask: explain a public service · task: complete it on the user's behalf (ID Austria)
export type ChatMode = 'ask' | 'task'

export interface ChatAttachment {
  id: string
  name: string
  size: number
  type: string
  file?: File
}

export interface ChatMessage {
  id: string
  role: ChatRole
  content: string
  createdAt: number
  attachments?: ChatAttachment[]
  suggestions?: string[]
  form?: ApplicationForm
  status?: 'error'
}
