import type { IncomingMessage } from 'node:http'
import type { Plugin } from 'vite'
import { GoogleGenAI } from '@google/genai'
import { DEFAULT_MODEL, handleChat, type ChatRequest } from './chat.ts'

async function readJson<T>(req: IncomingMessage): Promise<T> {
  const chunks: Buffer[] = []
  for await (const chunk of req) chunks.push(chunk as Buffer)
  return JSON.parse(Buffer.concat(chunks).toString('utf8')) as T
}

/**
 * Dev-server endpoint `POST /api/chat` that calls Gemini.
 * The API key stays on the server (never shipped to the browser).
 * In production the same endpoint is served by the Cloudflare Worker (worker/index.ts).
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
          send(200, await handleChat(ai, model, await readJson<ChatRequest>(req)))
        } catch (err) {
          server.config.logger.error(`[gemini-chat] ${err instanceof Error ? err.message : String(err)}`)
          send(502, { error: 'The AI service failed. Please try again.' })
        }
      })
    },
  }
}
