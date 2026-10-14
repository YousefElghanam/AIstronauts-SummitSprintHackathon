import { GoogleGenAI } from '@google/genai'
import { DEFAULT_MODEL, handleChat, type ChatRequest } from '../server/chat.ts'

// Cloudflare Worker: serves POST /api/chat. Everything else is the built Vue app (dist/),
// served by Workers Static Assets (see wrangler.jsonc).

interface Env {
  ASSETS: Fetcher
  GEMINI_API_KEY?: string
  GEMINI_MODEL?: string
}

export default {
  async fetch(req, env): Promise<Response> {
    const { pathname } = new URL(req.url)
    if (pathname !== '/api/chat') return env.ASSETS.fetch(req)

    if (req.method !== 'POST') return Response.json({ error: 'Method not allowed' }, { status: 405 })
    if (!env.GEMINI_API_KEY) {
      return Response.json({ error: 'GEMINI_API_KEY is not set (npx wrangler secret put GEMINI_API_KEY)' }, { status: 500 })
    }

    try {
      const ai = new GoogleGenAI({ apiKey: env.GEMINI_API_KEY })
      const body = await req.json<ChatRequest>()
      return Response.json(await handleChat(ai, env.GEMINI_MODEL || DEFAULT_MODEL, body))
    } catch (err) {
      console.error(`[gemini-chat] ${err instanceof Error ? err.message : String(err)}`)
      return Response.json({ error: 'The AI service failed. Please try again.' }, { status: 502 })
    }
  },
} satisfies ExportedHandler<Env>
