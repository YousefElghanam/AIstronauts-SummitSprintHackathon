<script setup lang="ts">
import { computed, nextTick, ref, useTemplateRef } from 'vue'
import { storeToRefs } from 'pinia'
import AppSidebar from '@/components/layout/AppSidebar.vue'
import AppBackground from '@/components/ui/AppBackground.vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import BrandLogo from '@/components/ui/BrandLogo.vue'
import ChatWelcome from '@/components/chat/ChatWelcome.vue'
import ChatComposer from '@/components/chat/ChatComposer.vue'
import TopicChips from '@/components/chat/TopicChips.vue'
import ChatMessageList from '@/components/chat/ChatMessageList.vue'
import VoiceListeningCloud from '@/components/chat/VoiceListeningCloud.vue'
import { useChatStore } from '@/stores/chat'
import { useSpeechRecognition } from '@/composables/useSpeechRecognition'
import { useKeyboardShortcut } from '@/composables/useKeyboardShortcut'
import { APP_NAME, MODES, TOPICS, type Topic } from '@/config/app'
import type { ChatAttachment } from '@/types/chat'

const chat = useChatStore()
const { messages, isWaiting, mode, hasMessages } = storeToRefs(chat)

const composer = useTemplateRef<InstanceType<typeof ChatComposer>>('composer')
const draft = ref('')

// ---- Sidebar ----
const isDesktop = () => window.matchMedia('(min-width: 768px)').matches
const sidebarOpen = ref(isDesktop())

function startNewThread() {
  chat.newThread()
  draft.value = ''
  if (!isDesktop()) sidebarOpen.value = false
  nextTick(() => composer.value?.focus())
}

// ---- Sending ----
function onSubmit({ text, attachments }: { text: string; attachments: ChatAttachment[] }) {
  chat.send(text, attachments)
}

const modeHint = computed(() => MODES.find((m) => m.value === mode.value)?.hint ?? '')

function onTopic(topic: Topic) {
  draft.value = topic.prompt
  nextTick(() => composer.value?.focus())
}

// ---- Voice mode ----
const voiceMode = ref(false)
const speech = useSpeechRecognition({
  onResult: (text) => chat.send(text),
  // Browsers end recognition after silence — keep listening while in voice mode.
  onEnd: () => {
    if (voiceMode.value && !speech.error.value) speech.start()
  },
})

const voiceState = computed(() => {
  if (speech.error.value) return 'idle'
  return isWaiting.value ? 'thinking' : 'listening'
})

const voiceCaption = computed(() => {
  const err = speech.error.value
  if (err === 'not-allowed' || err === 'service-not-allowed') return 'Microphone access denied'
  if (err) return 'Voice input stopped — tap to exit'
  if (!speech.isSupported) return 'Listening… (voice input not supported in this browser)'
  return speech.interim.value
})

function enterVoiceMode() {
  voiceMode.value = true
  speech.start()
}

function exitVoiceMode() {
  voiceMode.value = false
  speech.stop()
  nextTick(() => composer.value?.focus())
}

// ---- Shortcuts ----
useKeyboardShortcut({ key: 'i', ctrlOrMeta: true }, startNewThread)
useKeyboardShortcut({ key: 'Escape' }, () => {
  if (voiceMode.value) exitVoiceMode()
})
</script>

<template>
  <div class="flex h-dvh bg-canvas md:p-3">
    <AppSidebar :open="sidebarOpen" @toggle="sidebarOpen = !sidebarOpen" @new-thread="startNewThread" />

    <main
      class="relative flex min-w-0 flex-1 flex-col overflow-hidden border-line bg-surface md:rounded-3xl md:border md:shadow-xl md:shadow-black/5"
    >
      <AppBackground />

      <div class="relative z-10 flex h-full flex-col">
        <!-- Mobile top bar -->
        <div class="flex items-center gap-2 px-4 pt-4 md:hidden">
          <button
            type="button"
            class="grid size-9 place-items-center rounded-lg text-ink-muted hover:bg-black/5"
            aria-label="Open sidebar"
            @click="sidebarOpen = true"
          >
            <AppIcon name="menu" :size="18" />
          </button>
          <BrandLogo :size="24" />
          <span class="text-base font-semibold text-ink">{{ APP_NAME }}</span>
        </div>

        <ChatMessageList
          v-if="hasMessages"
          :messages="messages"
          :waiting="isWaiting" @suggest="chat.send($event)"
          @submit-form="chat.submitForm"
        />

        <div
          :class="
            hasMessages ? 'px-4 pb-4' : 'flex flex-1 flex-col items-center justify-center px-4 pb-[10vh]'
          "
        >
          <div class="mx-auto w-full" :class="hasMessages ? 'max-w-3xl' : 'max-w-2xl'">
            <ChatWelcome v-if="!hasMessages" class="mb-10" />

            <Transition
              enter-from-class="opacity-0 translate-y-4"
              leave-to-class="opacity-0 translate-y-4"
              enter-active-class="transition duration-300"
              leave-active-class="transition duration-200"
            >
              <div v-show="!voiceMode">
                <ChatComposer
                  ref="composer"
                  v-model="draft"
                  v-model:mode="mode"
                  :busy="isWaiting"
                  @submit="onSubmit"
                  @voice="enterVoiceMode"
                />
                <p
                  v-if="hasMessages || mode === 'task'"
                  class="mt-2 flex items-center justify-center gap-1.5 text-center text-[11px] text-ink-subtle"
                >
                  <AppIcon v-if="mode === 'task'" name="shield-check" :size="12" class="text-brand" />
                  {{ modeHint }}
                </p>
                <TopicChips v-if="!hasMessages" :topics="TOPICS" class="mt-5" @select="onTopic" />
              </div>
            </Transition>
          </div>
        </div>
      </div>

      <Transition
        enter-from-class="opacity-0 scale-75"
        leave-to-class="opacity-0 scale-75"
        enter-active-class="transition duration-300"
        leave-active-class="transition duration-200"
      >
        <VoiceListeningCloud v-if="voiceMode" :state="voiceState" :caption="voiceCaption" @close="exitVoiceMode" />
      </Transition>
    </main>
  </div>
</template>
