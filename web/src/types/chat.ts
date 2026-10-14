export type ChatRole = 'user' | 'assistant'

export type ChatMode = 'search' | 'research'

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
  status?: 'error'
}
