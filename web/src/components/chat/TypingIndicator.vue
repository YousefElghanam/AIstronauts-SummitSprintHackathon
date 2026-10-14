<script setup lang="ts">
import BrandLogo from '@/components/ui/BrandLogo.vue'
</script>

<template>
  <div class="flex items-center gap-3" role="status" aria-live="polite">
    <BrandLogo :size="28" class="animate-pulse" />
    <div class="flex items-center gap-1 rounded-2xl rounded-bl-md border border-line bg-surface px-4 py-3 shadow-sm">
      <span v-for="i in 3" :key="i" class="dot size-1.5 rounded-full bg-brand" :style="{ animationDelay: `${(i - 1) * 0.15}s` }" />
    </div>
    <span class="text-xs text-ink-subtle">Thinking…</span>
  </div>
</template>

<style scoped>
.dot {
  animation: typing-bounce 1s ease-in-out infinite;
}

@keyframes typing-bounce {
  0%,
  60%,
  100% {
    transform: translateY(0);
    opacity: 0.4;
  }
  30% {
    transform: translateY(-4px);
    opacity: 1;
  }
}

@media (prefers-reduced-motion: reduce) {
  .dot {
    animation: none;
  }
}
</style>
