<script setup lang="ts">
import { computed, reactive, ref, useTemplateRef } from 'vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import AttachmentChip from './AttachmentChip.vue'
import type { ApplicationForm } from '@/types/application'
import type { ChatAttachment } from '@/types/chat'
import { createId } from '@/utils/id'
import { formatDate } from '@/utils/format'

const props = defineProps<{ form: ApplicationForm }>()
const emit = defineEmits<{ submit: [form: ApplicationForm] }>()

// Local working copy — the store only receives the completed form on submit.
const values = reactive<Record<string, string>>(Object.fromEntries(props.form.fields.map((f) => [f.id, f.value])))
const files = reactive<Record<string, ChatAttachment | undefined>>(
  Object.fromEntries(props.form.documents.map((d) => [d.id, d.file])),
)

const locked = computed(() => props.form.status !== 'draft')
const profileFields = computed(() => props.form.fields.filter((f) => f.fromIdAustria))
const userFields = computed(() => props.form.fields.filter((f) => !f.fromIdAustria))

const missingFields = computed(() => userFields.value.filter((f) => !values[f.id]?.trim()).length)
const missingDocs = computed(() => props.form.documents.filter((d) => !files[d.id]).length)
const isComplete = computed(() => missingFields.value === 0 && missingDocs.value === 0)

const missingText = computed(() => {
  const parts = []
  if (missingFields.value) parts.push(`${missingFields.value} field${missingFields.value > 1 ? 's' : ''}`)
  if (missingDocs.value) parts.push(`${missingDocs.value} document${missingDocs.value > 1 ? 's' : ''}`)
  return `Still missing: ${parts.join(' and ')}`
})

// One hidden file input shared by all document slots.
const fileInput = useTemplateRef<HTMLInputElement>('fileInput')
const activeDoc = ref<string | null>(null)

function pickFile(docId: string) {
  activeDoc.value = docId
  fileInput.value?.click()
}

function onFileChange(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (file && activeDoc.value) {
    files[activeDoc.value] = { id: createId(), name: file.name, size: file.size, type: file.type, file }
  }
  input.value = ''
  activeDoc.value = null
}

function submit() {
  if (!isComplete.value || locked.value) return
  emit('submit', {
    ...props.form,
    fields: props.form.fields.map((f) => ({ ...f, value: values[f.id] ?? '' })),
    documents: props.form.documents.map((d) => ({ ...d, file: files[d.id] })),
  })
}
</script>

<template>
  <form class="mt-3 overflow-hidden rounded-2xl border border-line bg-surface shadow-sm" @submit.prevent="submit">
    <!-- Header -->
    <header class="flex items-start gap-3 border-b border-line bg-canvas/60 px-4 py-3">
      <span class="grid size-9 shrink-0 place-items-center rounded-lg bg-brand-soft text-brand">
        <AppIcon name="clipboard-check" :size="18" />
      </span>
      <div class="min-w-0 flex-1">
        <h3 class="text-sm font-semibold text-ink">{{ form.title }}</h3>
        <p class="text-xs text-ink-subtle">To: {{ form.authority }}</p>
      </div>
      <span
        class="shrink-0 rounded-full px-2 py-0.5 text-[11px] font-medium"
        :class="form.status === 'submitted' ? 'bg-emerald-50 text-emerald-700' : 'bg-canvas text-ink-muted'"
      >
        {{ form.status === 'submitted' ? 'Submitted' : 'Draft' }}
      </span>
    </header>

    <div class="space-y-5 px-4 py-4">
      <!-- From ID Austria -->
      <section>
        <h4 class="mb-2 flex items-center gap-1.5 text-xs font-medium text-ink-muted">
          <AppIcon name="shield-check" :size="13" class="text-brand" />
          Personal details from ID Austria
        </h4>
        <dl class="grid gap-x-4 gap-y-2 rounded-xl bg-canvas/60 p-3 text-sm sm:grid-cols-2">
          <div v-for="field in profileFields" :key="field.id" class="min-w-0">
            <dt class="text-[11px] text-ink-subtle">{{ field.label }}</dt>
            <dd class="truncate text-ink">{{ field.type === 'date' ? formatDate(field.value) : field.value }}</dd>
          </div>
        </dl>
      </section>

      <!-- To fill in -->
      <section>
        <h4 class="mb-2 text-xs font-medium text-ink-muted">Application details</h4>
        <div class="grid gap-3 sm:grid-cols-2">
          <label v-for="field in userFields" :key="field.id" class="block">
            <span class="mb-1 block text-[11px] text-ink-subtle">{{ field.label }}</span>
            <input
              v-model="values[field.id]"
              :type="field.type"
              :disabled="locked"
              required
              class="w-full rounded-lg border border-line bg-surface px-3 py-2 text-sm text-ink transition focus:border-brand/60 focus:outline-none focus:ring-4 focus:ring-brand/10 disabled:bg-canvas/60 disabled:text-ink-muted"
            />
          </label>
        </div>
      </section>

      <!-- Documents -->
      <section>
        <h4 class="mb-2 text-xs font-medium text-ink-muted">Documents</h4>
        <ul class="divide-y divide-line rounded-xl border border-line">
          <li v-for="doc in form.documents" :key="doc.id" class="flex items-center gap-3 px-3 py-2">
            <span
              class="grid size-5 shrink-0 place-items-center rounded-full"
              :class="files[doc.id] ? 'bg-emerald-500 text-white' : 'border border-line text-transparent'"
            >
              <AppIcon name="check" :size="12" :stroke-width="3" />
            </span>
            <span class="flex-1 text-sm text-ink">{{ doc.label }}</span>
            <AttachmentChip
              v-if="files[doc.id]"
              :attachment="files[doc.id]!"
              :removable="!locked"
              @remove="files[doc.id] = undefined"
            />
            <button
              v-else
              type="button"
              :disabled="locked"
              class="flex items-center gap-1.5 rounded-lg border border-line px-2.5 py-1 text-xs text-ink-muted transition hover:border-brand/40 hover:text-brand"
              @click="pickFile(doc.id)"
            >
              <AppIcon name="paperclip" :size="13" />
              Attach
            </button>
          </li>
        </ul>
        <input ref="fileInput" type="file" accept="application/pdf,image/*" class="hidden" @change="onFileChange" />
      </section>
    </div>

    <!-- Footer -->
    <footer class="flex flex-wrap items-center gap-3 border-t border-line bg-canvas/60 px-4 py-3">
      <p v-if="form.status === 'submitted'" class="flex items-center gap-1.5 text-xs text-emerald-700">
        <AppIcon name="check" :size="14" :stroke-width="2.5" />
        Signed and submitted · Reference {{ form.reference }}
      </p>
      <template v-else>
        <p class="flex-1 text-xs text-ink-subtle">
          <template v-if="!isComplete">{{ missingText }}</template>
          <template v-else>Pressing "Sign & apply" signs the application with your ID Austria.</template>
        </p>
        <button
          type="submit"
          :disabled="!isComplete || locked"
          class="flex items-center gap-2 rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white shadow-md shadow-brand/25 transition hover:bg-brand-hover disabled:bg-brand/30 disabled:shadow-none"
        >
          <span v-if="form.status === 'submitting'" class="size-3.5 animate-spin rounded-full border-2 border-white/30 border-t-white" />
          <AppIcon v-else name="shield-check" :size="15" />
          {{ form.status === 'submitting' ? 'Signing…' : 'Sign & apply' }}
        </button>
      </template>
    </footer>
  </form>
</template>
