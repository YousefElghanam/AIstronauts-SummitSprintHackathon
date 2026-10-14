import type { ChatMode } from '@/types/chat'
import { mockChat } from './mock'

export interface Source { title: string; url: string }
export interface ChatResponse {
  reply: string
  suggestions?: string[]
  intent?: string
  confidence?: number
  missingFields?: string[]
  workflow?: { service: string; currentStep: number; totalSteps: number }
  sources?: Source[]
}

export interface SendMessageOptions {
  sessionId?: string
  mode?: ChatMode
  attachments?: File[]
}

const USE_MOCK = import.meta.env.VITE_USE_MOCK !== 'false'
const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:3333'

export async function sendMessage(message: string, options: SendMessageOptions = {}): Promise<ChatResponse> {
  if (USE_MOCK) return mockChat(message)

  const { sessionId, mode, attachments = [] } = options
  let init: RequestInit

  if (attachments.length) {
    const body = new FormData()
    body.append('message', message)
    if (sessionId) body.append('sessionId', sessionId)
    if (mode) body.append('mode', mode)
    attachments.forEach((file) => body.append('attachments', file))
    init = { method: 'POST', body }
  } else {
    init = {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message, sessionId, mode }),
    }
  }

  const res = await fetch(`${API_URL}/api/chat`, init)
  if (!res.ok) throw new Error(`API error ${res.status}`)
  return res.json()
}
