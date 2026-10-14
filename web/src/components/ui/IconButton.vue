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
    class="grid size-8 place-items-center rounded-full text-slate-400 transition hover:bg-white/10 hover:text-white focus-visible:outline-2 focus-visible:outline-blue-400 disabled:pointer-events-none disabled:opacity-40"
    :class="{ 'bg-blue-500/20 text-blue-300': active }"
  >
    <AppIcon :name="icon" :size="size" />
  </button>
</template>
