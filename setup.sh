#!/usr/bin/env bash
# =============================================================================
#  CivicGuide – FRONTEND-ONLY setup (Vue 3 MVP)   Linux / WSL2 / macOS
#
#  Installs or updates Git + Node.js, then creates (first run) or installs
#  (teammates) the Vue 3 app in /web. No backend needed: the app runs on
#  mock data until we switch VITE_USE_MOCK=false and point it at a real API.
#
#  Usage:
#    ./setup-frontend.sh            # interactive menu
#    ./setup-frontend.sh --all      # tools + app, no menu
#    ./setup-frontend.sh --tools    # only Git + Node
#    ./setup-frontend.sh --app      # only the Vue app (deps, .env, files)
#    ./setup-frontend.sh --check    # show what is installed, change nothing
#    Add -y to answer "yes" to every question.
# =============================================================================

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

NODE_MIN_MAJOR=20
NVM_VERSION="v0.40.1"
APP_DIR="web"
ASSUME_YES=0; DO_TOOLS=0; DO_APP=0; DO_CHECK=0
SUMMARY=()

# ---------- output helpers ------------------------------------------------------
if [ -t 1 ]; then B=$'\033[1m'; BL=$'\033[34m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; N=$'\033[0m'
else B=""; BL=""; G=""; Y=""; R=""; N=""; fi
section() { printf "\n%s==> %s%s\n" "$B$BL" "$1" "$N"; }
info()    { printf "   %s\n" "$1"; }
ok()      { printf "   %s✔ %s%s\n" "$G" "$1" "$N"; SUMMARY+=("✔ $1"); }
warn()    { printf "   %s! %s%s\n" "$Y" "$1" "$N"; SUMMARY+=("! $1"); }
fail()    { printf "   %s✖ %s%s\n" "$R" "$1" "$N"; SUMMARY+=("✖ $1"); }
have()    { command -v "$1" >/dev/null 2>&1; }
# In WSL the Windows PATH leaks in – ignore Windows binaries under /mnt/*
linux_have() { local p; p="$(command -v "$1" 2>/dev/null)" || return 1; [[ "$p" != /mnt/* ]]; }
ask_yn() {
  local q="$1" def="${2:-y}" ans hint="[Y/n]"
  [ "$ASSUME_YES" -eq 1 ] && return 0
  [ "$def" = "n" ] && hint="[y/N]"
  read -r -p "   ? $q $hint " ans; ans="${ans:-$def}"; [[ "$ans" =~ ^[Yy] ]]
}

OS="$(uname -s)"
IS_WSL=0; grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1
SUDO=""; [ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"
PKG="unknown"
if [ "$OS" = "Darwin" ]; then PKG="brew"
elif have apt-get; then PKG="apt"
elif have dnf; then PKG="dnf"
elif have pacman; then PKG="pacman"; fi

# ---------- tools ---------------------------------------------------------------
ensure_system() {
  section "System packages"
  case "$PKG" in
    apt)    $SUDO apt-get update -y >/dev/null && $SUDO apt-get install -y git curl ca-certificates build-essential >/dev/null ;;
    dnf)    $SUDO dnf install -y git curl gcc-c++ make >/dev/null ;;
    pacman) $SUDO pacman -S --noconfirm --needed git curl base-devel >/dev/null ;;
    brew)
      if ! have brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
      brew update >/dev/null; brew list git >/dev/null 2>&1 && brew upgrade git >/dev/null 2>&1 || brew install git >/dev/null ;;
    *) warn "Unknown package manager – install git and curl manually" ;;
  esac
  if have git; then ok "Git $(git --version | awk '{print $3}')"; else fail "Git missing – https://git-scm.com"; fi
}

wsl_checks() {
  [ "$IS_WSL" -eq 1 ] || return 0
  section "WSL checks"
  if [[ "$ROOT" == /mnt/* ]]; then
    warn "Project is on the Windows drive ($ROOT) – npm will be slow and hot-reload may break."
    info "Better: mkdir -p ~/projects && cd ~/projects && git clone <repo-url>"
    ask_yn "Continue anyway?" n || exit 1
  else
    ok "Project is on the Linux filesystem"
  fi
  have git && git config --global core.autocrlf input && ok "git core.autocrlf=input (no CRLF issues)"
}

load_nvm() { export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; }
node_major() { node -v 2>/dev/null | sed 's/^v//' | cut -d. -f1; }

ensure_node() {
  section "Node.js LTS (>= $NODE_MIN_MAJOR) + npm"
  load_nvm
  have node && ! linux_have node && warn "Ignoring Windows Node.js at $(command -v node) – installing Linux Node"
  if ! have nvm; then
    if linux_have node && [ "$(node_major)" -ge "$NODE_MIN_MAJOR" ]; then
      ok "Node $(node -v) / npm $(npm -v) (system install – keeping it)"; return 0
    fi
    info "Installing nvm $NVM_VERSION..."
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash >/dev/null 2>&1 \
      || { fail "nvm install failed – install Node LTS from https://nodejs.org"; return 1; }
    load_nvm
  fi
  info "Installing / updating Node LTS via nvm..."
  if linux_have node; then nvm install --lts --latest-npm --reinstall-packages-from=current >/dev/null 2>&1 || nvm install --lts --latest-npm >/dev/null 2>&1
  else nvm install --lts --latest-npm >/dev/null 2>&1; fi
  nvm alias default 'lts/*' >/dev/null 2>&1; nvm use default >/dev/null 2>&1; hash -r
  if linux_have node && [ "$(node_major)" -ge "$NODE_MIN_MAJOR" ]; then ok "Node $(node -v) / npm $(npm -v)"
  else fail "Node setup failed"; fi
}

# ---------- app -----------------------------------------------------------------
write_if_missing() { # write_if_missing <file>  (content on stdin)
  if [ -e "$1" ]; then cat >/dev/null; return 1; fi
  mkdir -p "$(dirname "$1")"; cat > "$1"; return 0
}

scaffold_app() {
  info "Creating Vue 3 + TypeScript app (router, Pinia, ESLint)..."
  npm create vue@latest "$APP_DIR" -- --ts --router --pinia --eslint
  [ -f "$APP_DIR/package.json" ] || { fail "Vue scaffold failed"; return 1; }
  ( cd "$APP_DIR" && npm install >/dev/null && npm install -D tailwindcss @tailwindcss/vite >/dev/null ) \
    || { fail "Installing Tailwind failed"; return 1; }

  # Wire Tailwind v4 into Vite + CSS
  node - "$APP_DIR" <<'EOF' && ok "Tailwind CSS wired into Vite" || warn "Add tailwindcss() to vite.config.ts plugins manually"
const fs = require('fs'), path = require('path')
const f = path.join(process.argv[2], 'vite.config.ts')
let s = fs.readFileSync(f, 'utf8')
if (!s.includes('@tailwindcss/vite')) {
  s = "import tailwindcss from '@tailwindcss/vite'\n" + s
  if (!/plugins:\s*\[/.test(s)) process.exit(1)
  s = s.replace(/plugins:\s*\[/, 'plugins: [\n    tailwindcss(),')
  fs.writeFileSync(f, s)
}
EOF
  printf '@import "tailwindcss";\n' > "$APP_DIR/src/assets/main.css"
  ok "Scaffolded Vue app in /$APP_DIR"
}

write_starter_files() {
  # API layer: mock data now, real backend later (flip VITE_USE_MOCK=false)
  write_if_missing "$APP_DIR/src/api/client.ts" <<'EOF' && ok "Created src/api/client.ts (mock ↔ real API switch)"
import { mockChat } from './mock'

export interface Source { title: string; url: string }
export interface ChatResponse {
  reply: string
  intent?: string
  confidence?: number
  missingFields?: string[]
  workflow?: { service: string; currentStep: number; totalSteps: number }
  sources?: Source[]
}

const USE_MOCK = import.meta.env.VITE_USE_MOCK !== 'false'
const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:3333'

export async function sendMessage(message: string, sessionId?: string): Promise<ChatResponse> {
  if (USE_MOCK) return mockChat(message)
  const res = await fetch(`${API_URL}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message, sessionId }),
  })
  if (!res.ok) throw new Error(`API error ${res.status}`)
  return res.json()
}
EOF

  write_if_missing "$APP_DIR/src/api/mock.ts" <<'EOF' && ok "Created src/api/mock.ts (fake responses for the MVP)"
import type { ChatResponse } from './client'

const delay = (ms: number) => new Promise((r) => setTimeout(r, ms))

export async function mockChat(message: string): Promise<ChatResponse> {
  await delay(600)
  const text = message.toLowerCase()
  if (/(move|moved|address|költöz|lakcím)/.test(text)) {
    return {
      reply:
        'It sounds like you moved. You need to register your new address within 3 days. ' +
        'I can guide you – first, what is your new address?',
      intent: 'address_change',
      confidence: 0.92,
      missingFields: ['newAddress', 'moveDate', 'idCardNumber'],
      workflow: { service: 'address_change', currentStep: 1, totalSteps: 4 },
      sources: [{ title: 'Official address registration guide (example)', url: 'https://example.gov/address' }],
    }
  }
  return {
    reply: "I'm not completely sure what you need yet. Could you tell me a bit more – for example, did you move, have a baby, or start a business?",
    confidence: 0.4,
  }
}
EOF

  mkdir -p "$APP_DIR/src/components" "$APP_DIR/src/views" "$APP_DIR/src/stores"

  if [ ! -f "$APP_DIR/.env.example" ]; then
    printf 'VITE_USE_MOCK=true\nVITE_API_URL=http://localhost:3333\n' > "$APP_DIR/.env.example"
    ok "Created $APP_DIR/.env.example"
  fi
}

write_repo_files() {
  write_if_missing .gitignore <<'EOF' && ok "Created .gitignore"
node_modules/
dist/
coverage/
.env
.env.*
!.env.example
.DS_Store
*.log
EOF
  write_if_missing .gitattributes <<'EOF' && ok "Created .gitattributes (LF line endings)"
* text=auto eol=lf
*.sh text eol=lf
EOF
  write_if_missing .vscode/extensions.json <<'EOF' && ok "Created .vscode/extensions.json"
{
  "recommendations": [
    "Vue.volar",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "ms-vscode-remote.remote-wsl"
  ]
}
EOF
  true
}

setup_app() {
  section "Vue app (/$APP_DIR)"
  linux_have npm || { fail "npm missing – run tools setup first"; return 1; }
  if [ ! -f "$APP_DIR/package.json" ]; then
    if ask_yn "No /$APP_DIR app found. Create a new Vue 3 MVP app now?"; then
      scaffold_app || return 1
    else
      warn "Skipped app creation"; return 0
    fi
  else
    info "Installing dependencies..."
    ( cd "$APP_DIR" && npm install >/dev/null ) && ok "Dependencies installed" || { fail "npm install failed in /$APP_DIR"; return 1; }
  fi
  write_starter_files
  write_repo_files
  if [ ! -f "$APP_DIR/.env" ]; then cp "$APP_DIR/.env.example" "$APP_DIR/.env"; ok "Created $APP_DIR/.env (mock mode ON)"; fi
  if have code; then
    for e in Vue.volar dbaeumer.vscode-eslint esbenp.prettier-vscode bradlc.vscode-tailwindcss; do code --install-extension "$e" >/dev/null 2>&1; done
    ok "VS Code extensions installed"
  fi
}

check_only() {
  section "Tools"
  local t
  for t in git node npm code; do
    if linux_have "$t"; then printf "   %s✔%s %-5s %s\n" "$G" "$N" "$t" "$($t --version 2>/dev/null | head -n1)"
    elif have "$t"; then printf "   %s!%s %-5s Windows version only (%s)\n" "$Y" "$N" "$t" "$(command -v "$t")"
    else printf "   %s✖%s %-5s not installed\n" "$R" "$N" "$t"; fi
  done
  section "Project"
  for t in "$APP_DIR/package.json" "$APP_DIR/node_modules" "$APP_DIR/.env" "$APP_DIR/src/api/client.ts"; do
    [ -e "$t" ] && printf "   ✔ %s\n" "$t" || printf "   ✖ %s missing\n" "$t"
  done
}

# ---------- menu / flags -----------------------------------------------------------
if [ $# -eq 0 ]; then
  printf "\n%sCivicGuide – frontend setup (Vue 3 MVP)%s\n\n" "$B" "$N"
  printf "  1) All         – tools + Vue app\n  2) Tools only  – Git, Node.js LTS, npm\n  3) App only    – create / install /web, .env, starter files\n  4) Check only  – show what is installed\n  0) Exit\n\n"
  read -r -p "Choose [1]: " c; c="${c:-1}"
  case "$c" in 1) DO_TOOLS=1; DO_APP=1 ;; 2) DO_TOOLS=1 ;; 3) DO_APP=1 ;; 4) DO_CHECK=1 ;; 0) exit 0 ;; *) echo "Unknown option"; exit 1 ;; esac
else
  for a in "$@"; do
    case "$a" in
      --all) DO_TOOLS=1; DO_APP=1 ;; --tools) DO_TOOLS=1 ;; --app) DO_APP=1 ;; --check) DO_CHECK=1 ;;
      -y|--yes) ASSUME_YES=1 ;; -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) echo "Unknown flag: $a (see --help)"; exit 1 ;;
    esac
  done
fi

load_nvm
if [ "$DO_CHECK" -eq 1 ]; then check_only; exit 0; fi

section "System: $OS ($PKG)$([ "$IS_WSL" -eq 1 ] && echo ' – WSL')"
[ "$DO_TOOLS" -eq 1 ] && { ensure_system; wsl_checks; ensure_node; }
[ "$DO_APP" -eq 1 ] && setup_app

section "Summary"
for l in "${SUMMARY[@]}"; do info "$l"; done
cat <<EOF

${B}Start the app${N}
   cd $APP_DIR && npm run dev        → http://localhost:5173

${B}Later, when the backend exists${N}
   set VITE_USE_MOCK=false and VITE_API_URL=<api url> in $APP_DIR/.env

New terminal and 'node' not found?  source ~/.nvm/nvm.sh
EOF