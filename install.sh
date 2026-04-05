#!/usr/bin/env bash
# Web installer for r-workstation
# Usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/reproducible-by-design/r-workstation/main/install.sh)"
#
# Pass arguments to setup.sh:
#   bash -c "$(curl -fsSL ...)" -- --terminal
#   bash -c "$(curl -fsSL ...)" -- --environment
set -euo pipefail

REPO_URL="https://github.com/reproducible-by-design/r-workstation.git"
INSTALL_DIR="${R_WORKSTATION_DIR:-$HOME/.r-workstation}"

info()  { printf "\033[0;34m[install]\033[0m %s\n" "$1"; }
ok()    { printf "\033[0;32m[install]\033[0m %s\n" "$1"; }
error() { printf "\033[0;31m[install]\033[0m %s\n" "$1" >&2; }

# ── Clone or update ──────────────────────────────────────────────────────────

if [ -d "$INSTALL_DIR/.git" ]; then
    info "Updating existing installation at $INSTALL_DIR..."
    if ! git -C "$INSTALL_DIR" pull --ff-only 2>/dev/null; then
        error "Could not update $INSTALL_DIR (local changes or network issue)."
        info "Continuing with the existing version."
    fi
else
    if [ -d "$INSTALL_DIR" ]; then
        error "$INSTALL_DIR already exists but is not a git repository."
        error "Remove it or set R_WORKSTATION_DIR to a different path."
        exit 1
    fi

    if ! command -v git &>/dev/null; then
        error "git is required. Please install git and try again."
        exit 1
    fi

    info "Cloning r-workstation to $INSTALL_DIR..."
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

ok "Repository ready at $INSTALL_DIR"

# ── Run setup ────────────────────────────────────────────────────────────────

cd "$INSTALL_DIR"
exec bash setup.sh "$@"
