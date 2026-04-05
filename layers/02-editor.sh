#!/usr/bin/env bash
# Layer 2: Editor - VS Code + Jupyter extension
# Supports: Linux x64 (Debian/Ubuntu), macOS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DRY_RUN="${DRY_RUN:-false}"

info()  { printf "\033[0;34m[editor]\033[0m %s\n" "$1"; }
ok()    { printf "\033[0;32m[editor]\033[0m %s\n" "$1"; }
warn()  { printf "\033[0;33m[editor]\033[0m %s\n" "$1"; }
error() { printf "\033[0;31m[editor]\033[0m %s\n" "$1" >&2; }
dry()   { printf "\033[0;36m[dry-run]\033[0m would run: %s\n" "$*"; }

OS="$(uname -s)"
ARCH="$(uname -m)"

# ── VS Code ──────────────────────────────────────────────────────────────────

if command -v code &>/dev/null; then
    ok "VS Code is already installed: $(code --version | head -1)"
else
    case "$OS" in
        Linux)
            if [ "$ARCH" != "x86_64" ]; then
                error "This script supports Linux x86_64 only. Detected: $ARCH"
                exit 1
            fi
            if ! command -v dpkg &>/dev/null; then
                error "VS Code auto-install requires a Debian/Ubuntu-based system (dpkg)."
                error "On Fedora: sudo dnf install code"
                error "On Arch: yay -S visual-studio-code-bin"
                error "Or download from https://code.visualstudio.com"
                exit 1
            fi
            if [ "$DRY_RUN" = true ]; then
                dry "Download and install VS Code .deb package (sudo dpkg -i)"
            else
                TEMP_DEB="$(mktemp /tmp/vscode-XXXXXX.deb)"
                info "Downloading VS Code .deb package..."
                curl -fsSL "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -o "$TEMP_DEB"
                info "Installing (this may ask for your password)..."
                sudo dpkg -i "$TEMP_DEB" || sudo apt-get install -f -y
                rm -f "$TEMP_DEB"
            fi
            ;;
        Darwin)
            if command -v brew &>/dev/null; then
                if [ "$DRY_RUN" = true ]; then
                    dry "brew install --cask visual-studio-code"
                else
                    info "Installing via Homebrew..."
                    brew install --cask visual-studio-code
                fi
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

    # Verify installation (skip in dry-run)
    if [ "$DRY_RUN" != true ]; then
        if command -v code &>/dev/null; then
            ok "VS Code installed: $(code --version | head -1)"
        else
            error "VS Code installation completed but 'code' command not found."
            error "You may need to restart your terminal or add VS Code to your PATH."
            exit 1
        fi
    fi
fi

# ── Extensions ───────────────────────────────────────────────────────────────

EXTENSIONS=(
    "ms-toolsai.jupyter"
    "ms-toolsai.vscode-jupyter-cell-tags"
    "ms-toolsai.vscode-jupyter-slideshow"
)

for ext in "${EXTENSIONS[@]}"; do
    if [ "$DRY_RUN" != true ] && code --list-extensions 2>/dev/null | grep -qi "$ext"; then
        ok "Extension already installed: $ext"
    elif [ "$DRY_RUN" = true ]; then
        dry "code --install-extension $ext"
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

if [ -f "$TARGET_SETTINGS" ]; then
    warn "VS Code settings.json already exists at $TARGET_SETTINGS"
    info "Add these settings manually if needed:"
    info '  "jupyter.askForKernelRestart": false'
    info '  "notebook.output.textLineLimit": 500'
    info '  "notebook.output.scrolling": true'
elif [ "$DRY_RUN" = true ]; then
    dry "cp $SOURCE_SETTINGS $TARGET_SETTINGS"
else
    mkdir -p "$VSCODE_SETTINGS_DIR"
    cp "$SOURCE_SETTINGS" "$TARGET_SETTINGS"
    ok "VS Code settings copied to $TARGET_SETTINGS"
fi

echo ""
ok "Layer 2 (Editor) complete."
