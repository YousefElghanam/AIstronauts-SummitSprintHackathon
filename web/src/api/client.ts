import type { ApplicationForm } from '@/types/application'
import type { ChatMode, ChatRole } from '@/types/chat'
import { mockChat, mockSubmit } from './mock'
import { createForm } from './mock/studentVisa'

export interface ChatResponse {
  reply: string
  suggestions?: string[]
  form?: ApplicationForm
  intent?: string
}

export interface SubmitResponse {
  reply: string
  reference: string
}

export interface SendMessageOptions {
  mode?: ChatMode
  history?: { role: ChatRole; content: string }[]
}

// On/off switch for the real AI (costs tokens). Set VITE_AI_ENABLED=true in web/.env to use Gemini.
export const AI_ENABLED = import.meta.env.VITE_AI_ENABLED === 'true'
const API_URL = import.meta.env.VITE_API_URL ?? ''

// Shape returned by POST /api/chat (see web/server/geminiChat.ts).
interface AiChatResponse {
  reply: string
  suggestions: string[]
  intent: 'student_visa_renewal' | 'none'
  openForm: boolean
}

export async function sendMessage(message: string, options: SendMessageOptions = {}): Promise<ChatResponse> {
  const { mode = 'ask', history = [] } = options
  if (!AI_ENABLED) return mockChat(message, mode)

  const res = await fetch(`${API_URL}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message, mode, history }),
  })
  const data = await res.json().catch(() => null)
  if (!res.ok || !data) throw new Error(data?.error ?? `API error ${res.status}`)

  const ai = data as AiChatResponse
  return {
    reply: ai.reply,
    suggestions: ai.suggestions,
    intent: ai.intent,
    // The AI decides *when* to open the form; the form itself is defined in code.
    form: ai.openForm && ai.intent === 'student_visa_renewal' ? createForm() : undefined,
  }
}

// Signing and submitting to the authority is simulated until a real government API exists.
export async function submitApplication(form: ApplicationForm): Promise<SubmitResponse> {
  return mockSubmit(form)
}
