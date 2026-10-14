import type { ApplicationForm } from '@/types/application'
import type { ChatMode } from '@/types/chat'
import type { ChatResponse, SubmitResponse } from '../client'
import * as studentVisa from './studentVisa'

const delay = (ms: number) => new Promise((r) => setTimeout(r, ms))

// Placeholder until the real API is wired up.
export async function mockChat(message: string, mode: ChatMode): Promise<ChatResponse> {
  await delay(1200 + Math.random() * 800)
  const text = message.trim()

  const followUp = studentVisa.FOLLOW_UPS[text]
  if (followUp) {
    return {
      reply: followUp,
      intent: 'student_visa_renewal',
      suggestions: studentVisa.ASK_SUGGESTIONS.filter((q) => q !== text),
    }
  }

  if (text === studentVisa.PREPARE_PROMPT || (mode === 'task' && studentVisa.PATTERN.test(text))) {
    return {
      reply: studentVisa.FORM_INTRO,
      intent: 'student_visa_renewal',
      form: studentVisa.createForm(),
    }
  }

  if (studentVisa.PATTERN.test(text)) {
    return {
      reply: studentVisa.PROCESS,
      intent: 'student_visa_renewal',
      suggestions: studentVisa.ASK_SUGGESTIONS,
    }
  }

  return {
    reply: 'Right now I can help you renew your student residence permit. More services are coming soon.',
    suggestions: ['How do I renew my student visa?'],
  }
}

export async function mockSubmit(form: ApplicationForm): Promise<SubmitResponse> {
  await delay(1500)
  const reference = `MA35-${new Date().getFullYear()}-${Math.floor(10000 + Math.random() * 90000)}`
  return { reference, reply: studentVisa.submittedReply(form, reference) }
}
