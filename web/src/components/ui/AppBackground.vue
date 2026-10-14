<template>
  <div class="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
    <!-- Calm paper-like surface -->
    <div class="absolute inset-0 bg-[linear-gradient(180deg,#ffffff_0%,#f8f9fa_100%)]" />

    <!-- Faint dot grid -->
    <div
      class="absolute inset-0 opacity-60 [background-image:radial-gradient(#d5d9de_1px,transparent_1px)] [background-size:22px_22px] [mask-image:radial-gradient(ellipse_at_center,black_30%,transparent_75%)]"
    />

    <!-- Red-white-red band -->
    <div class="absolute inset-x-0 top-0 flex h-1.5 flex-col">
      <span class="flex-1 bg-brand" />
      <span class="flex-1 bg-white" />
      <span class="flex-1 bg-brand" />
    </div>

    <!-- Soft horizon arc -->
    <div
      class="absolute left-1/2 top-[80%] aspect-square w-[150%] -translate-x-1/2 rounded-full border-t-2 border-brand/15 bg-[radial-gradient(circle_at_50%_0%,#fbeef0_0%,#f4f5f7_30%,#f1f2f4_60%)] shadow-[0_-30px_120px_-30px_rgba(200,16,46,0.18)]"
    />
  </div>
</template>
