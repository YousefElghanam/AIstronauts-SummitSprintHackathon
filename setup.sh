#!/usr/bin/env bash
# =============================================================================
#  CivicGuide – local setup script (macOS / Linux / WSL)
#
#  Installs missing tools, updates the ones you already have, and prepares
#  the project (frontend, backend, database, AI/data) so the team can start fast.
#
#  Usage:
#    ./setup.sh                 # interactive menu
#    ./setup.sh --all           # everything, no menu
#    ./setup.sh --frontend --db # pick parts directly
#    ./setup.sh --check         # only show what is installed
#    Add -y to answer "yes" to every question.
#
#  Flags: --all --core --frontend --backend --db --ai --extras --check -y --help
# =============================================================================

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

NODE_MIN_MAJOR=20
NVM_VERSION="v0.40.1"
DB_USER="hack"; DB_PASS="hack"; DB_NAME="civicguide"; DB_PORT="5432"

ASSUME_YES=0
DO_CORE=0; DO_FRONTEND=0; DO_BACKEND=0; DO_DB=0; DO_AI=0; DO_EXTRAS=0; DO_CHECK=0
SUMMARY=()

# ---------- pretty output ------------------------------------------------------
if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_BLUE=$'\033[34m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET=""; C_BOLD=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""
fi
section() { printf "\n%s==> %s%s\n" "$C_BOLD$C_BLUE" "$1" "$C_RESET"; }
info()    { printf "   %s\n" "$1"; }
ok()      { printf "   %s✔ %s%s\n" "$C_GREEN" "$1" "$C_RESET"; SUMMARY+=("✔ $1"); }
warn()    { printf "   %s! %s%s\n" "$C_YELLOW" "$1" "$C_RESET"; SUMMARY+=("! $1"); }
fail()    { printf "   %s✖ %s%s\n" "$C_RED" "$1" "$C_RESET"; SUMMARY+=("✖ $1"); }
have()    { command -v "$1" >/dev/null 2>&1; }

ask_yn() { # ask_yn "Question?" [default y|n]
  local q="$1" def="${2:-y}" ans
  if [ "$ASSUME_YES" -eq 1 ]; then return 0; fi
  local hint="[Y/n]"; [ "$def" = "n" ] && hint="[y/N]"
  read -r -p "   ? $q $hint " ans
  ans="${ans:-$def}"
  [[ "$ans" =~ ^[Yy] ]]
}

# ---------- OS / package manager ----------------------------------------------
OS="$(uname -s)"
PKG=""
detect_pkg() {
  if [ "$OS" = "Darwin" ]; then PKG="brew"
  elif have apt-get; then PKG="apt"
  elif have dnf; then PKG="dnf"
  elif have pacman; then PKG="pacman"
  else PKG="unknown"; fi
}
SUDO=""; [ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"
APT_UPDATED=0
IS_WSL=0; grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1

# In WSL the Windows PATH is appended, so `node` may be the Windows node.exe
# under /mnt/c/... – that one breaks native modules and file watching.
linux_have() { local p; p="$(command -v "$1" 2>/dev/null)" || return 1; [[ "$p" != /mnt/* ]]; }

wsl_checks() {
  [ "$IS_WSL" -eq 1 ] || return 0
  section "WSL checks"
  if [[ "$ROOT" == /mnt/* ]]; then
    warn "Project is on the Windows drive ($ROOT). npm installs will be very slow and hot-reload may not work."
    info "Recommended: clone the repo inside WSL instead, e.g.  mkdir -p ~/projects && cd ~/projects && git clone <repo-url>"
    ask_yn "Continue anyway?" n || exit 1
  else
    ok "Project is on the Linux filesystem (fast)"
  fi
  if grep -q $'\r' "$0" 2>/dev/null; then
    warn "This script has Windows line endings (CRLF). Run: sed -i 's/\\r\$//' setup.sh"
  fi
  if have git; then
    git config --global core.autocrlf input && ok "git core.autocrlf=input (avoids CRLF problems)"
  fi
  if [ ! -f .gitattributes ]; then
    printf '* text=auto eol=lf\n*.sh text eol=lf\n*.ps1 text eol=crlf\n' > .gitattributes
    ok "Created .gitattributes (consistent LF line endings for the team)"
  fi
}

ensure_base_packages() {
  [ "$PKG" = "apt" ] || return 0
  section "Base system packages"
  $SUDO apt-get update -y >/dev/null && APT_UPDATED=1
  if $SUDO apt-get install -y curl ca-certificates build-essential unzip >/dev/null; then
    ok "curl, ca-certificates, build-essential, unzip"
  else
    warn "Could not install base packages (curl/build-essential)"
  fi
}

ensure_brew() {
  [ "$PKG" != "brew" ] && return 0
  if have brew; then
    info "Updating Homebrew..."; brew update >/dev/null || warn "brew update failed"
  else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { fail "Homebrew install failed"; return 1; }
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# pkg_install_or_upgrade <command> <package-name>
pkg_install_or_upgrade() {
  local cmd="$1" pkg="$2"
  case "$PKG" in
    brew)
      if brew list "$pkg" >/dev/null 2>&1; then brew upgrade "$pkg" >/dev/null 2>&1 || true
      else brew install "$pkg"; fi ;;
    apt)
      [ "$APT_UPDATED" -eq 0 ] && { $SUDO apt-get update -y >/dev/null; APT_UPDATED=1; }
      $SUDO apt-get install -y "$pkg" >/dev/null ;;
    dnf)    $SUDO dnf install -y "$pkg" >/dev/null || $SUDO dnf upgrade -y "$pkg" >/dev/null ;;
    pacman) $SUDO pacman -S --noconfirm --needed "$pkg" >/dev/null ;;
    *) return 1 ;;
  esac
  have "$cmd"
}

# ---------- tools ---------------------------------------------------------------
ensure_git() {
  section "Git"
  local had=0; have git && had=1
  if pkg_install_or_upgrade git git; then
    [ $had -eq 1 ] && ok "Git up to date ($(git --version | awk '{print $3}'))" \
                   || ok "Git installed ($(git --version | awk '{print $3}'))"
  else
    have git && warn "Could not update Git, keeping $(git --version)" || fail "Git install failed – see https://git-scm.com/downloads"
  fi
}

load_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}

node_major() { node -v 2>/dev/null | sed 's/^v//' | cut -d. -f1; }

ensure_node() {
  section "Node.js (LTS, >= $NODE_MIN_MAJOR) + npm"
  load_nvm
  if have node && ! linux_have node; then
    warn "Found Windows Node.js ($(command -v node)) – installing a Linux Node inside WSL instead"
  fi
  if ! have nvm; then
    if linux_have node && [ "$(node_major)" -ge "$NODE_MIN_MAJOR" ]; then
      ok "Node $(node -v) found (not managed by nvm – keeping it)"
      info "Updating npm..."; npm install -g npm@latest >/dev/null 2>&1 || warn "npm self-update skipped (may need sudo)"
      return 0
    fi
    info "Installing nvm $NVM_VERSION (Node version manager)..."
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash >/dev/null 2>&1 \
      || { fail "nvm install failed – install Node $NODE_MIN_MAJOR+ from https://nodejs.org"; return 1; }
    load_nvm
  fi
  local before; before="$(node -v 2>/dev/null || echo none)"
  info "Installing / updating Node LTS via nvm (current: $before)..."
  if [ "$before" != "none" ]; then
    nvm install --lts --latest-npm --reinstall-packages-from=current >/dev/null 2>&1 || nvm install --lts --latest-npm >/dev/null 2>&1
  else
    nvm install --lts --latest-npm >/dev/null 2>&1
  fi
  nvm alias default 'lts/*' >/dev/null 2>&1; nvm use default >/dev/null 2>&1
  hash -r
  if linux_have node && [ "$(node_major)" -ge "$NODE_MIN_MAJOR" ]; then
    ok "Node $(node -v), npm $(npm -v)"
  else
    fail "Node setup failed"
  fi
}

ensure_docker() {
  section "Docker + Docker Compose"
  if [ "$PKG" = "brew" ]; then
    if brew list --cask docker >/dev/null 2>&1; then brew upgrade --cask docker >/dev/null 2>&1 || true
    elif ! have docker; then
      info "Installing Docker Desktop..."; brew install --cask docker || { fail "Docker Desktop install failed"; return 1; }
      info "Open Docker Desktop once from Applications to finish setup."
    fi
  elif ! have docker && [ "$IS_WSL" -eq 1 ]; then
    warn "Docker not found in WSL."
    info "Recommended: install Docker Desktop on Windows (https://www.docker.com/products/docker-desktop/),"
    info "then Settings → Resources → WSL Integration → enable your distro, and re-run this script."
    if ask_yn "Or install Docker Engine directly inside WSL instead?" n; then
      curl -fsSL https://get.docker.com | $SUDO sh || { fail "Docker install failed"; return 1; }
      $SUDO usermod -aG docker "$USER" 2>/dev/null && warn "Added $USER to 'docker' group – run 'wsl --shutdown' in Windows and reopen WSL"
      $SUDO service docker start >/dev/null 2>&1 || true
    else
      return 1
    fi
  elif ! have docker; then
    if ask_yn "Docker not found. Install it with the official script (get.docker.com)?"; then
      curl -fsSL https://get.docker.com | $SUDO sh || { fail "Docker install failed"; return 1; }
      $SUDO usermod -aG docker "$USER" 2>/dev/null && warn "Added $USER to 'docker' group – log out/in for it to take effect"
    else
      warn "Skipped Docker – the database will not work without it"; return 1
    fi
  else
    pkg_install_or_upgrade docker docker-ce >/dev/null 2>&1 || true
  fi

  if ! have docker; then fail "Docker not available"; return 1; fi
  if ! docker compose version >/dev/null 2>&1; then
    fail "'docker compose' plugin missing – install docker-compose-plugin"; return 1
  fi
  if ! docker info >/dev/null 2>&1 && ! $SUDO docker info >/dev/null 2>&1; then
    if [ "$IS_WSL" -eq 1 ]; then
      $SUDO service docker start >/dev/null 2>&1 || true; sleep 2
    fi
    if ! docker info >/dev/null 2>&1 && ! $SUDO docker info >/dev/null 2>&1; then
      if [ "$IS_WSL" -eq 1 ]; then
        warn "Docker is not running – start Docker Desktop on Windows (with WSL Integration on) and re-run"
      else
        warn "Docker is installed but not running – start Docker Desktop / 'sudo systemctl start docker'"
      fi
      return 1
    fi
  fi
  ok "Docker $(docker --version | awk '{print $3}' | tr -d ,) with Compose $(docker compose version --short 2>/dev/null)"
}

DOCKER="docker"
pick_docker_cmd() { docker info >/dev/null 2>&1 || DOCKER="$SUDO docker"; }

npm_global() { # npm_global <command> <package>
  local cmd="$1" pkg="$2"
  have npm || { fail "npm missing – run Core first"; return 1; }
  if npm install -g "$pkg@latest" >/dev/null 2>&1; then
    ok "$pkg $( $cmd --version 2>/dev/null | head -n1 )"
  else
    fail "Could not install $pkg (try: npm install -g $pkg)"
  fi
}

# ---------- helpers for project files -------------------------------------------
set_env_var() { # set_env_var <file> <KEY> <value>
  local file="$1" key="$2" value="$3"
  touch "$file"
  if grep -q "^${key}=" "$file"; then
    awk -v k="$key" -v v="$value" 'BEGIN{FS=OFS="="} $1==k{print k"="v; next} {print}' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  else
    [ -s "$file" ] && [ -n "$(tail -c1 "$file")" ] && printf "\n" >> "$file"
    printf "%s=%s\n" "$key" "$value" >> "$file"
  fi
}
get_env_var() { grep -E "^$2=" "$1" 2>/dev/null | head -n1 | cut -d= -f2-; }

# ---------- project parts ---------------------------------------------------------
setup_database() {
  section "Database (PostgreSQL + pgvector)"
  have docker || { fail "Docker missing – cannot start database"; return 1; }
  pick_docker_cmd
  if [ ! -f docker-compose.yml ]; then
    cat > docker-compose.yml <<EOF
services:
  db:
    image: pgvector/pgvector:pg16
    restart: unless-stopped
    environment:
      POSTGRES_USER: $DB_USER
      POSTGRES_PASSWORD: $DB_PASS
      POSTGRES_DB: $DB_NAME
    ports: ["$DB_PORT:5432"]
    volumes: ["pgdata:/var/lib/postgresql/data"]
volumes:
  pgdata:
EOF
    ok "Created docker-compose.yml"
  fi
  info "Pulling latest image and starting container..."
  $DOCKER compose pull db >/dev/null 2>&1 || true
  $DOCKER compose up -d db >/dev/null || { fail "Could not start database container (is port $DB_PORT free?)"; return 1; }
  info "Waiting for Postgres to be ready..."
  local i
  for i in $(seq 1 30); do
    $DOCKER compose exec -T db pg_isready -U "$DB_USER" >/dev/null 2>&1 && break
    sleep 1
  done
  if $DOCKER compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;" >/dev/null 2>&1; then
    ok "Postgres running on localhost:$DB_PORT (db: $DB_NAME, user: $DB_USER) with pgvector"
  else
    fail "Postgres did not become ready – check: docker compose logs db"
  fi
}

setup_frontend() {
  section "Frontend (Vue 3 in /web)"
  have npm || { fail "npm missing – run Core first"; return 1; }
  if [ ! -f web/package.json ]; then
    if ask_yn "No /web app found. Scaffold a new Vue 3 + TypeScript app now?"; then
      npm create vue@latest web -- --ts --router --pinia --eslint
      [ -f web/package.json ] || { fail "Vue scaffold failed"; return 1; }
      ( cd web && npm install >/dev/null \
        && npm install primevue @primevue/themes ai @ai-sdk/vue >/dev/null \
        && npm install -D tailwindcss @tailwindcss/vite >/dev/null ) \
        && ok "Scaffolded Vue app + PrimeVue, Tailwind, AI SDK" \
        || warn "Scaffolded, but some extra packages failed to install"
      info "Remember: add tailwindcss() to plugins in web/vite.config.ts"
    else
      warn "Skipped frontend scaffold"; return 0
    fi
  fi
  info "Installing frontend dependencies..."
  ( cd web && npm install >/dev/null ) && ok "web/ dependencies installed" || { fail "npm install failed in web/"; return 1; }
  if [ ! -f web/.env ]; then
    if [ -f web/.env.example ]; then cp web/.env.example web/.env; else printf "VITE_API_URL=http://localhost:3333\n" > web/.env; fi
    [ -f web/.env.example ] || cp web/.env web/.env.example
    ok "Created web/.env"
  fi
}

# New AdonisJS starter kits default to SQLite – switch config + env validation to Postgres.
switch_adonis_to_postgres() {
  cat > api/config/database.ts <<'EOF'
import app from '@adonisjs/core/services/app'
import env from '#start/env'
import { defineConfig } from '@adonisjs/lucid'

const dbConfig = defineConfig({
  connection: 'pg',
  connections: {
    pg: {
      client: 'pg',
      connection: {
        host: env.get('DB_HOST'),
        port: env.get('DB_PORT'),
        user: env.get('DB_USER'),
        password: env.get('DB_PASSWORD'),
        database: env.get('DB_DATABASE'),
      },
      migrations: {
        naturalSort: true,
        paths: ['database/migrations'],
      },
      debug: app.inDev,
    },
  },
})

export default dbConfig
EOF
  node - <<'EOF' && ok "Switched AdonisJS to PostgreSQL" || warn "Could not patch api/start/env.ts – add DB_* vars manually"
const fs = require('fs')
const f = 'api/start/env.ts'
let s = fs.readFileSync(f, 'utf8')
if (!s.includes('DB_HOST')) {
  const add = `
  // Database
  DB_HOST: Env.schema.string({ format: 'host' }),
  DB_PORT: Env.schema.number(),
  DB_USER: Env.schema.string(),
  DB_PASSWORD: Env.schema.string.optional(),
  DB_DATABASE: Env.schema.string(),

  // AI
  LLM_PROVIDER: Env.schema.string.optional(),
  ANTHROPIC_API_KEY: Env.schema.string.optional(),
  CORS_ORIGIN: Env.schema.string.optional(),
`
  const i = s.lastIndexOf('})')
  if (i < 0) process.exit(1)
  s = s.slice(0, i) + add + s.slice(i)
  fs.writeFileSync(f, s)
}
EOF
}

setup_backend() {
  section "Backend (AdonisJS in /api)"
  have npm || { fail "npm missing – run Core first"; return 1; }
  if [ ! -f api/package.json ]; then
    if ask_yn "No /api app found. Scaffold a new AdonisJS API (Postgres) now?"; then
      npm init adonisjs@latest api -- --kit=api --skip-migrations
      [ -f api/ace.js ] || { fail "AdonisJS scaffold failed (no api/ace.js)"; return 1; }
      [ -d api/.git ] && rm -rf api/.git
      ( cd api && npm install pg @anthropic-ai/sdk pgvector >/dev/null ) \
        && ok "Scaffolded AdonisJS API + pg, Anthropic SDK, pgvector" \
        || warn "Scaffolded, but extra packages failed to install"
      switch_adonis_to_postgres
    else
      warn "Skipped backend scaffold"; return 0
    fi
  fi
  info "Installing backend dependencies..."
  ( cd api && npm install >/dev/null ) && ok "api/ dependencies installed" || { fail "npm install failed in api/"; return 1; }

  if [ ! -f api/.env ]; then
    [ -f api/.env.example ] && cp api/.env.example api/.env || touch api/.env
  fi
  set_env_var api/.env DB_HOST 127.0.0.1
  set_env_var api/.env DB_PORT "$DB_PORT"
  set_env_var api/.env DB_USER "$DB_USER"
  set_env_var api/.env DB_PASSWORD "$DB_PASS"
  set_env_var api/.env DB_DATABASE "$DB_NAME"
  [ -z "$(get_env_var api/.env CORS_ORIGIN)" ] && set_env_var api/.env CORS_ORIGIN http://localhost:5173
  if [ -z "$(get_env_var api/.env APP_KEY)" ] && [ -f api/ace.js ]; then
    ( cd api && node ace generate:key >/dev/null 2>&1 ) && ok "Generated APP_KEY"
  fi
  ok "api/.env configured for local database"

  if [ -f api/ace.js ] && have docker && docker compose ps db 2>/dev/null | grep -q "running\|Up"; then
    info "Running migrations..."
    ( cd api && node ace migration:run >/dev/null 2>&1 ) && ok "Migrations applied" || warn "Migrations failed – run 'cd api && node ace migration:run' to see why"
  else
    warn "Database not running – skipped migrations"
  fi
}

setup_ai() {
  section "AI / Data"
  mkdir -p data/sources data/workflows data/scripts
  if [ ! -f data/workflows/address_change.json ]; then
    cat > data/workflows/address_change.json <<'EOF'
{
  "service": "address_change",
  "title": "Register a new address",
  "steps": [
    { "id": "collect", "fields": ["fullName", "newAddress", "moveDate", "idCardNumber"] },
    { "id": "documents", "required": ["ID card", "Proof of residence"] },
    { "id": "review" },
    { "id": "submit", "action": "mockGov.registerAddress" }
  ],
  "deadlineDays": 3
}
EOF
    ok "Created sample workflow data/workflows/address_change.json"
  fi
  ok "data/ folders ready (put official PDFs/pages in data/sources)"

  if [ ! -f api/package.json ]; then
    warn "No /api app yet – run Backend first, then AI/Data again to store the API key"
  else
  set_env_var api/.env LLM_PROVIDER "$(get_env_var api/.env LLM_PROVIDER | grep . || echo anthropic)"
  if [ -n "$(get_env_var api/.env ANTHROPIC_API_KEY)" ]; then
    ok "ANTHROPIC_API_KEY already set in api/.env"
  elif [ "$ASSUME_YES" -eq 0 ] && ask_yn "Paste your LLM API key now? (stored only in api/.env)" n; then
    local key; read -r -s -p "   Key: " key; echo
    if [ -n "$key" ]; then set_env_var api/.env ANTHROPIC_API_KEY "$key"; ok "API key saved to api/.env"; fi
  else
    set_env_var api/.env ANTHROPIC_API_KEY ""
    warn "ANTHROPIC_API_KEY is empty – add it to api/.env (ask your team lead)"
  fi
  fi

  # make sure secrets never get committed
  touch .gitignore
  for p in ".env" "*.env.local" "node_modules/" ".DS_Store"; do
    grep -qxF "$p" .gitignore || echo "$p" >> .gitignore
  done
  grep -qxF '!.env.example' .gitignore || echo '!.env.example' >> .gitignore
  ok ".gitignore protects .env files"
}

setup_extras() {
  section "Dev extras"
  if pkg_install_or_upgrade gh gh; then ok "GitHub CLI $(gh --version | head -n1 | awk '{print $3}') (run 'gh auth login' once)"
  else warn "GitHub CLI not installed – see https://cli.github.com"; fi
  npm_global vercel vercel
  npm_global railway @railway/cli

  mkdir -p .vscode
  local exts=(Vue.volar dbaeumer.vscode-eslint esbenp.prettier-vscode bradlc.vscode-tailwindcss jripouteau.adonis-vscode-extension ms-azuretools.vscode-docker)
  if [ ! -f .vscode/extensions.json ]; then
    printf '{\n  "recommendations": [\n' > .vscode/extensions.json
    local i last=$(( ${#exts[@]} - 1 ))
    for i in "${!exts[@]}"; do
      printf '    "%s"%s\n' "${exts[$i]}" "$([ "$i" -lt "$last" ] && echo ,)" >> .vscode/extensions.json
    done
    printf '  ]\n}\n' >> .vscode/extensions.json
    ok "Created .vscode/extensions.json (recommended extensions)"
  fi
  if have code; then
    local e; for e in "${exts[@]}"; do code --install-extension "$e" --force >/dev/null 2>&1; done
    ok "VS Code extensions installed/updated"
  else
    info "VS Code CLI 'code' not found – open the repo in VS Code and accept the recommended extensions"
  fi
}

check_only() {
  section "Installed tools"
  local t
  for t in git node npm docker gh vercel railway code; do
    if have "$t"; then printf "   %s✔%s %-8s %s\n" "$C_GREEN" "$C_RESET" "$t" "$($t --version 2>/dev/null | head -n1)"
    else printf "   %s✖%s %-8s not installed\n" "$C_RED" "$C_RESET" "$t"; fi
  done
  have docker && docker compose version >/dev/null 2>&1 && printf "   %s✔%s %-8s %s\n" "$C_GREEN" "$C_RESET" "compose" "$(docker compose version --short)"
  section "Project"
  for t in web/package.json api/package.json docker-compose.yml api/.env web/.env; do
    [ -e "$t" ] && printf "   ✔ %s\n" "$t" || printf "   ✖ %s missing\n" "$t"
  done
}

# ---------- menu / args ---------------------------------------------------------------
usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

show_menu() {
  printf "\n%sCivicGuide setup%s – what do you want to set up?\n\n" "$C_BOLD" "$C_RESET"
  cat <<'EOF'
  1) All           – everything below
  2) Core tools    – Git, Node.js LTS + npm, Docker
  3) Frontend      – Vue 3 app in /web (deps, .env)
  4) Backend       – AdonisJS API in /api (deps, .env, migrations) + database
  5) Database      – PostgreSQL + pgvector in Docker
  6) AI / Data     – API key, /data folders, sample workflow, .gitignore
  7) Dev extras    – GitHub CLI, Vercel & Railway CLIs, VS Code extensions
  8) Check only    – show what is installed, change nothing
  0) Exit

EOF
  local choice c
  read -r -p "Choose one or more (e.g. \"3 5\"): " choice
  [ -z "$choice" ] && choice=1
  for c in ${choice//,/ }; do
    case "$c" in
      1) DO_CORE=1; DO_FRONTEND=1; DO_BACKEND=1; DO_DB=1; DO_AI=1; DO_EXTRAS=1 ;;
      2) DO_CORE=1 ;; 3) DO_FRONTEND=1 ;; 4) DO_BACKEND=1 ;; 5) DO_DB=1 ;;
      6) DO_AI=1 ;; 7) DO_EXTRAS=1 ;; 8) DO_CHECK=1 ;; 0) exit 0 ;;
      *) printf "Unknown option: %s\n" "$c"; exit 1 ;;
    esac
  done
}

if [ $# -eq 0 ]; then
  show_menu
else
  for arg in "$@"; do
    case "$arg" in
      --all) DO_CORE=1; DO_FRONTEND=1; DO_BACKEND=1; DO_DB=1; DO_AI=1; DO_EXTRAS=1 ;;
      --core) DO_CORE=1 ;; --frontend) DO_FRONTEND=1 ;; --backend) DO_BACKEND=1 ;;
      --db) DO_DB=1 ;; --ai) DO_AI=1 ;; --extras) DO_EXTRAS=1 ;; --check) DO_CHECK=1 ;;
      -y|--yes) ASSUME_YES=1 ;; -h|--help) usage ;;
      *) echo "Unknown flag: $arg (see --help)"; exit 1 ;;
    esac
  done
fi

if [ "$DO_CHECK" -eq 1 ]; then load_nvm; check_only; exit 0; fi

# ---------- resolve dependencies --------------------------------------------------
NEED_GIT=0; NEED_NODE=0; NEED_DOCKER=0
[ $DO_CORE -eq 1 ]     && { NEED_GIT=1; NEED_NODE=1; NEED_DOCKER=1; }
[ $DO_FRONTEND -eq 1 ] && { NEED_GIT=1; NEED_NODE=1; }
[ $DO_BACKEND -eq 1 ]  && { NEED_GIT=1; NEED_NODE=1; NEED_DOCKER=1; DO_DB=1; }
[ $DO_DB -eq 1 ]       && NEED_DOCKER=1
[ $DO_EXTRAS -eq 1 ]   && NEED_NODE=1

detect_pkg
section "System: $OS ($PKG) – project root: $ROOT"
[ "$IS_WSL" -eq 1 ] && info "Running inside WSL"
if [ "$PKG" = "unknown" ]; then warn "No supported package manager found – tools must be installed manually"; fi
[ "$PKG" = "brew" ] && ensure_brew
ensure_base_packages
wsl_checks

[ $NEED_GIT -eq 1 ]    && ensure_git
[ $NEED_NODE -eq 1 ]   && ensure_node
[ $NEED_DOCKER -eq 1 ] && ensure_docker
[ $DO_DB -eq 1 ]       && setup_database
[ $DO_FRONTEND -eq 1 ] && setup_frontend
[ $DO_BACKEND -eq 1 ]  && setup_backend
[ $DO_AI -eq 1 ]       && setup_ai
[ $DO_EXTRAS -eq 1 ]   && setup_extras

# ---------- summary ------------------------------------------------------------------
section "Summary"
for line in "${SUMMARY[@]}"; do info "$line"; done
cat <<EOF

${C_BOLD}Next steps${C_RESET}
   Backend:   cd api && node ace serve --hmr     → http://localhost:3333
   Frontend:  cd web && npm run dev              → http://localhost:5173
   Database:  docker compose up -d db | docker compose logs db
   New terminal? If 'node' is missing, run: source ~/.nvm/nvm.sh
EOF