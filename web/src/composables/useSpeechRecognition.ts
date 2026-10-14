import { onBeforeUnmount, ref } from 'vue'

// Minimal typing for the Web Speech API (not fully covered by lib.dom).
interface SpeechResult {
  isFinal: boolean
  0?: { transcript: string }
}
interface SpeechResultEvent {
  resultIndex: number
  results: ArrayLike<SpeechResult>
}
interface SpeechRecognitionLike {
  lang: string
  continuous: boolean
  interimResults: boolean
  start(): void
  stop(): void
  abort(): void
  onresult: ((event: SpeechResultEvent) => void) | null
  onerror: ((event: { error: string }) => void) | null
  onend: (() => void) | null
}
type SpeechRecognitionCtor = new () => SpeechRecognitionLike

function getRecognitionCtor(): SpeechRecognitionCtor | undefined {
  if (typeof window === 'undefined') return undefined
  const w = window as unknown as {
    SpeechRecognition?: SpeechRecognitionCtor
    webkitSpeechRecognition?: SpeechRecognitionCtor
  }
  return w.SpeechRecognition ?? w.webkitSpeechRecognition
}

interface Options {
  lang?: string
  onResult?: (text: string) => void
  onEnd?: () => void
}

export function useSpeechRecognition(options: Options = {}) {
  const Ctor = getRecognitionCtor()
  const isSupported = Boolean(Ctor)
  const isListening = ref(false)
  const interim = ref('')
  const error = ref<string | null>(null)
  let recognition: SpeechRecognitionLike | null = null

  function start() {
    if (recognition) return
    error.value = null
    interim.value = ''
    isListening.value = true
    // Without browser support we still show the listening state (UI only).
    if (!Ctor) return

    recognition = new Ctor()
    recognition.lang = options.lang ?? navigator.language
    recognition.continuous = true
    recognition.interimResults = true

    recognition.onresult = (event) => {
      let pending = ''
      for (let i = event.resultIndex; i < event.results.length; i++) {
        const result = event.results[i]
        const text = result?.[0]?.transcript ?? ''
        if (result?.isFinal) {
          if (text.trim()) options.onResult?.(text.trim())
        } else {
          pending += text
        }
      }
      interim.value = pending
    }
    recognition.onerror = (event) => {
      error.value = event.error
    }
    recognition.onend = () => {
      recognition = null
      isListening.value = false
      interim.value = ''
      options.onEnd?.()
    }
    recognition.start()
  }

  function stop() {
    isListening.value = false
    interim.value = ''
    if (!recognition) return
    const current = recognition
    recognition = null
    current.onend = null
    current.stop()
  }

  onBeforeUnmount(() => {
    if (recognition) recognition.onend = null
    recognition?.abort()
  })

  return { isSupported, isListening, interim, error, start, stop }
}
