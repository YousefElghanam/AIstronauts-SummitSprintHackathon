<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  state: 'listening' | 'thinking' | 'idle'
  caption?: string
}>()
const emit = defineEmits<{ close: [] }>()

const label = computed(() => {
  if (props.caption) return props.caption
  if (props.state === 'thinking') return 'Thinking…'
  if (props.state === 'idle') return 'Paused'
  return 'Listening…'
})
</script>

<template>
  <div class="pointer-events-none absolute inset-x-0 bottom-8 z-20 flex flex-col items-center gap-3">
    <button
      type="button"
      class="cloud pointer-events-auto relative h-20 w-28 focus-visible:outline-none"
      :class="`cloud--${state}`"
      aria-label="Exit voice mode"
      title="Click or press Esc to exit voice mode"
      @click="emit('close')"
    >
      <!-- Glow -->
      <span class="absolute inset-2 rounded-full bg-brand/30 blur-2xl" />

      <!-- Cloud shape -->
      <svg viewBox="0 0 24 20" class="relative size-full drop-shadow-[0_8px_24px_rgba(200,16,46,0.4)]" aria-hidden="true">
        <defs>
          <linearGradient id="cloud-fill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="#ef5a70" />
            <stop offset="1" stop-color="#c8102e" />
          </linearGradient>
        </defs>
        <path
          d="M17.5 17H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"
          fill="url(#cloud-fill)"
          stroke="rgba(255,255,255,0.7)"
          stroke-width="0.4"
        />
      </svg>

      <!-- Voice bars -->
      <span class="absolute inset-x-0 top-[48%] flex h-6 -translate-y-1/2 items-center justify-center gap-[3px] pl-1">
        <span v-for="i in 5" :key="i" class="bar w-[3px] rounded-full bg-white" :style="{ animationDelay: `${i * 0.12}s` }" />
      </span>
    </button>

    <p
      class="max-w-xs truncate rounded-full border border-line bg-surface px-3 py-1 text-xs text-ink-muted shadow-sm"
      role="status"
      aria-live="polite"
    >
      {{ label }}
    </p>
  </div>
</template>

<style scoped>
.cloud {
  animation: float 3s ease-in-out infinite;
}

.bar {
  height: 30%;
  animation: wave 0.9s ease-in-out infinite;
}

.cloud--thinking .bar {
  height: 4px;
  animation: pulse-dot 1.2s ease-in-out infinite;
}

.cloud--idle .bar {
  height: 4px;
  animation: none;
  opacity: 0.6;
}

@keyframes float {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-6px);
  }
}

@keyframes wave {
  0%,
  100% {
    height: 25%;
  }
  50% {
    height: 90%;
  }
}

@keyframes pulse-dot {
  0%,
  100% {
    opacity: 0.35;
  }
  50% {
    opacity: 1;
  }
}

@media (prefers-reduced-motion: reduce) {
  .cloud,
  .bar {
    animation: none;
  }
}
</style>
