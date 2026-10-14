<script setup lang="ts">
withDefaults(defineProps<{ size?: number }>(), { size: 28 })
</script>

<template>
  <svg :width="size" :height="size" viewBox="0 0 32 32" aria-hidden="true" class="shrink-0">
    <defs>
      <linearGradient id="brand-bg" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#60a5fa" />
        <stop offset="1" stop-color="#1d4ed8" />
      </linearGradient>
    </defs>
    <rect width="32" height="32" rx="9" fill="url(#brand-bg)" />
    <circle cx="16" cy="17" r="7.5" fill="none" stroke="#fff" stroke-width="2.2" opacity=".95" />
    <circle cx="19.5" cy="13.5" r="3" fill="#fff" />
  </svg>
</template>
