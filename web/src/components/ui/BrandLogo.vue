<script setup lang="ts">
import { useId } from 'vue'

withDefaults(defineProps<{ size?: number }>(), { size: 28 })

// Unique clip id per instance (the logo appears many times on the page).
const clipId = useId()
</script>

<template>
  <!-- Original mark: speech bubble in red-white-red. Not an official emblem. -->
  <svg :width="size" :height="size" viewBox="0 0 32 32" aria-hidden="true" class="shrink-0">
    <defs>
      <clipPath :id="clipId">
        <path d="M8 3h16a6 6 0 0 1 6 6v10a6 6 0 0 1-6 6H14l-6.5 5v-5.3A6 6 0 0 1 2 19V9a6 6 0 0 1 6-6Z" />
      </clipPath>
    </defs>
    <g :clip-path="`url(#${clipId})`">
      <rect width="32" height="11" fill="#c8102e" />
      <rect y="11" width="32" height="6" fill="#ffffff" />
      <rect y="17" width="32" height="15" fill="#c8102e" />
    </g>
    <path
      d="M8 3h16a6 6 0 0 1 6 6v10a6 6 0 0 1-6 6H14l-6.5 5v-5.3A6 6 0 0 1 2 19V9a6 6 0 0 1 6-6Z"
      fill="none"
      stroke="#a50d26"
      stroke-width="1"
    />
  </svg>
</template>
