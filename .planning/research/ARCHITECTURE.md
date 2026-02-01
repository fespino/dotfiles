# Architecture Research: Cross-Platform Dotfiles

**Domain:** Dotfiles repository management
**Researched:** 2026-02-01
**Confidence:** HIGH (patterns well-established, multiple authoritative sources)

## Executive Summary

Dotfiles repositories follow well-established patterns refined over a decade of community practice. The two dominant approaches are **bare git repositories** (tracking files in-place) and **symlink management** (storing files in a repo directory, linking to home). For a cross-platform bootstrap-focused repository, the **symlink approach with GNU Stow** provides the best balance of simplicity, portability, and maintainability.

Your existing repository already follows sensible patterns (app-per-directory), but lacks the install script and symlink management needed for single-command bootstrap.

---

## Directory Structure

### Recommended Layout

```
~/.dotfiles/
├── install.sh              # Single entry point for bootstrap
├── README.md               # Usage documentation
├── Brewfile                # macOS package list (Homebrew)
├── packages.txt            # Linux package list (apt)
│
├── scripts/                # Installation helper scripts
│   ├── functions.sh        # Shared functions (OS detection, backup, link)
│   ├── packages-mac.sh     # macOS-specific package installation
│   ├── packages-linux.sh   # Linux-specific package installation
│   └── post-install.sh     # Post-installation configuration
│
├── zsh/                    # Shell configuration
│   └── .zshrc              # -> symlinks to ~/.zshrc
│
├── kitty/                  # Terminal emulator
│   └── .config/
│       └── kitty/
│           ├── kitty.conf
│           └── current-theme.conf
│
├── tmux/                   # Terminal multiplexer
│   └── .tmux.conf          # -> symlinks to ~/.tmux.conf
│   └── theme.sh            # Sourced by tmux.conf
│
├── nvim/                   # Editor (XDG-compliant)
│   └── .config/
│       └── nvim/
│           └── init.lua
│
├── git/                    # Git configuration
│   ├── .gitconfig          # -> symlinks to ~/.gitconfig
│   └── .gitignore_global   # -> symlinks to ~/.gitignore_global
│
├── bin/                    # Custom scripts
│   └── cht.sh              # -> symlinks to ~/.local/bin/cht.sh
│
└── docs/                   # Extended documentation
    ├── KEYBINDINGS.md
    └── DECISIONS.md
```

### Key Principles

1. **Mirror home directory structure**: Files at `dotfiles/zsh/.zshrc` symlink to `~/.zshrc`. Files at `dotfiles/kitty/.config/kitty/kitty.conf` symlink to `~/.config/kitty/kitty.conf`. This is how GNU Stow works.

2. **One directory per application**: Keeps related files together. Easy to enable/disable apps by stowing/unstowing individual directories.

3. **XDG compliance where possible**: Modern apps use `~/.config/appname/`. Older apps (zsh, tmux) still expect dotfiles in home directory.

4. **Scripts directory for installation logic**: Separates configuration files from installation machinery.

### Your Current Structure vs. Recommended

| Current | Issue | Recommended |
|---------|-------|-------------|
| `.zshrc` in root | Should be in `zsh/` subdirectory | `zsh/.zshrc` |
| `kitty/kitty.conf` | Missing `.config/kitty/` nesting | `kitty/.config/kitty/kitty.conf` |
| `tmux/tmux.conf` | Should be `.tmux.conf` for home symlink | `tmux/.tmux.conf` |
| No install script | Cannot bootstrap | Add `install.sh` |
| `bin/cht.sh` | Good, but needs linking to PATH | Link to `~/.local/bin/` |

---

## Components

### 1. Bootstrap Entry Point (`install.sh`)

**Purpose:** Single command to set up entire environment on a fresh machine.

**Responsibilities:**
- Detect operating system (Darwin vs Linux)
- Install package manager if needed (Homebrew on Mac)
- Install system packages
- Create symlinks for all configuration files
- Backup existing files before replacing
- Install language runtimes (nvm, pyenv)
- Clone/install plugins (oh-my-zsh, tmux plugin manager)
- Run post-install configuration

**Design:**
```bash
#!/usr/bin/env bash
set -e  # Exit on error

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helper functions
source "$DOTFILES_DIR/scripts/functions.sh"

# Detect OS
OS=$(detect_os)

# Run installation phases
install_packages "$OS"
create_symlinks
install_runtimes
install_plugins
run_post_install

echo "Bootstrap complete! Restart your shell."
```

### 2. Helper Functions (`scripts/functions.sh`)

**Purpose:** Shared utilities used across installation scripts.

**Key Functions:**

```bash
# OS Detection
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

# Backup existing file before symlinking
backup_if_exists() {
    local target="$1"
    local backup_dir="$HOME/.dotfiles.backup/$(date +%Y%m%d_%H%M%S)"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mkdir -p "$backup_dir"
        mv "$target" "$backup_dir/"
        echo "Backed up: $target -> $backup_dir/"
    fi
}

# Create symlink with backup
safe_link() {
    local source="$1"
    local target="$2"

    backup_if_exists "$target"
    mkdir -p "$(dirname "$target")"
    ln -sf "$source" "$target"
    echo "Linked: $source -> $target"
}
```

### 3. Package Installation Scripts

**macOS (`scripts/packages-mac.sh`):**
- Install Homebrew if not present
- Install packages from Brewfile
- Install casks (GUI apps)

**Linux (`scripts/packages-linux.sh`):**
- Update apt repositories
- Install packages from packages.txt
- Handle Debian/Ubuntu differences if needed

### 4. Application Configurations

Each application directory contains:
- Configuration files in the correct path structure
- Optional `install.sh` for app-specific setup (e.g., installing plugins)

| App | Config Location | Symlink Target |
|-----|-----------------|----------------|
| zsh | `zsh/.zshrc` | `~/.zshrc` |
| kitty | `kitty/.config/kitty/*` | `~/.config/kitty/*` |
| tmux | `tmux/.tmux.conf` | `~/.tmux.conf` |
| nvim | `nvim/.config/nvim/*` | `~/.config/nvim/*` |
| git | `git/.gitconfig` | `~/.gitconfig` |

### 5. Documentation

| File | Purpose |
|------|---------|
| `README.md` | Quick start, what's included |
| `docs/KEYBINDINGS.md` | Reference for custom keybindings |
| `docs/DECISIONS.md` | Why certain choices were made |

---

## Component Interactions

### Dependency Graph

```
install.sh (entry point)
    │
    ├── scripts/functions.sh (loaded first)
    │
    ├── scripts/packages-{mac,linux}.sh
    │       │
    │       └── Brewfile / packages.txt
    │
    ├── [symlink creation]
    │       │
    │       ├── zsh/.zshrc ────────────────> ~/.zshrc
    │       ├── kitty/.config/kitty/* ─────> ~/.config/kitty/*
    │       ├── tmux/.tmux.conf ───────────> ~/.tmux.conf
    │       ├── nvim/.config/nvim/* ───────> ~/.config/nvim/*
    │       ├── git/.gitconfig ────────────> ~/.gitconfig
    │       └── bin/* ─────────────────────> ~/.local/bin/*
    │
    └── scripts/post-install.sh
            │
            ├── oh-my-zsh installation
            ├── tmux plugin manager (tpm)
            ├── nvm (Node.js)
            └── pyenv (Python)
```

### Data Flow

1. **User runs:** `./install.sh` or `curl ... | bash`
2. **OS detected:** `uname -s` determines macOS vs Linux
3. **Packages installed:** Homebrew/apt installs dependencies
4. **Symlinks created:** Each app directory processed, files linked
5. **Runtimes installed:** nvm, pyenv set up
6. **Plugins installed:** oh-my-zsh, tpm cloned
7. **Shell restarted:** User sources new config or restarts terminal

### Cross-Component Dependencies

| Component | Depends On | Notes |
|-----------|------------|-------|
| zsh config | oh-my-zsh | Must install omz before sourcing .zshrc |
| zsh config | nvm, pyenv | Paths set in .zshrc |
| tmux config | tpm | Must clone tpm before tmux loads plugins |
| nvim config | (none) | Self-contained, lazy.nvim auto-installs |
| kitty config | (none) | Self-contained |

---

## Build Order

Based on dependencies, implement components in this order:

### Phase 1: Foundation

1. **Directory restructuring**
   - Move `.zshrc` to `zsh/.zshrc`
   - Reorganize kitty to `kitty/.config/kitty/`
   - Reorganize tmux to `tmux/.tmux.conf`
   - Why first: All other work depends on correct structure

2. **Core helper functions (`scripts/functions.sh`)**
   - `detect_os`
   - `backup_if_exists`
   - `safe_link`
   - Why second: Install script needs these

### Phase 2: Basic Bootstrap

3. **Minimal install script (`install.sh`)**
   - Source functions
   - Detect OS
   - Create symlinks only (no packages yet)
   - Why: Achieves basic "one command" goal

4. **Test on both platforms**
   - Verify symlinks work on Mac
   - Verify symlinks work on Linux
   - Why: Catch path differences early

### Phase 3: Package Management

5. **Brewfile (macOS packages)**
   - List all CLI tools
   - List all casks

6. **packages.txt (Linux packages)**
   - Equivalent apt packages

7. **Package installation scripts**
   - `scripts/packages-mac.sh`
   - `scripts/packages-linux.sh`

### Phase 4: Runtime Installation

8. **Language runtime installation**
   - nvm for Node.js
   - pyenv for Python
   - (Optional) rustup, Elixir

### Phase 5: Plugin Management

9. **Post-install automation**
   - oh-my-zsh installation
   - tmux plugin manager
   - Any other plugins

### Phase 6: Polish

10. **Documentation**
    - Update README with usage
    - Keybindings reference
    - Decision log

11. **Remote bootstrap**
    - Support `curl ... | bash` installation
    - GitHub raw URL setup

---

## Architecture Patterns to Follow

### Pattern 1: Idempotent Installation

**What:** Running `install.sh` multiple times produces the same result without errors.

**Implementation:**
```bash
# Good: Check before installing
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Good: Use -f flag for symlinks (overwrites existing)
ln -sf "$source" "$target"

# Good: Check before cloning
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone ...
fi
```

### Pattern 2: Graceful Degradation

**What:** Installation continues even if optional components fail.

**Implementation:**
```bash
install_optional() {
    if ! some_command; then
        echo "Warning: Failed to install $1, continuing..."
    fi
}
```

### Pattern 3: Configuration Sourcing Chain

**What:** Split configuration into logical pieces that source each other.

**Implementation:**
```bash
# .zshrc sources from multiple files
source ~/.dotfiles/zsh/aliases.zsh
source ~/.dotfiles/zsh/functions.zsh
[ -f ~/.zshrc.local ] && source ~/.zshrc.local  # Machine-specific
```

### Pattern 4: OS-Conditional Configuration

**What:** Same config file handles Mac/Linux differences.

**Implementation:**
```bash
# In .zshrc
if [[ "$(uname)" == "Darwin" ]]; then
    alias ls="ls -G"  # macOS
    export PATH="/opt/homebrew/bin:$PATH"
else
    alias ls="ls --color=auto"  # Linux
fi
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Hardcoded Paths

**What:** Using absolute paths that differ between machines.

**Bad:**
```bash
source /Users/fespino/.dotfiles/zsh/aliases.zsh
```

**Good:**
```bash
source "$HOME/.dotfiles/zsh/aliases.zsh"
# Or use DOTFILES_DIR variable set at top of script
```

### Anti-Pattern 2: Destructive Overwrites

**What:** Replacing existing config without backup.

**Bad:**
```bash
ln -sf $source $target  # Destroys existing file
```

**Good:**
```bash
backup_if_exists "$target"
ln -sf "$source" "$target"
```

### Anti-Pattern 3: No Exit on Error

**What:** Script continues after critical failures.

**Bad:**
```bash
#!/bin/bash
git clone ...  # Might fail silently
cd repo        # Undefined behavior if clone failed
```

**Good:**
```bash
#!/bin/bash
set -e  # Exit immediately on error
git clone ... || { echo "Clone failed"; exit 1; }
```

### Anti-Pattern 4: Monolithic Config Files

**What:** Single massive .zshrc with everything.

**Issue:** Hard to maintain, can't selectively disable features.

**Good:** Split into sourced files by concern (aliases, functions, path, local).

---

## Scalability Considerations

| Concern | Now (1 machine) | Later (multiple machines) |
|---------|-----------------|---------------------------|
| Machine-specific config | Not needed | Use `.zshrc.local` pattern (gitignored) |
| Different app sets | All apps installed | Use `--only` flag or package groups |
| Secrets | None in repo | Use `.env.local` or secret manager |
| Testing | Manual | Add CI to test bootstrap on fresh VMs |

---

## GNU Stow vs. Manual Symlinking

### Recommendation: Start with Manual Linking

For this project's scope (4-5 apps, 2 platforms), manual symlinking in `install.sh` is simpler:

**Advantages of manual approach:**
- No additional dependency (stow not installed by default on macOS)
- Full control over backup behavior
- Easier to understand for contributors
- Can integrate OS-conditional logic directly

**When to consider Stow:**
- Managing 10+ application configs
- Need to frequently enable/disable app configs
- Want per-app `stow nvim` commands

**Manual linking in install.sh:**
```bash
# Simple and explicit
safe_link "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
safe_link "$DOTFILES/kitty/.config/kitty" "$HOME/.config/kitty"
safe_link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"
```

---

## Sources

### HIGH Confidence (Official/Authoritative)
- [dotfiles.github.io](https://dotfiles.github.io/) - Community standard reference
- [dotfiles.github.io/bootstrap](https://dotfiles.github.io/bootstrap/) - Bootstrap patterns
- [GNU Stow Documentation](https://www.gnu.org/software/stow/manual/) - Stow behavior

### MEDIUM Confidence (Well-Regarded Community)
- [Holman's dotfiles](https://github.com/holman/dotfiles) - Topical organization pattern
- [System Crafters - GNU Stow Guide](https://systemcrafters.net/managing-your-dotfiles/using-gnu-stow/) - XDG structure with Stow
- [Atlassian - Bare Git Dotfiles](https://www.atlassian.com/git/tutorials/dotfiles) - Alternative bare repo approach
- [Arch Wiki - Dotfiles](https://wiki.archlinux.org/title/Dotfiles) - Comprehensive reference

### Verification Applied
- Cross-platform patterns verified across multiple repositories
- OS detection methods confirmed across sources
- XDG directory structure confirmed with Arch Wiki and multiple implementations
