import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { sendMessage } from '@/api/client'
import type { ChatAttachment, ChatMessage, ChatMode } from '@/types/chat'
import { createId } from '@/utils/id'

export const useChatStore = defineStore('chat', () => {
  const messages = ref<ChatMessage[]>([])
  const isWaiting = ref(false)
  const mode = ref<ChatMode>('search')
  const sessionId = ref(createId())

  const hasMessages = computed(() => messages.value.length > 0)

  async function send(text: string, attachments: ChatAttachment[] = []) {
    const content = text.trim()
    if ((!content && !attachments.length) || isWaiting.value) return

    messages.value.push({
      id: createId(),
      role: 'user',
      content,
      attachments,
      createdAt: Date.now(),
    })

    isWaiting.value = true
    const requestSession = sessionId.value
    try {
      const res = await sendMessage(content, {
        sessionId: requestSession,
        mode: mode.value,
        attachments: attachments.flatMap((a) => (a.file ? [a.file] : [])),
      })
      // Ignore replies for a thread that was reset while waiting.
      if (requestSession !== sessionId.value) return
      messages.value.push({
        id: createId(),
        role: 'assistant',
        content: res.reply,
        suggestions: res.suggestions,
        createdAt: Date.now(),
      })
    } catch (err) {
      if (requestSession !== sessionId.value) return
      messages.value.push({
        id: createId(),
        role: 'assistant',
        content: err instanceof Error ? err.message : 'Something went wrong. Please try again.',
        status: 'error',
        createdAt: Date.now(),
      })
    } finally {
      if (requestSession === sessionId.value) isWaiting.value = false
    }
  }

  function newThread() {
    messages.value = []
    isWaiting.value = false
    sessionId.value = createId()
  }

  return { messages, isWaiting, mode, sessionId, hasMessages, send, newThread }
})
