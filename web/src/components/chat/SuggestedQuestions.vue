<script setup lang="ts">
import AppIcon from '@/components/ui/AppIcon.vue'

defineProps<{ questions: string[] }>()
const emit = defineEmits<{ select: [question: string] }>()
</script>

<template>
  <section class="ml-10" aria-labelledby="related-heading">
    <h2 id="related-heading" class="mb-2 flex items-center gap-2 text-xs font-medium uppercase tracking-wider text-ink-subtle">
      <AppIcon name="layers" :size="13" />
      Related
    </h2>
    <ul class="divide-y divide-line overflow-hidden rounded-xl border border-line bg-surface shadow-sm">
      <li v-for="question in questions" :key="question">
        <button
          type="button"
          class="group flex w-full items-center gap-3 px-3 py-2.5 text-left text-sm text-ink transition hover:bg-brand-soft hover:text-brand"
          @click="emit('select', question)"
        >
          <AppIcon name="corner-down-right" :size="14" class="text-ink-subtle group-hover:text-brand" />
          <span class="flex-1">{{ question }}</span>
          <AppIcon name="plus" :size="14" class="text-ink-subtle group-hover:text-brand" />
        </button>
      </li>
    </ul>
  </section>
</template>
