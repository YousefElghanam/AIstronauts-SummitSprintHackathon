import { ApiError, GoogleGenAI } from '@google/genai'
import { buildSystemPrompt } from './prompt.ts'

// Shared by the Vite dev server (server/geminiChat.ts) and the Cloudflare Worker (worker/index.ts).

export const DEFAULT_MODEL = 'gemini-flash-latest'
// Used when the main model stays overloaded (503) or rate-limited (429).
const FALLBACK_MODEL = 'gemini-flash-lite-latest'

export interface ChatRequest {
  message: string
  mode?: 'ask' | 'task'
  history?: { role: 'user' | 'assistant'; content: string }[]
}

// Gemini must answer in this shape so the UI can render it.
const RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    reply: { type: 'string' },
    suggestions: { type: 'array', items: { type: 'string' } },
    intent: { type: 'string', enum: ['student_visa_renewal', 'none'] },
    openForm: { type: 'boolean' },
  },
  required: ['reply', 'suggestions', 'intent', 'openForm'],
}

const isOverloaded = (err: unknown) => err instanceof ApiError && (err.status === 503 || err.status === 429)

// Gemini is sometimes briefly overloaded: retry once, then switch to the next model.
async function withFallback<T>(models: string[], call: (model: string) => Promise<T>): Promise<T> {
  let lastError: unknown
  for (const model of models) {
    for (let attempt = 1; attempt <= 2; attempt++) {
      try {
        return await call(model)
      } catch (err) {
        if (!isOverloaded(err)) throw err
        lastError = err
        await new Promise((r) => setTimeout(r, 800 * attempt))
      }
    }
  }
  throw lastError
}

/** Sends one chat turn to Gemini and returns its JSON answer. */
export async function handleChat(ai: GoogleGenAI, model: string, body: ChatRequest): Promise<unknown> {
  const { message, mode = 'ask', history = [] } = body

  const models = [...new Set([model, FALLBACK_MODEL])]
  const response = await withFallback(models, (model) =>
    ai.models.generateContent({
      model,
      contents: [
        ...history.map((m) => ({
          role: m.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: m.content }],
        })),
        { role: 'user', parts: [{ text: message }] },
      ],
      config: {
        systemInstruction: buildSystemPrompt(mode),
        responseMimeType: 'application/json',
        responseJsonSchema: RESPONSE_SCHEMA,
      },
    }),
  )

  return JSON.parse(response.text ?? '{}')
}
