#!/usr/bin/env bash
# Layer 2: Editor - VS Code + Jupyter extension
# Supports: Linux x64, macOS ARM
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

info()  { printf "\033[0;34m[editor]\033[0m %s\n" "$1"; }
ok()    { printf "\033[0;32m[editor]\033[0m %s\n" "$1"; }
warn()  { printf "\033[0;33m[editor]\033[0m %s\n" "$1"; }
error() { printf "\033[0;31m[editor]\033[0m %s\n" "$1" >&2; }

OS="$(uname -s)"
ARCH="$(uname -m)"

# ── VS Code ──────────────────────────────────────────────────────────────────

if command -v code &>/dev/null; then
    ok "VS Code is already installed: $(code --version | head -1)"
else
    info "Installing VS Code..."
    case "$OS" in
        Linux)
            if [ "$ARCH" != "x86_64" ]; then
                error "This script supports Linux x86_64 only. Detected: $ARCH"
                exit 1
            fi
            TEMP_DEB="$(mktemp /tmp/vscode-XXXXXX.deb)"
            info "Downloading VS Code .deb package..."
            curl -fsSL "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -o "$TEMP_DEB"
            info "Installing (this may ask for your password)..."
            sudo dpkg -i "$TEMP_DEB" || sudo apt-get install -f -y
            rm -f "$TEMP_DEB"
            ;;
        Darwin)
            if command -v brew &>/dev/null; then
                info "Installing via Homebrew..."
                brew install --cask visual-studio-code
            else
                error "Homebrew is not available. Please install VS Code manually from https://code.visualstudio.com"
                exit 1
            fi
            ;;
        *)
            error "Unsupported OS: $OS"
            exit 1
            ;;
    esac

    # Verify installation
    if command -v code &>/dev/null; then
        ok "VS Code installed: $(code --version | head -1)"
    else
        error "VS Code installation completed but 'code' command not found."
        error "You may need to restart your terminal or add VS Code to your PATH."
        exit 1
    fi
fi

# ── Extensions ───────────────────────────────────────────────────────────────

EXTENSIONS=(
    "ms-toolsai.jupyter"
    "ms-toolsai.vscode-jupyter-cell-tags"
    "ms-toolsai.vscode-jupyter-slideshow"
)

for ext in "${EXTENSIONS[@]}"; do
    if code --list-extensions 2>/dev/null | grep -qi "$ext"; then
        ok "Extension already installed: $ext"
    else
        info "Installing extension: $ext"
        code --install-extension "$ext" --force 2>/dev/null
        ok "Extension installed: $ext"
    fi
done

# ── VS Code settings ────────────────────────────────────────────────────────

case "$OS" in
    Linux)  VSCODE_SETTINGS_DIR="$HOME/.config/Code/User" ;;
    Darwin) VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User" ;;
esac

SOURCE_SETTINGS="$REPO_DIR/config/vscode/settings.json"
TARGET_SETTINGS="$VSCODE_SETTINGS_DIR/settings.json"

if [ ! -d "$VSCODE_SETTINGS_DIR" ]; then
    mkdir -p "$VSCODE_SETTINGS_DIR"
fi

if [ -f "$TARGET_SETTINGS" ]; then
    warn "VS Code settings.json already exists at $TARGET_SETTINGS"
    warn "Review $SOURCE_SETTINGS and merge manually if needed."
else
    cp "$SOURCE_SETTINGS" "$TARGET_SETTINGS"
    ok "VS Code settings copied to $TARGET_SETTINGS"
fi

echo ""
ok "Layer 2 (Editor) complete."
