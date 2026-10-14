import type { ChatResponse } from './client'

const delay = (ms: number) => new Promise((r) => setTimeout(r, ms))

const SUGGESTION_POOL = [
  'What documents do I need to bring?',
  'How long does the process take?',
  'Can I do this online instead?',
  'Is there a fee for this service?',
  'What is the deadline?',
  'Who can I contact if I get stuck?',
  'Can someone else do this on my behalf?',
]

function pickSuggestions(count: number): string[] {
  return [...SUGGESTION_POOL].sort(() => Math.random() - 0.5).slice(0, count)
}

// Placeholder until the real API is wired up: answers everything with "Good job!".
export async function mockChat(_message: string): Promise<ChatResponse> {
  await delay(1200 + Math.random() * 800)
  return {
    reply: 'Good job!',
    suggestions: pickSuggestions(3),
  }
}
