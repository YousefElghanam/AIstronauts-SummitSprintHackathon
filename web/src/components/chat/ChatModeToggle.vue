<script setup lang="ts">
import AppIcon from '@/components/ui/AppIcon.vue'
import type { IconName } from '@/components/ui/icons'
import type { ChatMode } from '@/types/chat'

const mode = defineModel<ChatMode>({ required: true })

const options: { value: ChatMode; label: string; icon: IconName }[] = [
  { value: 'search', label: 'Search', icon: 'search' },
  { value: 'research', label: 'Research', icon: 'flask' },
]
</script>

<template>
  <div class="flex rounded-lg bg-white/5 p-0.5" role="radiogroup" aria-label="Answer mode">
    <button
      v-for="option in options"
      :key="option.value"
      type="button"
      role="radio"
      :aria-checked="mode === option.value"
      class="flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs transition"
      :class="mode === option.value ? 'bg-blue-600 text-white shadow' : 'text-slate-400 hover:text-white'"
      @click="mode = option.value"
    >
      <AppIcon :name="option.icon" :size="13" />
      {{ option.label }}
    </button>
  </div>
</template>
