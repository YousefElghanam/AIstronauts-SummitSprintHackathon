<script setup lang="ts">
import { USER_NAME } from '@/config/app'
import { useGreeting } from '@/composables/useGreeting'

const greeting = useGreeting(USER_NAME)
</script>

<template>
  <header class="text-center">
    <h1 class="text-3xl font-medium tracking-tight text-white sm:text-5xl">{{ greeting }}</h1>
    <p class="mt-2 text-2xl text-slate-400 sm:text-4xl">How can I help you today?</p>
  </header>
</template>
