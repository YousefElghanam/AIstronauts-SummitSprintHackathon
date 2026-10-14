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
        class="flex items-center gap-1.5 rounded-lg border border-white/10 bg-[#0a0d16]/80 px-3 py-1.5 text-xs text-slate-200 backdrop-blur transition hover:-translate-y-0.5 hover:border-blue-400/40 hover:bg-blue-500/10"
        @click="emit('select', topic)"
      >
        <AppIcon :name="topic.icon" :size="13" class="text-blue-400" />
        {{ topic.label }}
      </button>
    </li>
  </ul>
</template>
