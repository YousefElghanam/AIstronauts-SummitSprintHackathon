import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { sendMessage, submitApplication } from '@/api/client'
import type { ApplicationForm } from '@/types/application'
import type { ChatAttachment, ChatMessage, ChatMode } from '@/types/chat'
import { createId } from '@/utils/id'

export const useChatStore = defineStore('chat', () => {
  const messages = ref<ChatMessage[]>([])
  const isWaiting = ref(false)
  const mode = ref<ChatMode>('ask')
  const sessionId = ref(createId())

  const hasMessages = computed(() => messages.value.length > 0)

  function addMessage(message: Omit<ChatMessage, 'id' | 'createdAt'>) {
    messages.value.push({ id: createId(), createdAt: Date.now(), ...message })
  }

  function addError(err: unknown) {
    addMessage({
      role: 'assistant',
      content: err instanceof Error ? err.message : 'Something went wrong. Please try again.',
      status: 'error',
    })
  }

  // Runs a request while showing the waiting state; drops the result if the thread was reset meanwhile.
  async function withWaiting(request: () => Promise<void>, onError?: () => void) {
    isWaiting.value = true
    const requestSession = sessionId.value
    const isCurrent = () => requestSession === sessionId.value
    try {
      await request()
    } catch (err) {
      if (!isCurrent()) return
      onError?.()
      addError(err)
    } finally {
      if (isCurrent()) isWaiting.value = false
    }
  }

  async function send(text: string, attachments: ChatAttachment[] = []) {
    const content = text.trim()
    if ((!content && !attachments.length) || isWaiting.value) return

    // Earlier turns give the AI context (errors excluded, last 20 messages).
    const history = messages.value
      .filter((m) => m.status !== 'error' && m.content)
      .slice(-20)
      .map(({ role, content }) => ({ role, content }))

    addMessage({ role: 'user', content, attachments })

    // The AI only sees file names for now, not file contents.
    const fileNote = attachments.length ? `\n(Attached: ${attachments.map((a) => a.name).join(', ')})` : ''

    const requestSession = sessionId.value
    await withWaiting(async () => {
      const res = await sendMessage(content + fileNote, { mode: mode.value, history })
      if (requestSession !== sessionId.value) return
      addMessage({ role: 'assistant', content: res.reply, suggestions: res.suggestions, form: res.form })
    })
  }

  async function submitForm(messageId: string, form: ApplicationForm) {
    const message = messages.value.find((m) => m.id === messageId)
    if (!message?.form || isWaiting.value) return

    message.form = { ...form, status: 'submitting' }
    const requestSession = sessionId.value
    await withWaiting(
      async () => {
        const res = await submitApplication(form)
        if (requestSession !== sessionId.value) return
        message.form = { ...form, status: 'submitted', reference: res.reference }
        addMessage({ role: 'assistant', content: res.reply })
      },
      () => (message.form = { ...form, status: 'draft' }),
    )
  }

  function newThread() {
    messages.value = []
    isWaiting.value = false
    sessionId.value = createId()
  }

  return { messages, isWaiting, mode, sessionId, hasMessages, send, submitForm, newThread }
})
