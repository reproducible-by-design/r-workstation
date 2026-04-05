#!/usr/bin/env bash
# Layer 3: Environment - Conda/Mamba + R environment with Jupyter kernel
# Supports: Linux x64, macOS ARM
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

info()  { printf "\033[0;34m[environment]\033[0m %s\n" "$1"; }
ok()    { printf "\033[0;32m[environment]\033[0m %s\n" "$1"; }
warn()  { printf "\033[0;33m[environment]\033[0m %s\n" "$1"; }
error() { printf "\033[0;31m[environment]\033[0m %s\n" "$1" >&2; }

OS="$(uname -s)"
ARCH="$(uname -m)"
ENV_FILE="$REPO_DIR/environment.yml"
ENV_NAME="r-workstation"

# ── Conda / Mamba ────────────────────────────────────────────────────────────

CONDA_CMD=""

if command -v mamba &>/dev/null; then
    CONDA_CMD="mamba"
    ok "Mamba is already installed: $(mamba --version | head -1)"
elif command -v conda &>/dev/null; then
    CONDA_CMD="conda"
    ok "Conda is already installed: $(conda --version)"
else
    info "Neither Conda nor Mamba found. Installing Miniforge..."

    case "${OS}-${ARCH}" in
        Linux-x86_64)   MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh" ;;
        Darwin-arm64)   MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh" ;;
        Darwin-x86_64)  MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh" ;;
        *)
            error "Unsupported platform: ${OS}-${ARCH}"
            exit 1
            ;;
    esac

    INSTALLER="$(mktemp /tmp/miniforge-XXXXXX.sh)"
    info "Downloading Miniforge installer..."
    curl -fsSL "$MINIFORGE_URL" -o "$INSTALLER"

    info "Running Miniforge installer (non-interactive)..."
    bash "$INSTALLER" -b -p "$HOME/miniforge3"
    rm -f "$INSTALLER"

    # Initialize for the current session
    eval "$("$HOME/miniforge3/bin/conda" shell.bash hook)"

    CONDA_CMD="mamba"
    ok "Miniforge installed at $HOME/miniforge3"

    # Initialize conda for the user's shell
    info "Initializing conda for your shell..."
    if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
        "$HOME/miniforge3/bin/conda" init zsh
        info "Conda initialized for Zsh. Restart your terminal or run: source ~/.zshrc"
    else
        "$HOME/miniforge3/bin/conda" init bash
        info "Conda initialized for Bash. Restart your terminal or run: source ~/.bashrc"
    fi
fi

# ── Create environment ───────────────────────────────────────────────────────

if [ ! -f "$ENV_FILE" ]; then
    error "Environment file not found: $ENV_FILE"
    exit 1
fi

# Check if environment already exists
if $CONDA_CMD env list 2>/dev/null | grep -qE "^${ENV_NAME}\s"; then
    warn "Environment '$ENV_NAME' already exists."
    info "Updating environment from $ENV_FILE..."
    $CONDA_CMD env update -n "$ENV_NAME" -f "$ENV_FILE" --prune
    ok "Environment updated: $ENV_NAME"
else
    info "Creating environment from $ENV_FILE..."
    $CONDA_CMD env create -f "$ENV_FILE"
    ok "Environment created: $ENV_NAME"
fi

# ── Register R kernel ────────────────────────────────────────────────────────

info "Registering R kernel with Jupyter..."

# Activate the environment and register the kernel
eval "$($CONDA_CMD shell.bash hook)"
$CONDA_CMD activate "$ENV_NAME"

# IRkernel::installspec() registers the R kernel so Jupyter (and VS Code) can find it
Rscript -e 'IRkernel::installspec(user = TRUE, displayname = "R (r-workstation)")'

ok "R kernel registered as 'R (r-workstation)'"

# ── Verify ───────────────────────────────────────────────────────────────────

info "Verifying installation..."
R_VERSION=$(Rscript -e 'cat(R.version$major, R.version$minor, sep=".")')
ok "R version: $R_VERSION"

KERNEL_COUNT=$(jupyter kernelspec list 2>/dev/null | grep -c "ir" || true)
if [ "$KERNEL_COUNT" -gt 0 ]; then
    ok "R kernel is registered with Jupyter"
else
    warn "R kernel may not be registered. Try running: Rscript -e 'IRkernel::installspec(user = TRUE)'"
fi

echo ""
ok "Layer 3 (Environment) complete."
echo ""
info "To activate the environment: conda activate $ENV_NAME"
info "To use in VS Code: open a .ipynb file and select the 'R (r-workstation)' kernel."
