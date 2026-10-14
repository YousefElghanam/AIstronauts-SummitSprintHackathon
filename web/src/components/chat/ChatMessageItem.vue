<script setup lang="ts">
import { ref } from 'vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import BrandLogo from '@/components/ui/BrandLogo.vue'
import AttachmentChip from './AttachmentChip.vue'
import ApplicationFormCard from './ApplicationFormCard.vue'
import type { ApplicationForm } from '@/types/application'
import type { ChatMessage } from '@/types/chat'

const props = defineProps<{ message: ChatMessage }>()
const emit = defineEmits<{ submitForm: [form: ApplicationForm] }>()

const copied = ref(false)
async function copy() {
  try {
    await navigator.clipboard.writeText(props.message.content)
    copied.value = true
    setTimeout(() => (copied.value = false), 1500)
  } catch {
    // Clipboard may be unavailable (insecure context) — ignore.
  }
}
</script>

<template>
  <!-- User -->
  <div v-if="message.role === 'user'" class="flex flex-col items-end gap-2">
    <div v-if="message.attachments?.length" class="flex flex-wrap justify-end gap-2">
      <AttachmentChip v-for="a in message.attachments" :key="a.id" :attachment="a" />
    </div>
    <p
      v-if="message.content"
      class="max-w-[85%] whitespace-pre-wrap break-words rounded-2xl rounded-br-md bg-ink px-4 py-2.5 text-sm text-white shadow-md shadow-black/10"
    >
      {{ message.content }}
    </p>
  </div>

  <!-- Assistant -->
  <div v-else class="flex gap-3">
    <BrandLogo :size="28" class="mt-0.5" />
    <div class="min-w-0 flex-1">
      <p
        class="whitespace-pre-wrap break-words text-[15px] leading-7"
        :class="message.status === 'error' ? 'flex items-center gap-2 text-brand' : 'text-ink'"
      >
        <AppIcon v-if="message.status === 'error'" name="alert" :size="16" />
        {{ message.content }}
      </p>
      <ApplicationFormCard v-if="message.form" :form="message.form" @submit="emit('submitForm', $event)" />
      <div v-if="message.status !== 'error'" class="mt-1 flex gap-1">
        <button
          type="button"
          class="flex items-center gap-1 rounded-md px-1.5 py-1 text-xs text-ink-subtle transition hover:bg-black/5 hover:text-ink"
          @click="copy"
        >
          <AppIcon :name="copied ? 'check' : 'copy'" :size="13" />
          {{ copied ? 'Copied' : 'Copy' }}
        </button>
      </div>
    </div>
  </div>
</template>
