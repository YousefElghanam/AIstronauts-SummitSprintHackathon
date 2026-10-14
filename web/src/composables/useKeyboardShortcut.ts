import { onBeforeUnmount, onMounted } from 'vue'

interface Shortcut {
  key: string
  ctrlOrMeta?: boolean
}

export function useKeyboardShortcut({ key, ctrlOrMeta = false }: Shortcut, handler: (e: KeyboardEvent) => void) {
  function onKeydown(e: KeyboardEvent) {
    if (e.key.toLowerCase() !== key.toLowerCase()) return
    if (ctrlOrMeta && !(e.ctrlKey || e.metaKey)) return
    e.preventDefault()
    handler(e)
  }

  onMounted(() => window.addEventListener('keydown', onKeydown))
  onBeforeUnmount(() => window.removeEventListener('keydown', onKeydown))
}
