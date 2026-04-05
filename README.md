# r-workstation

A setup toolkit for a modern R development environment: a better terminal, VS Code with Jupyter notebooks and an R kernel, and reproducible conda/mamba environments.

Companion to the blog post [A Modern R Workstation](https://www.reproducible-science.com/modern-r-workstation/) on [reproducible-science.com](https://www.reproducible-science.com).

## Supported platforms

- Linux x86_64 (Debian/Ubuntu-based)
- macOS Apple Silicon (ARM)

## Prerequisites

- A terminal and an internet connection
- `git` and `curl` installed

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

## Layers

Each layer is independent. Use only what you need.

### Layer 1: Terminal

```bash
./setup.sh --terminal
```

Installs Zsh (if needed), Oh My Zsh, and two plugins:

- **zsh-autosuggestions**: shows predicted commands from your history as you type.
- **zsh-syntax-highlighting**: colors valid commands green and errors red, before you press Enter.

### Layer 2: Editor

```bash
./setup.sh --editor
```

Installs VS Code (if needed) and the Jupyter extension. The R language server extension is not installed — it is not needed for the notebook/kernel approach.

### Layer 3: Environment

```bash
./setup.sh --environment
```

Installs Miniforge (if neither conda nor mamba is available) and creates the `r-workstation` conda environment from `environment.yml`. This environment includes R, common R packages, the Jupyter R kernel, and Python.

After setup, open a `.ipynb` file in VS Code and select the **R (r-workstation)** kernel from the kernel picker.

### Combining layers

```bash
./setup.sh --terminal --environment
```

## Customizing the environment

Edit `environment.yml` to add or remove packages:

```yaml
dependencies:
  - r-base=4.4
  - r-irkernel
  - r-tidyverse
  - r-sf          # add geospatial support
  - r-DBI         # add database support
```

Then update the environment:

```bash
mamba env update -n r-workstation -f environment.yml --prune
```

R packages in conda-forge are prefixed with `r-` (e.g., `r-ggplot2`, `r-data.table`). System-level libraries (GDAL, Java, etc.) can also be added as conda packages, avoiding the need for manual system installation.

## AI tools

This repository does not pre-install any AI coding assistant. If your organization permits their use, some options include:

- [GitHub Copilot](https://github.com/features/copilot) (VS Code extension)
- [ChatGPT Codex](https://openai.com/index/codex/) (OpenAI)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Anthropic, terminal CLI)
- [Gemini Code Assist](https://cloud.google.com/gemini/docs/codeassist/overview) (Google, VS Code extension)

Review your organization's guidelines before adopting any AI tool. Always review AI-generated output before acting on it.

## Troubleshooting

**VS Code does not show the R kernel**

Make sure the `r-workstation` conda environment is created and the kernel is registered:

```bash
conda activate r-workstation
Rscript -e 'IRkernel::installspec(user = TRUE, displayname = "R (r-workstation)")'
```

Then restart VS Code. The kernel should appear in the Jupyter kernel picker.

**Zsh is not my default shell after running setup**

The script runs `chsh -s /path/to/zsh`, which requires your password. If it failed silently, run it manually:

```bash
chsh -s $(which zsh)
```

Then restart your terminal.

**VS Code keeps asking to install the R language server**

This is a VS Code recommendation, not a requirement. You can safely dismiss it. The Jupyter kernel approach does not depend on the R language server extension.

**The conda environment takes a long time to solve**

Mamba (included with Miniforge) is significantly faster than conda for environment resolution. If you installed conda separately, consider switching to mamba:

```bash
conda install -n base -c conda-forge mamba
```

## License

MIT. See [LICENSE](LICENSE).

## Disclaimer

This repository is provided for educational purposes only, "as-is," without warranty of any kind. The author assumes no responsibility for errors, omissions, or consequences arising from its use. Users are responsible for evaluating suitability in their own contexts, including compliance with applicable policies, regulations, and organizational guidelines.
