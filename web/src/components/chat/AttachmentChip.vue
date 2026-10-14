<script setup lang="ts">
import AppIcon from '@/components/ui/AppIcon.vue'
import type { ChatAttachment } from '@/types/chat'
import { formatFileSize } from '@/utils/format'

defineProps<{ attachment: ChatAttachment; removable?: boolean }>()
const emit = defineEmits<{ remove: [] }>()
</script>

<template>
  <div class="flex max-w-56 items-center gap-2 rounded-lg border border-white/10 bg-white/5 py-1.5 pl-2 pr-1.5 text-xs">
    <span class="grid size-7 place-items-center rounded-md bg-blue-500/20 text-blue-300">
      <AppIcon name="file" :size="14" />
    </span>
    <span class="min-w-0 flex-1">
      <span class="block truncate text-slate-200">{{ attachment.name }}</span>
      <span class="block text-[10px] text-slate-500">{{ formatFileSize(attachment.size) }}</span>
    </span>
    <button
      v-if="removable"
      type="button"
      class="grid size-5 place-items-center rounded text-slate-500 transition hover:bg-white/10 hover:text-white"
      :aria-label="`Remove ${attachment.name}`"
      @click="emit('remove')"
    >
      <AppIcon name="x" :size="12" />
    </button>
  </div>
</template>
