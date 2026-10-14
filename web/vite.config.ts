import tailwindcss from '@tailwindcss/vite'
import { fileURLToPath, URL } from 'node:url'

import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'
import { geminiChat } from './server/geminiChat.ts'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // '' prefix loads non-VITE_ vars too (server-only, never exposed to the browser).
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [
      tailwindcss(),
      vue(),
      vueDevTools(),
      geminiChat(env.GEMINI_API_KEY, env.GEMINI_MODEL || undefined),
    ],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
      },
    },
  }
})
