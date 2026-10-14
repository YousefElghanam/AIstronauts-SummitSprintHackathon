<script setup lang="ts">
import AppIcon from '@/components/ui/AppIcon.vue'
import { MODES } from '@/config/app'
import type { ChatMode } from '@/types/chat'

const mode = defineModel<ChatMode>({ required: true })
</script>

<template>
  <div class="flex rounded-lg bg-canvas p-0.5" role="radiogroup" aria-label="Assistant mode">
    <button
      v-for="option in MODES"
      :key="option.value"
      type="button"
      role="radio"
      :aria-checked="mode === option.value"
      class="flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs transition"
      :class="mode === option.value ? 'bg-brand text-white shadow-sm' : 'text-ink-muted hover:text-ink'"
      @click="mode = option.value"
    >
      <AppIcon :name="option.icon" :size="13" />
      {{ option.label }}
    </button>
  </div>
</template>
