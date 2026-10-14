import { computed } from 'vue'

export function useGreeting(name: string) {
  return computed(() => {
    const hour = new Date().getHours()
    const part = hour < 12 ? 'Morning' : hour < 18 ? 'Afternoon' : 'Evening'
    return `Good ${part} ${name}`
  })
}
