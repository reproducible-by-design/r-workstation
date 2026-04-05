#!/usr/bin/env bash
# r-workstation setup
# A modern R development environment: terminal, editor, and reproducible environments.
#
# Usage: ./setup.sh [--all | --terminal | --editor | --environment | --help]
#
# Each layer can be run independently. Running without arguments installs all layers.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { printf "\033[0;34m[setup]\033[0m %s\n" "$1"; }
ok()    { printf "\033[0;32m[setup]\033[0m %s\n" "$1"; }
error() { printf "\033[0;31m[setup]\033[0m %s\n" "$1" >&2; }

usage() {
    cat <<EOF
Usage: ./setup.sh [OPTIONS]

Options:
  --all           Install all layers (default)
  --terminal      Layer 1: Zsh + Oh My Zsh + plugins
  --editor        Layer 2: VS Code + Jupyter extension
  --environment   Layer 3: Conda/Mamba + R environment
  --help          Show this message

Layers can be combined: ./setup.sh --terminal --environment

For more information, see README.md.
EOF
}

run_layer() {
    local script="$SCRIPT_DIR/layers/$1"
    if [ ! -f "$script" ]; then
        error "Layer script not found: $script"
        return 1
    fi
    bash "$script"
}

# ── Parse arguments ──────────────────────────────────────────────────────────

RUN_TERMINAL=false
RUN_EDITOR=false
RUN_ENVIRONMENT=false
ANY_SELECTED=false

if [ $# -eq 0 ]; then
    RUN_TERMINAL=true
    RUN_EDITOR=true
    RUN_ENVIRONMENT=true
    ANY_SELECTED=true
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --all)
            RUN_TERMINAL=true
            RUN_EDITOR=true
            RUN_ENVIRONMENT=true
            ANY_SELECTED=true
            ;;
        --terminal)
            RUN_TERMINAL=true
            ANY_SELECTED=true
            ;;
        --editor)
            RUN_EDITOR=true
            ANY_SELECTED=true
            ;;
        --environment)
            RUN_ENVIRONMENT=true
            ANY_SELECTED=true
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

if [ "$ANY_SELECTED" = false ]; then
    usage
    exit 1
fi

# ── System info ──────────────────────────────────────────────────────────────

OS="$(uname -s)"
ARCH="$(uname -m)"

echo ""
info "r-workstation setup"
info "OS: $OS | Arch: $ARCH"
echo ""

# ── Run selected layers ─────────────────────────────────────────────────────

if [ "$RUN_TERMINAL" = true ]; then
    info "━━━ Layer 1: Terminal ━━━"
    run_layer "01-terminal.sh"
    echo ""
fi

if [ "$RUN_EDITOR" = true ]; then
    info "━━━ Layer 2: Editor ━━━"
    run_layer "02-editor.sh"
    echo ""
fi

if [ "$RUN_ENVIRONMENT" = true ]; then
    info "━━━ Layer 3: Environment ━━━"
    run_layer "03-environment.sh"
    echo ""
fi

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
ok "Setup complete."
info "You may need to restart your terminal for all changes to take effect."
