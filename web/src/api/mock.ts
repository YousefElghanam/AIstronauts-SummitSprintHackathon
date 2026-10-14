import type { ChatResponse } from './client'

const delay = (ms: number) => new Promise((r) => setTimeout(r, ms))

const SUGGESTION_POOL = [
  'Fill in the form for me',
  'Sign and submit it with ID Austria',
  'Which documents do I need to bring?',
  'Can I do this online on oesterreich.gv.at?',
  'Book an appointment at my Magistrat or Bezirkshauptmannschaft',
  'What does it cost?',
  'What is the deadline?',
  'Remind me before the deadline',
  'Show the status of my application',
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
