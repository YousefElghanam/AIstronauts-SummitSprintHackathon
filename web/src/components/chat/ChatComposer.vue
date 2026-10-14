<script setup lang="ts">
import { computed, nextTick, ref, useTemplateRef, watch } from 'vue'
import IconButton from '@/components/ui/IconButton.vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import AttachmentChip from './AttachmentChip.vue'
import ChatModeToggle from './ChatModeToggle.vue'
import type { ChatAttachment, ChatMode } from '@/types/chat'
import { createId } from '@/utils/id'

const props = defineProps<{ busy?: boolean }>()
const emit = defineEmits<{
  submit: [payload: { text: string; attachments: ChatAttachment[] }]
  voice: []
}>()

const draft = defineModel<string>({ default: '' })
const mode = defineModel<ChatMode>('mode', { required: true })

const textarea = useTemplateRef<HTMLTextAreaElement>('textarea')
const fileInput = useTemplateRef<HTMLInputElement>('fileInput')
const attachments = ref<ChatAttachment[]>([])
const isDragging = ref(false)

const canSend = computed(() => !props.busy && (draft.value.trim().length > 0 || attachments.value.length > 0))

const MAX_HEIGHT = 200
function autoResize() {
  const el = textarea.value
  if (!el) return
  el.style.height = 'auto'
  el.style.height = `${Math.min(el.scrollHeight, MAX_HEIGHT)}px`
}
watch(draft, () => nextTick(autoResize))

function addFiles(files: FileList | File[]) {
  const added = Array.from(files).map((file) => ({
    id: createId(),
    name: file.name,
    size: file.size,
    type: file.type,
    file,
  }))
  attachments.value.push(...added)
}

function onFileChange(e: Event) {
  const input = e.target as HTMLInputElement
  if (input.files) addFiles(input.files)
  input.value = ''
}

function removeAttachment(id: string) {
  attachments.value = attachments.value.filter((a) => a.id !== id)
}

function onDrop(e: DragEvent) {
  isDragging.value = false
  if (e.dataTransfer?.files.length) addFiles(e.dataTransfer.files)
}

function submit() {
  if (!canSend.value) return
  emit('submit', { text: draft.value, attachments: attachments.value })
  draft.value = ''
  attachments.value = []
}

function focus() {
  const el = textarea.value
  if (!el) return
  el.focus()
  el.setSelectionRange(el.value.length, el.value.length)
}

defineExpose({ focus })
</script>

<template>
  <form
    class="w-full rounded-2xl border bg-[#0a0d16]/90 p-3 shadow-2xl shadow-black/40 backdrop-blur-xl transition"
    :class="isDragging ? 'border-blue-400/70 ring-4 ring-blue-500/20' : 'border-white/10 focus-within:border-white/20'"
    @submit.prevent="submit"
    @dragover.prevent="isDragging = true"
    @dragleave.self="isDragging = false"
    @drop.prevent="onDrop"
  >
    <!-- Pending attachments -->
    <div v-if="attachments.length" class="mb-2 flex flex-wrap gap-2">
      <AttachmentChip
        v-for="attachment in attachments"
        :key="attachment.id"
        :attachment="attachment"
        removable
        @remove="removeAttachment(attachment.id)"
      />
    </div>

    <label for="chat-input" class="sr-only">Message</label>
    <textarea
      id="chat-input"
      ref="textarea"
      v-model="draft"
      rows="2"
      placeholder="Ask anything..."
      class="block w-full resize-none bg-transparent px-1 text-sm leading-6 text-slate-100 placeholder:text-slate-500 focus:outline-none"
      @keydown.enter.exact.prevent="submit"
    />

    <div class="mt-2 flex items-center justify-between gap-2">
      <ChatModeToggle v-model="mode" />

      <div class="flex items-center gap-0.5 rounded-full bg-white/5 p-0.5">
        <IconButton icon="paperclip" label="Attach files" @click="fileInput?.click()" />
        <IconButton icon="mic" label="Voice mode" @click="emit('voice')" />
        <button
          type="submit"
          class="ml-0.5 grid size-8 place-items-center rounded-full bg-blue-600 text-white shadow-lg shadow-blue-600/30 transition hover:bg-blue-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-400 disabled:bg-blue-600/30 disabled:text-white/50 disabled:shadow-none"
          :disabled="!canSend"
          :aria-label="busy ? 'Waiting for answer' : 'Send message'"
        >
          <span v-if="busy" class="size-3.5 animate-spin rounded-full border-2 border-white/30 border-t-white" />
          <AppIcon v-else name="arrow-up" :size="16" :stroke-width="2.5" />
        </button>
      </div>
    </div>

    <input ref="fileInput" type="file" multiple class="hidden" @change="onFileChange" />
  </form>
</template>
