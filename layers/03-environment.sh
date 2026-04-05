#!/usr/bin/env bash
# Layer 3: Environment - Conda/Mamba + R environment with Jupyter kernel
# Supports: Linux x64, macOS ARM
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DRY_RUN="${DRY_RUN:-false}"

info()  { printf "\033[0;34m[environment]\033[0m %s\n" "$1"; }
ok()    { printf "\033[0;32m[environment]\033[0m %s\n" "$1"; }
warn()  { printf "\033[0;33m[environment]\033[0m %s\n" "$1"; }
error() { printf "\033[0;31m[environment]\033[0m %s\n" "$1" >&2; }
dry()   { printf "\033[0;36m[dry-run]\033[0m would run: %s\n" "$*"; }

OS="$(uname -s)"
ARCH="$(uname -m)"
ENV_FILE="$REPO_DIR/environment.yml"
DEFAULT_ENV_NAME="r-workstation"

# ── Environment name ─────────────────────────────────────────────────────────
# Can be set via --name flag from setup.sh, the R_ENV_NAME variable, or
# interactively. This lets users create multiple project-specific environments
# from the same base template.

if [ -n "${R_ENV_NAME:-}" ]; then
    ENV_NAME="$R_ENV_NAME"
else
    echo ""
    info "This will create a conda environment with R, common packages, and a Jupyter kernel."
    info "Each project can have its own environment. You can run this script again with a"
    info "different name to create as many as you need."
    echo ""
    printf "\033[0;34m[environment]\033[0m Environment name [%s]: " "$DEFAULT_ENV_NAME"
    read -r USER_INPUT
    ENV_NAME="${USER_INPUT:-$DEFAULT_ENV_NAME}"
fi

# Validate environment name: alphanumeric, hyphens, and underscores only.
# Prevents breakage in conda commands, Rscript string interpolation, and file paths.
if ! [[ "$ENV_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "Invalid environment name: '$ENV_NAME'"
    error "Use only letters, numbers, hyphens, and underscores."
    exit 1
fi

info "Environment name: $ENV_NAME"

# ── Project directory ────────────────────────────────────────────────────────
# Copy environment.yml to the user's project so it can be version-controlled
# and modified per project.

if [ "$DRY_RUN" != true ]; then
    echo ""
    printf "\033[0;34m[environment]\033[0m Copy environment.yml to a project directory? [path or empty to skip]: "
    read -r PROJECT_DIR

    if [ -n "$PROJECT_DIR" ]; then
        PROJECT_DIR="${PROJECT_DIR/#\~/$HOME}"
        if [ -d "$PROJECT_DIR" ]; then
            if [ -f "$PROJECT_DIR/environment.yml" ]; then
                warn "environment.yml already exists in $PROJECT_DIR (not overwritten)"
            else
                cp "$ENV_FILE" "$PROJECT_DIR/environment.yml"
                ok "Copied environment.yml to $PROJECT_DIR/"
                info "Add or remove packages there, then run:"
                info "  mamba env update -n $ENV_NAME -f $PROJECT_DIR/environment.yml"
            fi
        else
            warn "Directory does not exist: $PROJECT_DIR (skipping copy)"
        fi
    fi
fi

# ── Conda / Mamba ────────────────────────────────────────────────────────────

CONDA_CMD=""
CONDA_BASE=""

# Try PATH first, then check common installation directories.
# Conda/mamba are often initialized only in .zshrc or .bashrc, so they may
# not be in PATH when this script runs as a non-interactive bash subprocess.
SEARCH_DIRS=(
    "$HOME/miniforge3"
    "$HOME/mambaforge"
    "$HOME/miniconda3"
    "$HOME/anaconda3"
    "$HOME/.conda"
)

find_conda() {
    # Check PATH
    if command -v mamba &>/dev/null; then
        CONDA_CMD="mamba"
        return 0
    elif command -v conda &>/dev/null; then
        CONDA_CMD="conda"
        return 0
    fi

    # Check common install locations
    for dir in "${SEARCH_DIRS[@]}"; do
        if [ -x "$dir/bin/conda" ]; then
            info "Found conda at $dir/bin/conda (not in PATH). Activating..."
            eval "$("$dir/bin/conda" shell.bash hook)"
            CONDA_BASE="$dir"
            # Prefer mamba as the solver if available
            if [ -x "$dir/bin/mamba" ]; then
                CONDA_CMD="mamba"
            else
                CONDA_CMD="conda"
            fi
            return 0
        fi
    done

    return 1
}

if find_conda; then
    ok "Using $CONDA_CMD: $($CONDA_CMD --version 2>&1 | head -1)"
else
    if [ "$DRY_RUN" = true ]; then
        case "${OS}-${ARCH}" in
            Linux-x86_64)   dry "Download and install Miniforge3-Linux-x86_64.sh to $HOME/miniforge3" ;;
            Darwin-arm64)   dry "Download and install Miniforge3-MacOSX-arm64.sh to $HOME/miniforge3" ;;
            Darwin-x86_64)  dry "Download and install Miniforge3-MacOSX-x86_64.sh to $HOME/miniforge3" ;;
            *)              error "Unsupported platform: ${OS}-${ARCH}"; exit 1 ;;
        esac
        dry "conda init zsh/bash"
        # Set a placeholder so dry-run can continue
        CONDA_CMD="mamba"
        CONDA_BASE="$HOME/miniforge3"
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

        CONDA_BASE="$HOME/miniforge3"

        # Initialize for the current session
        eval "$("$CONDA_BASE/bin/conda" shell.bash hook)"

        CONDA_CMD="mamba"
        ok "Miniforge installed at $CONDA_BASE"

        # Initialize conda for the user's shell
        info "Initializing conda for your shell..."
        if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
            "$CONDA_BASE/bin/conda" init zsh
            info "Conda initialized for Zsh. Restart your terminal or run: source ~/.zshrc"
        else
            "$CONDA_BASE/bin/conda" init bash
            info "Conda initialized for Bash. Restart your terminal or run: source ~/.bashrc"
        fi
    fi
fi

# ── Create environment ───────────────────────────────────────────────────────

if [ ! -f "$ENV_FILE" ]; then
    error "Environment file not found: $ENV_FILE"
    exit 1
fi

KERNEL_DISPLAY="R ($ENV_NAME)"

if [ "$DRY_RUN" = true ]; then
    dry "$CONDA_CMD env create -n $ENV_NAME -f $ENV_FILE"
    dry "conda activate $ENV_NAME"
    dry "Rscript -e \"IRkernel::installspec(user = TRUE, name = '$ENV_NAME', displayname = '$KERNEL_DISPLAY')\""
    echo ""
    ok "Layer 3 (Environment) dry run complete."
    echo ""
    info "Would create environment: $ENV_NAME"
    info "Would register kernel: $KERNEL_DISPLAY"
    exit 0
fi

# The -n flag overrides the name in environment.yml, allowing multiple
# environments from the same template.
if $CONDA_CMD env list 2>/dev/null | grep -qE "^${ENV_NAME}\s"; then
    warn "Environment '$ENV_NAME' already exists."
    info "Updating environment from $ENV_FILE..."
    info "(Packages you installed manually will be preserved.)"
    $CONDA_CMD env update -n "$ENV_NAME" -f "$ENV_FILE"
    ok "Environment updated: $ENV_NAME"
else
    info "Creating environment '$ENV_NAME' from $ENV_FILE..."
    $CONDA_CMD env create -n "$ENV_NAME" -f "$ENV_FILE"
    ok "Environment created: $ENV_NAME"
fi

# ── Register R kernel ────────────────────────────────────────────────────────

info "Registering R kernel with Jupyter..."

# Always use conda for activation. Mamba is the solver, conda is the
# activation mechanism. Calling "mamba activate" may not work because the
# mamba shell hook does not always define an activate function.
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

# IRkernel::installspec() registers the R kernel so Jupyter (and VS Code) can find it
Rscript -e "IRkernel::installspec(user = TRUE, name = '${ENV_NAME}', displayname = '${KERNEL_DISPLAY}')"

ok "R kernel registered as '$KERNEL_DISPLAY'"

# ── Verify ───────────────────────────────────────────────────────────────────

info "Verifying installation..."
R_VERSION=$(Rscript -e 'cat(R.version$major, R.version$minor, sep=".")')
ok "R version: $R_VERSION"

if jupyter kernelspec list 2>/dev/null | grep -qE "^\s+${ENV_NAME}\s"; then
    ok "R kernel is registered with Jupyter"
else
    warn "R kernel may not be registered. Try running:"
    warn "  conda activate $ENV_NAME"
    warn "  Rscript -e 'IRkernel::installspec(user = TRUE)'"
fi

echo ""
ok "Layer 3 (Environment) complete."
echo ""
info "To activate the environment: conda activate $ENV_NAME"
info "To use in VS Code: open a .ipynb file and select the '$KERNEL_DISPLAY' kernel."
echo ""
info "To add packages later:"
info "  1. Search on https://anaconda.org for the package name"
info "  2. Add it to your project's environment.yml"
info "  3. Run: mamba env update -n $ENV_NAME -f environment.yml"
