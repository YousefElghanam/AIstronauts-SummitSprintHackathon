import type { ApplicationForm } from '@/types/application'
import type { ChatMode } from '@/types/chat'
import { mockChat, mockSubmit } from './mock'

export interface Source { title: string; url: string }
export interface ChatResponse {
  reply: string
  suggestions?: string[]
  form?: ApplicationForm
  intent?: string
  confidence?: number
  missingFields?: string[]
  workflow?: { service: string; currentStep: number; totalSteps: number }
  sources?: Source[]
}

export interface SubmitResponse {
  reply: string
  reference: string
}

export interface SendMessageOptions {
  sessionId?: string
  mode?: ChatMode
  attachments?: File[]
}

const USE_MOCK = import.meta.env.VITE_USE_MOCK !== 'false'
const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:3333'

export async function sendMessage(message: string, options: SendMessageOptions = {}): Promise<ChatResponse> {
  const { sessionId, mode = 'ask', attachments = [] } = options
  if (USE_MOCK) return mockChat(message, mode)

  let init: RequestInit

  if (attachments.length) {
    const body = new FormData()
    body.append('message', message)
    if (sessionId) body.append('sessionId', sessionId)
    body.append('mode', mode)
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

// Signs (via the user's ID Austria session) and submits a completed application.
export async function submitApplication(form: ApplicationForm, sessionId?: string): Promise<SubmitResponse> {
  if (USE_MOCK) return mockSubmit(form)

  const body = new FormData()
  if (sessionId) body.append('sessionId', sessionId)
  body.append('formId', form.id)
  body.append('fields', JSON.stringify(Object.fromEntries(form.fields.map((f) => [f.id, f.value]))))
  form.documents.forEach((doc) => {
    if (doc.file?.file) body.append(`documents[${doc.id}]`, doc.file.file)
  })

  const res = await fetch(`${API_URL}/api/applications`, { method: 'POST', body })
  if (!res.ok) throw new Error(`API error ${res.status}`)
  return res.json()
}
