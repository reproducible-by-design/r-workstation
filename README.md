# r-workstation

A setup toolkit for a modern R development environment: a better terminal, VS Code with Jupyter notebooks and an R kernel, and reproducible conda/mamba environments.

Companion to the blog post [A Modern R Workstation](https://www.reproducible-science.com/modern-r-workstation/) on [reproducible-science.com](https://www.reproducible-science.com).

## Supported platforms

- Linux x86_64 (Debian/Ubuntu for VS Code auto-install; Zsh and conda work on other distros)
- macOS (Apple Silicon and Intel)

## Prerequisites

- A terminal and an internet connection
- `git` and `curl` installed
- ~4-5 GB of disk space (mostly the conda environment with R and packages)

## Quick start

One-liner (clones the repo and runs setup):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/reproducible-by-design/r-workstation/main/install.sh)"
```

Or clone manually:

```bash
git clone https://github.com/reproducible-by-design/r-workstation.git
cd r-workstation
./setup.sh --all
```

Both approaches install all three layers. You can also install them individually.

### Preview before installing

Use `--dry-run` to see what would happen without making any changes:

```bash
./setup.sh --dry-run
./setup.sh --dry-run --terminal --environment
```

## Layers

Each layer is independent. Use only what you need.

### Layer 1: Terminal

```bash
./setup.sh --terminal
```

Installs Zsh (if needed), Oh My Zsh, and two plugins:

- **zsh-autosuggestions**: shows predicted commands from your history as you type.
- **zsh-syntax-highlighting**: colors valid commands green and errors red, before you press Enter.

Zsh is enabled for interactive sessions via a guarded line in `.bashrc`. This is safer than changing the login shell with `chsh`, especially on servers accessed via SSH: if Zsh is ever removed, Bash takes over automatically. The line only runs for interactive sessions, so `scp`, `rsync`, and cron jobs are unaffected.

To undo, remove the lines at the end of `~/.bashrc` marked `# Added by r-workstation`.

### Layer 2: Editor

```bash
./setup.sh --editor
```

Installs VS Code (if needed) and the Jupyter extension. The R language server extension is not installed — it is not needed for the notebook/kernel approach.

On Linux, VS Code auto-install requires a Debian/Ubuntu-based system. On other distros, install VS Code from your package manager first, then run this layer for the extensions.

### Layer 3: Environment

```bash
./setup.sh --environment
```

Installs Miniforge (if neither conda nor mamba is available) and creates a conda environment from `environment.yml`. This environment includes R, common R packages, the Jupyter R kernel, and Python.

After setup, open a `.ipynb` file in VS Code and select the R kernel from the kernel picker.

### Combining layers

```bash
./setup.sh --terminal --environment
```

## Multiple environments

Each project can have its own isolated environment. Use `--name` to create environments with different names:

```bash
./setup.sh --environment --name my-project
./setup.sh --environment --name another-project
```

Each gets its own R installation, packages, and Jupyter kernel (shown as `R (my-project)` in VS Code). If you skip `--name`, the script prompts you interactively, defaulting to `r-workstation`.

During setup, you can optionally copy `environment.yml` to your project directory so it can be version-controlled alongside your code. Each project should have its own copy.

## Adding packages

The recommended workflow for adding new dependencies:

1. Search for the package on [anaconda.org](https://anaconda.org) (R packages are typically prefixed `r-`, e.g., `r-sf`, `r-DBI`).
2. Add the package to your project's `environment.yml`.
3. Update the environment:

```bash
mamba env update -n my-project -f environment.yml
```

This keeps `environment.yml` as the single source of truth for your environment. Collaborators can recreate it with `mamba env create -n my-project -f environment.yml`.

System-level libraries (GDAL, Java, etc.) can also be added as conda packages, avoiding the need for manual system installation.

## AI tools

This repository does not pre-install any AI coding assistant. If your organization permits their use, some options include:

- [GitHub Copilot](https://github.com/features/copilot) (VS Code extension)
- [ChatGPT Codex](https://openai.com/index/codex/) (OpenAI)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Anthropic, terminal CLI)
- [Gemini Code Assist](https://cloud.google.com/gemini/docs/codeassist/overview) (Google, VS Code extension)

Review your organization's guidelines before adopting any AI tool. Always review AI-generated output before acting on it.

## Configuration reference

| File | Purpose |
|---|---|
| `environment.yml` | Base template for conda environments (R, packages, kernel) |
| `config/zshrc.snippet` | Reference for manual Oh My Zsh plugin configuration |
| `config/vscode/settings.json` | VS Code settings for Jupyter notebooks |
| `config/vscode/extensions.json` | Recommended VS Code extensions (reference only) |

## Troubleshooting

**VS Code does not show the R kernel**

Make sure the conda environment is created and the kernel is registered:

```bash
conda activate <your-env-name>
Rscript -e 'IRkernel::installspec(user = TRUE, displayname = "R (<your-env-name>)")'
```

Then restart VS Code. The kernel should appear in the Jupyter kernel picker.

**Zsh is not active after running setup**

The setup adds a handoff line to `~/.bashrc`. Open a new terminal window for it to take effect. If it still does not work, check that `~/.bashrc` contains the line `exec zsh -l` near the end.

If you prefer to change your login shell directly (not recommended on servers):

```bash
chsh -s $(which zsh)
```

**VS Code keeps asking to install the R language server**

This is a VS Code recommendation, not a requirement. You can safely dismiss it. The Jupyter kernel approach does not depend on the R language server extension.

**The conda environment takes a long time to solve**

Mamba (included with Miniforge) is significantly faster than conda for environment resolution. If you installed conda separately, consider switching to mamba:

```bash
conda install -n base -c conda-forge mamba
```

**VS Code auto-install fails on Fedora/Arch Linux**

Layer 2 auto-installs VS Code only on Debian/Ubuntu-based systems. On other distros, install VS Code from your package manager first:

- Fedora: `sudo dnf install code`
- Arch: `yay -S visual-studio-code-bin`
- Or download from [code.visualstudio.com](https://code.visualstudio.com)

Then run `./setup.sh --editor` to install the Jupyter extensions.

## Environment variables

| Variable | Purpose | Default |
|---|---|---|
| `R_ENV_NAME` | Set environment name non-interactively | Prompted (default: `r-workstation`) |
| `R_WORKSTATION_DIR` | Clone location for the web installer | `~/.r-workstation` |
| `DRY_RUN` | Set to `true` to preview without changes | `false` |

## License

MIT. See [LICENSE](LICENSE).

## Disclaimer

This repository is provided for educational purposes only, "as-is," without warranty of any kind. The author assumes no responsibility for errors, omissions, or consequences arising from its use. Users are responsible for evaluating suitability in their own contexts, including compliance with applicable policies, regulations, and organizational guidelines.
