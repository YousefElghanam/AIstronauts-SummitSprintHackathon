<script setup lang="ts">
import { computed, nextTick, useTemplateRef, watch } from 'vue'
import ChatMessageItem from './ChatMessageItem.vue'
import SuggestedQuestions from './SuggestedQuestions.vue'
import TypingIndicator from './TypingIndicator.vue'
import type { ApplicationForm } from '@/types/application'
import type { ChatMessage } from '@/types/chat'

const props = defineProps<{ messages: ChatMessage[]; waiting: boolean }>()
const emit = defineEmits<{ suggest: [question: string]; submitForm: [messageId: string, form: ApplicationForm] }>()

const scroller = useTemplateRef<HTMLElement>('scroller')

// Suggestions are only offered for the latest answer.
const suggestions = computed(() => {
  const last = props.messages.at(-1)
  if (props.waiting || last?.role !== 'assistant') return []
  return last.suggestions ?? []
})

watch(
  () => [props.messages.length, props.waiting],
  async () => {
    await nextTick()
    scroller.value?.scrollTo({ top: scroller.value.scrollHeight, behavior: 'smooth' })
  },
  { immediate: true },
)
</script>

<template>
  <div ref="scroller" class="scrollbar-thin min-h-0 flex-1 overflow-y-auto px-4">
    <div class="mx-auto flex max-w-3xl flex-col gap-6 py-8" aria-live="polite">
      <ChatMessageItem
        v-for="message in messages"
        :key="message.id"
        :message="message"
        @submit-form="emit('submitForm', message.id, $event)"
      />
      <TypingIndicator v-if="waiting" />
      <SuggestedQuestions v-if="suggestions.length" :questions="suggestions" @select="emit('suggest', $event)" />
    </div>
  </div>
</template>
