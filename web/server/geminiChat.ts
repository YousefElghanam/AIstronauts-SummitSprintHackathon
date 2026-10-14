import type { IncomingMessage } from 'node:http'
import type { Plugin } from 'vite'
import { ApiError, GoogleGenAI } from '@google/genai'
import { buildSystemPrompt } from './prompt.ts'

const DEFAULT_MODEL = 'gemini-flash-latest'
// Used when the main model stays overloaded (503) or rate-limited (429).
const FALLBACK_MODEL = 'gemini-flash-lite-latest'

interface ChatRequest {
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

async function readJson<T>(req: IncomingMessage): Promise<T> {
  const chunks: Buffer[] = []
  for await (const chunk of req) chunks.push(chunk as Buffer)
  return JSON.parse(Buffer.concat(chunks).toString('utf8')) as T
}

/**
 * Dev-server endpoint `POST /api/chat` that calls Gemini.
 * The API key stays on the server (never shipped to the browser).
 */
export function geminiChat(apiKey: string | undefined, model = DEFAULT_MODEL): Plugin {
  return {
    name: 'gemini-chat',
    configureServer(server) {
      const ai = apiKey ? new GoogleGenAI({ apiKey }) : null

      server.middlewares.use('/api/chat', async (req, res) => {
        const send = (status: number, body: unknown) => {
          res.statusCode = status
          res.setHeader('Content-Type', 'application/json')
          res.end(JSON.stringify(body))
        }

        if (req.method !== 'POST') return send(405, { error: 'Method not allowed' })
        if (!ai) return send(500, { error: 'GEMINI_API_KEY is not set in web/.env' })

        try {
          const { message, mode = 'ask', history = [] } = await readJson<ChatRequest>(req)

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

          send(200, JSON.parse(response.text ?? '{}'))
        } catch (err) {
          server.config.logger.error(`[gemini-chat] ${err instanceof Error ? err.message : String(err)}`)
          send(502, { error: 'The AI service failed. Please try again.' })
        }
      })
    },
  }
}
