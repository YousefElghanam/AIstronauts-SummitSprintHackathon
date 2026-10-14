<script setup lang="ts">
import { computed } from 'vue'
import { icons, type IconName } from './icons'

const props = withDefaults(defineProps<{ name: IconName; size?: number | string; strokeWidth?: number }>(), {
  size: 16,
  strokeWidth: 2,
})

// Static, trusted SVG markup from ./icons — safe for v-html.
const body = computed(() => icons[props.name])
</script>

<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    :width="size"
    :height="size"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    :stroke-width="strokeWidth"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
    class="shrink-0"
    v-html="body"
  />
</template>
