<script setup lang="ts">
import AppIcon from './AppIcon.vue'
import type { IconName } from './icons'

withDefaults(defineProps<{ icon: IconName; label: string; active?: boolean; size?: number }>(), {
  active: false,
  size: 15,
})
</script>

<template>
  <button
    type="button"
    :aria-label="label"
    :title="label"
    :aria-pressed="active || undefined"
    class="grid size-8 place-items-center rounded-full text-ink-muted transition hover:bg-black/5 hover:text-ink focus-visible:outline-2 focus-visible:outline-brand disabled:pointer-events-none disabled:opacity-40"
    :class="{ 'bg-brand-soft text-brand': active }"
  >
    <AppIcon :name="icon" :size="size" />
  </button>
</template>
