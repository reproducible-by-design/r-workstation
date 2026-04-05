#!/usr/bin/env bash
# Layer 1: Terminal - Zsh + Oh My Zsh + plugins
# Supports: Linux x64, macOS ARM
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DRY_RUN="${DRY_RUN:-false}"

info()  { printf "\033[0;34m[terminal]\033[0m %s\n" "$1"; }
ok()    { printf "\033[0;32m[terminal]\033[0m %s\n" "$1"; }
warn()  { printf "\033[0;33m[terminal]\033[0m %s\n" "$1"; }
error() { printf "\033[0;31m[terminal]\033[0m %s\n" "$1" >&2; }
dry()   { printf "\033[0;36m[dry-run]\033[0m would run: %s\n" "$*"; }

OS="$(uname -s)"

# ── Zsh ──────────────────────────────────────────────────────────────────────

if command -v zsh &>/dev/null; then
    ok "Zsh is already installed: $(zsh --version)"
else
    if [ "$DRY_RUN" = true ]; then
        case "$OS" in
            Linux)
                if command -v apt-get &>/dev/null; then
                    dry "sudo apt-get update && sudo apt-get install -y zsh"
                elif command -v dnf &>/dev/null; then
                    dry "sudo dnf install -y zsh"
                elif command -v pacman &>/dev/null; then
                    dry "sudo pacman -S --noconfirm zsh"
                else
                    dry "Install zsh via your package manager"
                fi
                ;;
            Darwin) dry "brew install zsh" ;;
            *)      error "Unsupported OS: $OS"; exit 1 ;;
        esac
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
fi

# ── Oh My Zsh ────────────────────────────────────────────────────────────────

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"

if [ -d "$ZSH_DIR" ]; then
    ok "Oh My Zsh is already installed at $ZSH_DIR"
else
    if [ "$DRY_RUN" = true ]; then
        dry "Install Oh My Zsh to $ZSH_DIR"
    else
        info "Installing Oh My Zsh..."
        INSTALLER="$(mktemp /tmp/omz-install-XXXXXX.sh)"
        curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$INSTALLER"
        if [ ! -s "$INSTALLER" ]; then
            error "Failed to download Oh My Zsh installer."
            rm -f "$INSTALLER"
            exit 1
        fi
        # RUNZSH=no prevents the installer from switching to zsh immediately.
        # KEEP_ZSHRC=yes prevents overwriting an existing .zshrc.
        RUNZSH=no KEEP_ZSHRC=yes sh "$INSTALLER"
        rm -f "$INSTALLER"
        ok "Oh My Zsh installed"
    fi
fi

# ── Plugins ──────────────────────────────────────────────────────────────────

ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

install_plugin() {
    local name="$1"
    local repo="$2"
    local dest="$ZSH_CUSTOM/plugins/$name"

    if [ -d "$dest" ]; then
        ok "Plugin already installed: $name"
    elif [ "$DRY_RUN" = true ]; then
        dry "git clone --depth=1 $repo $dest"
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
        elif [ "$DRY_RUN" = true ]; then
            dry "Add $plugin to plugins=(...) in $ZSHRC"
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

# ── Enable Zsh for interactive sessions ──────────────────────────────────────
# Instead of changing the login shell with chsh (which can lock users out of
# SSH sessions if Zsh is removed or misconfigured), we add a guarded handoff
# in .bashrc that only activates for interactive sessions and only if Zsh exists.
#
# To change the login shell instead, run: chsh -s $(which zsh)

CURRENT_SHELL="$(basename "$SHELL")"
BASHRC="$HOME/.bashrc"
ZSH_HANDOFF='if [[ $- == *i* ]] && command -v zsh &>/dev/null; then exec zsh -l; fi'
ZSH_HANDOFF_MARKER="exec zsh"

if [ "$CURRENT_SHELL" = "zsh" ]; then
    ok "Zsh is already your default shell"
elif [ -f "$BASHRC" ] && grep -q "$ZSH_HANDOFF_MARKER" "$BASHRC" 2>/dev/null; then
    ok "Zsh handoff already configured in .bashrc"
elif [ "$DRY_RUN" = true ]; then
    dry "Append Zsh handoff to $BASHRC"
else
    info "Adding Zsh handoff to .bashrc (interactive sessions only)..."
    {
        echo ""
        echo "# Added by r-workstation: launch Zsh for interactive sessions"
        echo "# Safe to remove. Only runs if Zsh is installed and session is interactive."
        echo "$ZSH_HANDOFF"
    } >> "$BASHRC"
    ok "Zsh will launch automatically for interactive sessions."
    info "To undo, remove the last 3 lines from $BASHRC"
fi

echo ""
ok "Layer 1 (Terminal) complete."
