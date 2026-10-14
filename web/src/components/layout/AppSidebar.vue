<script setup lang="ts">
import { APP_DISCLAIMER, APP_NAME, APP_TAGLINE } from '@/config/app'
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

// Only the assistant (chat) exists for now; the rest are placeholders.
const nav: NavItem[] = [
  { label: 'Assistant', icon: 'message', active: true },
  { label: 'Services', icon: 'compass' },
  { label: 'My applications', icon: 'clipboard-check' },
  { label: 'My documents', icon: 'folder' },
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
    <div v-if="open" class="fixed inset-0 z-30 bg-black/30 md:hidden" @click="emit('toggle')" />
  </Transition>

  <aside
    class="z-40 flex shrink-0 flex-col gap-6 overflow-hidden px-3 py-4 transition-all duration-300 max-md:fixed max-md:inset-y-0 max-md:left-0 max-md:w-64 max-md:bg-canvas max-md:shadow-2xl"
    :class="open ? 'md:w-60' : 'max-md:-translate-x-full md:w-[68px]'"
    aria-label="Main navigation"
  >
    <!-- Brand -->
    <div class="flex items-center gap-2.5 px-1" :class="{ 'md:flex-col': !open }">
      <BrandLogo :size="30" />
      <span class="min-w-0 leading-tight" :class="{ 'md:hidden': !open }">
        <span class="block truncate text-lg font-semibold tracking-tight text-ink">{{ APP_NAME }}</span>
        <span class="block truncate text-[11px] text-ink-subtle">{{ APP_TAGLINE }}</span>
      </span>
      <button
        type="button"
        class="ml-auto grid size-7 shrink-0 place-items-center rounded-md text-ink-subtle transition hover:bg-black/5 hover:text-ink"
        :class="{ 'md:ml-0': !open }"
        :aria-label="open ? 'Collapse sidebar' : 'Expand sidebar'"
        @click="emit('toggle')"
      >
        <AppIcon :name="open ? 'panel-close' : 'panel-open'" :size="16" />
      </button>
    </div>

    <!-- New request -->
    <button
      type="button"
      class="group flex items-center gap-2 rounded-lg border border-line bg-surface px-3 py-2 text-sm font-medium text-ink shadow-sm transition hover:border-brand/40 hover:text-brand"
      :class="{ 'md:justify-center md:px-0': !open }"
      title="New request (Ctrl+I)"
      @click="emit('newThread')"
    >
      <AppIcon name="plus" :size="15" />
      <span class="flex-1 text-left" :class="{ 'md:hidden': !open }">New request</span>
      <span class="flex gap-1" :class="{ 'md:hidden': !open }">
        <kbd class="rounded bg-canvas px-1.5 py-0.5 font-sans text-[10px] text-ink-subtle">Ctrl</kbd>
        <kbd class="rounded bg-canvas px-1.5 py-0.5 font-sans text-[10px] text-ink-subtle">I</kbd>
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
            ? 'bg-brand font-medium text-white shadow-md shadow-brand/25'
            : 'cursor-not-allowed text-ink-subtle hover:bg-black/5',
          { 'md:justify-center md:px-0': !open },
        ]"
        :aria-current="item.active ? 'page' : undefined"
        :aria-disabled="!item.active || undefined"
        :title="item.active ? item.label : `${item.label} (coming soon)`"
      >
        <AppIcon :name="item.icon" :size="16" />
        <span :class="{ 'md:hidden': !open }">{{ item.label }}</span>
      </button>
    </nav>

    <p class="mt-auto px-1 text-[10px] leading-snug text-ink-subtle" :class="{ 'md:hidden': !open }">
      {{ APP_DISCLAIMER }}
    </p>
  </aside>
</template>
