#!/usr/bin/env bash
# Layer 1: Terminal - Zsh + Oh My Zsh + plugins
# Supports: Linux x64, macOS ARM
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

info()  { printf "\033[0;34m[terminal]\033[0m %s\n" "$1"; }
ok()    { printf "\033[0;32m[terminal]\033[0m %s\n" "$1"; }
warn()  { printf "\033[0;33m[terminal]\033[0m %s\n" "$1"; }
error() { printf "\033[0;31m[terminal]\033[0m %s\n" "$1" >&2; }

OS="$(uname -s)"

# ── Zsh ──────────────────────────────────────────────────────────────────────

if command -v zsh &>/dev/null; then
    ok "Zsh is already installed: $(zsh --version)"
else
    info "Installing Zsh..."
    case "$OS" in
        Linux)
            if command -v apt-get &>/dev/null; then
                sudo apt-get update -qq && sudo apt-get install -y -qq zsh
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y zsh
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm zsh
            else
                error "Could not detect package manager. Please install Zsh manually."
                exit 1
            fi
            ;;
        Darwin)
            # Zsh is the default shell on macOS since Catalina.
            # If somehow missing, install via Homebrew.
            if command -v brew &>/dev/null; then
                brew install zsh
            else
                error "Zsh not found and Homebrew is not available. Please install Zsh manually."
                exit 1
            fi
            ;;
        *)
            error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    ok "Zsh installed: $(zsh --version)"
fi

# ── Oh My Zsh ────────────────────────────────────────────────────────────────

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"

if [ -d "$ZSH_DIR" ]; then
    ok "Oh My Zsh is already installed at $ZSH_DIR"
else
    info "Installing Oh My Zsh..."
    # RUNZSH=no prevents the installer from switching to zsh immediately.
    # KEEP_ZSHRC=yes prevents overwriting an existing .zshrc.
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Oh My Zsh installed"
fi

# ── Plugins ──────────────────────────────────────────────────────────────────

ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

install_plugin() {
    local name="$1"
    local repo="$2"
    local dest="$ZSH_CUSTOM/plugins/$name"

    if [ -d "$dest" ]; then
        ok "Plugin already installed: $name"
    else
        info "Cloning plugin: $name"
        git clone --depth=1 "$repo" "$dest"
        ok "Plugin installed: $name"
    fi
}

install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"

# ── Activate plugins in .zshrc ───────────────────────────────────────────────

ZSHRC="$HOME/.zshrc"

if [ ! -f "$ZSHRC" ]; then
    warn "No .zshrc found. Oh My Zsh should have created one. Skipping plugin activation."
else
    PLUGINS_TO_ADD=("zsh-autosuggestions" "zsh-syntax-highlighting")
    CHANGED=false

    for plugin in "${PLUGINS_TO_ADD[@]}"; do
        if grep -q "$plugin" "$ZSHRC" 2>/dev/null; then
            ok "Plugin already in .zshrc: $plugin"
        else
            # Add plugin to the plugins=(...) line.
            # Handles the common single-line format: plugins=(git)
            if grep -qE "^plugins=\(" "$ZSHRC"; then
                sed -i.bak "s/^plugins=(\(.*\))/plugins=(\1 $plugin)/" "$ZSHRC"
                CHANGED=true
                ok "Added $plugin to plugins list in .zshrc"
            else
                warn "Could not find plugins=(...) line in .zshrc. Add '$plugin' manually."
            fi
        fi
    done

    if [ "$CHANGED" = true ] && [ -f "$ZSHRC.bak" ]; then
        rm -f "$ZSHRC.bak"
    fi
fi

# ── Set Zsh as default shell ─────────────────────────────────────────────────

CURRENT_SHELL="$(basename "$SHELL")"
ZSH_PATH="$(command -v zsh)"

if [ "$CURRENT_SHELL" = "zsh" ]; then
    ok "Zsh is already your default shell"
else
    info "Setting Zsh as your default shell (this may ask for your password)..."
    if chsh -s "$ZSH_PATH"; then
        ok "Default shell changed to Zsh. Restart your terminal to use it."
    else
        warn "Could not change default shell automatically. Run: chsh -s $ZSH_PATH"
    fi
fi

echo ""
ok "Layer 1 (Terminal) complete."
