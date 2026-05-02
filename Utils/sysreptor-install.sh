#!/usr/bin/env bash
# SysReptor - Installation script for macOS with OrbStack
# Usage: bash ~/sysreptor-install.sh

set -euo pipefail

INSTALL_DIR="$HOME/sysreptor"
DEPLOY_DIR="$INSTALL_DIR/deploy"
ADMIN_USER="reptor"
ADMIN_PASS="SOMETHING"

# ── colors ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
die()     { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

# ── prerequisites ──────────────────────────────────────────────────────────────
check_deps() {
  info "Checking dependencies..."
  command -v docker  >/dev/null || die "Docker not found. Install OrbStack."
  command -v gh      >/dev/null || die "gh CLI not found. Install with: brew install gh"
  command -v openssl >/dev/null || die "openssl not found."
  command -v uuidgen >/dev/null || die "uuidgen not found."
  docker info >/dev/null 2>&1   || die "Docker is not running. Open OrbStack."
  info "Dependencies OK."
}

# ── optional cleanup ───────────────────────────────────────────────────────────
cleanup_existing() {
  if [ -d "$INSTALL_DIR" ] || docker volume ls -q | grep -q "sysreptor"; then
    warn "Existing installation detected."
    read -r -p "Remove existing installation and data? [y/N] " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      info "Stopping containers..."
      docker compose -f "$DEPLOY_DIR/docker-compose.yml" down 2>/dev/null || true
      info "Removing volumes..."
      docker volume rm sysreptor-db-data sysreptor-app-data 2>/dev/null || true
      info "Removing directory..."
      rm -rf "$INSTALL_DIR" ~/sysreptor.tar.gz
    else
      die "Installation cancelled. Remove the existing installation manually before retrying."
    fi
  fi
}

# ── download ───────────────────────────────────────────────────────────────────
download_sysreptor() {
  info "Downloading SysReptor via gh CLI..."
  gh release download \
    --repo syslifters/sysreptor \
    --pattern "setup.tar.gz" \
    --output "$HOME/sysreptor.tar.gz" \
    --clobber

  info "Extracting files..."
  tar xzf "$HOME/sysreptor.tar.gz" -C "$HOME"
  rm "$HOME/sysreptor.tar.gz"
}

# ── configuration ──────────────────────────────────────────────────────────────
configure_env() {
  info "Generating security keys..."
  cd "$DEPLOY_DIR"

  SECRET_KEY=$(openssl rand -base64 64 | tr -d '\n=')
  KEY_ID=$(uuidgen)
  AES_KEY=$(openssl rand -base64 32)

  sed -i '' "s|^SECRET_KEY=.*|SECRET_KEY=\"${SECRET_KEY}\"|" app.env

  sed -i '' \
    "s|^# ENCRYPTION_KEYS=.*|ENCRYPTION_KEYS='[{\"id\": \"${KEY_ID}\", \"key\": \"${AES_KEY}\", \"cipher\": \"AES-GCM\", \"revoked\": false}]'|" \
    app.env
  sed -i '' \
    "s|^# DEFAULT_ENCRYPTION_KEY_ID=.*|DEFAULT_ENCRYPTION_KEY_ID=\"${KEY_ID}\"|" \
    app.env

  info "app.env configured."
}

# ── containers ─────────────────────────────────────────────────────────────────
start_containers() {
  info "Creating Docker volumes..."
  docker volume create sysreptor-db-data
  docker volume create sysreptor-app-data

  info "Starting containers..."
  cd "$DEPLOY_DIR"
  docker compose up -d

  info "Waiting for app to become healthy..."
  for i in $(seq 1 30); do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' sysreptor-app 2>/dev/null || echo "starting")
    if [ "$STATUS" = "healthy" ]; then
      info "App is ready!"
      return 0
    fi
    echo -n "."
    sleep 5
  done
  echo ""
  die "Timeout: app did not become healthy within 150s. Check: docker compose logs app"
}

# ── admin user ─────────────────────────────────────────────────────────────────
create_admin() {
  info "Creating admin user '${ADMIN_USER}'..."
  cd "$DEPLOY_DIR"

  docker compose exec app python3 manage.py createsuperuser \
    --username "$ADMIN_USER" --noinput 2>/dev/null || true

  docker compose exec app python3 manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
u = User.objects.get(username='${ADMIN_USER}')
u.set_password('${ADMIN_PASS}')
u.save()
print('Password set.')
" 2>/dev/null | grep -E "Password|Error" || true
}

# ── demo data ──────────────────────────────────────────────────────────────────
import_demo_data() {
  info "Importing demo data..."
  cd "$DEPLOY_DIR"
  local base_url="https://docs.sysreptor.com/assets"

  for type in designs templates projects; do
    echo -n "  → $type... "
    local extra=""
    [ "$type" = "projects" ] && extra="--add-member=${ADMIN_USER}"
    curl -sL "${base_url}/demo-${type}.tar.gz" \
      | docker compose exec --no-TTY app python3 manage.py importdemodata \
          --type="${type%s}" $extra 2>/dev/null
    echo "OK"
  done

  info "Importing Hack The Box data..."
  echo -n "  → htb designs... "
  curl -sL "${base_url}/htb-designs.tar.gz" \
    | docker compose exec --no-TTY app python3 manage.py importdemodata \
        --type=design 2>/dev/null
  echo "OK"

  echo -n "  → htb projects... "
  curl -sL "${base_url}/htb-demo-projects.tar.gz" \
    | docker compose exec --no-TTY app python3 manage.py importdemodata \
        --type=project --add-member="${ADMIN_USER}" 2>/dev/null
  echo "OK"
}

# ── main ───────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║   SysReptor — Installation for macOS    ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""

  check_deps
  cleanup_existing
  download_sysreptor
  configure_env
  start_containers
  create_admin
  import_demo_data

  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║         Installation complete!           ║"
  echo "╠══════════════════════════════════════════╣"
  echo "║  URL:      http://127.0.0.1:8000/        ║"
  echo "║  Username: ${ADMIN_USER}                       ║"
  echo "║  Password: ${ADMIN_PASS}           ║"
  echo "╠══════════════════════════════════════════╣"
  echo "║  Change your password after first login! ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
  echo "  Start:  cd ~/sysreptor/deploy && docker compose up -d"
  echo "  Stop:   cd ~/sysreptor/deploy && docker compose stop"
  echo ""
}

main "$@"
