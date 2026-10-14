<script setup lang="ts">
import { APP_NAME } from '@/config/app'
import AppIcon from '@/components/ui/AppIcon.vue'
import BrandLogo from '@/components/ui/BrandLogo.vue'
import type { IconName } from '@/components/ui/icons'

defineProps<{ open: boolean }>()
const emit = defineEmits<{ toggle: []; newThread: [] }>()

interface NavItem {
  label: string
  icon: IconName
  active?: boolean
}

// Only "Home" (the chat) exists for now; the rest are placeholders.
const nav: NavItem[] = [
  { label: 'Home', icon: 'search', active: true },
  { label: 'Discover', icon: 'compass' },
  { label: 'Spaces', icon: 'layers' },
  { label: 'Library', icon: 'library' },
]
</script>

<template>
  <!-- Mobile backdrop -->
  <Transition
    enter-from-class="opacity-0"
    leave-to-class="opacity-0"
    enter-active-class="transition-opacity"
    leave-active-class="transition-opacity"
  >
    <div v-if="open" class="fixed inset-0 z-30 bg-black/50 md:hidden" @click="emit('toggle')" />
  </Transition>

  <aside
    class="z-40 flex shrink-0 flex-col gap-6 overflow-hidden px-3 py-4 transition-all duration-300 max-md:fixed max-md:inset-y-0 max-md:left-0 max-md:w-64 max-md:bg-[#0b1838] max-md:shadow-2xl"
    :class="open ? 'md:w-60' : 'max-md:-translate-x-full md:w-[68px]'"
    aria-label="Main navigation"
  >
    <!-- Brand -->
    <div class="flex items-center gap-2 px-1" :class="{ 'md:flex-col': !open }">
      <BrandLogo :size="28" />
      <span class="truncate text-lg font-light tracking-tight text-white" :class="{ 'md:hidden': !open }">
        {{ APP_NAME }}
      </span>
      <button
        type="button"
        class="ml-auto grid size-7 place-items-center rounded-md text-slate-400 transition hover:bg-white/10 hover:text-white"
        :class="{ 'md:ml-0': !open }"
        :aria-label="open ? 'Collapse sidebar' : 'Expand sidebar'"
        @click="emit('toggle')"
      >
        <AppIcon :name="open ? 'panel-close' : 'panel-open'" :size="16" />
      </button>
    </div>

    <!-- New thread -->
    <button
      type="button"
      class="group flex items-center gap-2 rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-sm text-slate-200 transition hover:border-white/20 hover:bg-white/10"
      :class="{ 'md:justify-center md:px-0': !open }"
      title="New Thread (Ctrl+I)"
      @click="emit('newThread')"
    >
      <AppIcon name="plus" :size="15" />
      <span class="flex-1 text-left" :class="{ 'md:hidden': !open }">New Thread</span>
      <span class="flex gap-1" :class="{ 'md:hidden': !open }">
        <kbd class="rounded bg-white/10 px-1.5 py-0.5 font-sans text-[10px] text-slate-400">Ctrl</kbd>
        <kbd class="rounded bg-white/10 px-1.5 py-0.5 font-sans text-[10px] text-slate-400">I</kbd>
      </span>
    </button>

    <!-- Navigation -->
    <nav class="flex flex-col gap-1">
      <button
        v-for="item in nav"
        :key="item.label"
        type="button"
        class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition"
        :class="[
          item.active
            ? 'bg-gradient-to-r from-blue-600 to-blue-700 text-white shadow-lg shadow-blue-900/40'
            : 'cursor-not-allowed text-slate-500 hover:bg-white/5',
          { 'md:justify-center md:px-0': !open },
        ]"
        :aria-current="item.active ? 'page' : undefined"
        :aria-disabled="!item.active || undefined"
        :title="item.active ? item.label : `${item.label} — coming soon`"
      >
        <AppIcon :name="item.icon" :size="16" />
        <span :class="{ 'md:hidden': !open }">{{ item.label }}</span>
      </button>
    </nav>
  </aside>
</template>
