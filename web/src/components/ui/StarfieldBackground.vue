<script setup lang="ts">
interface Star {
  top: number
  left: number
  size: number
  delay: number
  duration: number
  opacity: number
}

// Generated once per mount — purely decorative.
const stars: Star[] = Array.from({ length: 70 }, () => ({
  top: Math.random() * 100,
  left: Math.random() * 100,
  size: Math.random() < 0.85 ? 1 : 2,
  delay: Math.random() * 6,
  duration: 3 + Math.random() * 5,
  opacity: 0.25 + Math.random() * 0.6,
}))
</script>

<template>
  <div class="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
    <!-- Deep space gradient -->
    <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_top,#0f1d45_0%,#081029_45%,#050a1c_100%)]" />

    <!-- Stars -->
    <span
      v-for="(star, i) in stars"
      :key="i"
      class="absolute animate-twinkle rounded-full bg-white motion-reduce:animate-none"
      :style="{
        top: `${star.top}%`,
        left: `${star.left}%`,
        width: `${star.size}px`,
        height: `${star.size}px`,
        opacity: star.opacity,
        animationDelay: `${star.delay}s`,
        animationDuration: `${star.duration}s`,
      }"
    />

    <!-- A few sparkles -->
    <span class="sparkle top-[72%] right-[6%]" />
    <span class="sparkle top-[86%] right-[14%] scale-75 [animation-delay:2s]" />
    <span class="sparkle top-[18%] left-[9%] scale-50 [animation-delay:4s]" />

    <!-- Planet horizon -->
    <div
      class="absolute left-1/2 top-[78%] aspect-square w-[150%] -translate-x-1/2 rounded-full bg-[radial-gradient(circle_at_50%_0%,#13285e_0%,#0a1534_25%,#060c22_60%)] shadow-[0_-30px_120px_-20px_rgba(59,130,246,0.35),inset_0_1px_0_rgba(147,197,253,0.35)]"
    />
  </div>
</template>

<style scoped>
.sparkle {
  position: absolute;
  width: 14px;
  height: 14px;
  background:
    linear-gradient(transparent 45%, rgb(147 197 253 / 0.9) 45% 55%, transparent 55%),
    linear-gradient(90deg, transparent 45%, rgb(147 197 253 / 0.9) 45% 55%, transparent 55%);
  border-radius: 9999px;
  filter: drop-shadow(0 0 4px rgb(96 165 250));
  animation: twinkle 5s ease-in-out infinite;
}

@media (prefers-reduced-motion: reduce) {
  .sparkle {
    animation: none;
  }
}
</style>
