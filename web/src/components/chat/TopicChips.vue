<script setup lang="ts">
import AppIcon from '@/components/ui/AppIcon.vue'
import type { Topic } from '@/config/app'

defineProps<{ topics: Topic[] }>()
const emit = defineEmits<{ select: [topic: Topic] }>()
</script>

<template>
  <ul class="flex flex-wrap justify-center gap-2">
    <li v-for="topic in topics" :key="topic.label">
      <button
        type="button"
        class="flex items-center gap-1.5 rounded-lg border border-line bg-surface px-3 py-1.5 text-xs font-medium text-ink shadow-sm transition hover:-translate-y-0.5 hover:border-brand/40 hover:bg-brand-soft"
        @click="emit('select', topic)"
      >
        <AppIcon :name="topic.icon" :size="13" class="text-brand" />
        {{ topic.label }}
      </button>
    </li>
  </ul>
</template>
