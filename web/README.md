# web

This template should help get you started developing with Vue 3 in Vite.

## Recommended IDE Setup

[VS Code](https://code.visualstudio.com/) + [Vue (Official)](https://marketplace.visualstudio.com/items?itemName=Vue.volar) (and disable Vetur).

## Recommended Browser Setup

- Chromium-based browsers (Chrome, Edge, Brave, etc.):
  - [Vue.js devtools](https://chromewebstore.google.com/detail/vuejs-devtools/nhdogjmejiglipccpnnnanhbledajbpd)
  - [Turn on Custom Object Formatter in Chrome DevTools](http://bit.ly/object-formatters)
- Firefox:
  - [Vue.js devtools](https://addons.mozilla.org/en-US/firefox/addon/vue-js-devtools/)
  - [Turn on Custom Object Formatter in Firefox DevTools](https://fxdx.dev/firefox-devtools-custom-object-formatters/)

## Type Support for `.vue` Imports in TS

TypeScript cannot handle type information for `.vue` imports by default, so we replace the `tsc` CLI with `vue-tsc` for type checking. In editors, we need [Volar](https://marketplace.visualstudio.com/items?itemName=Vue.volar) to make the TypeScript language service aware of `.vue` types.

## Customize configuration

See [Vite Configuration Reference](https://vite.dev/config/).

## Project Setup

```sh
npm install
```

### Compile and Hot-Reload for Development

```sh
npm run dev
```

### Type-Check, Compile and Minify for Production

```sh
npm run build
```

### Lint with [ESLint](https://eslint.org/)

```sh
npm run lint
```

## Deploy to Cloudflare Workers

One Worker serves the built Vue app (Workers Static Assets) and `POST /api/chat` (`worker/index.ts`), so the Gemini key stays server-side and no CORS setup is needed. Config: `wrangler.jsonc`.

```sh
npx wrangler login
npx wrangler secret put GEMINI_API_KEY   # once
VITE_AI_ENABLED=true npm run deploy      # VITE_* vars are baked in at build time
```

Test the production setup locally: copy `.dev.vars.example` to `.dev.vars`, add your key, then run `VITE_AI_ENABLED=true npm run cf:dev`.

Auto-deploy on push: Cloudflare dashboard → Workers & Pages → Create → Import a repository. Set root directory `web`, build command `npm run build`, deploy command `npx wrangler deploy`, build variable `VITE_AI_ENABLED=true`, and add `GEMINI_API_KEY` as a secret in the Worker's settings.
