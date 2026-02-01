# Stack Research: Cross-Platform Dotfiles

**Project:** Cross-platform dotfiles with automated bootstrap
**Researched:** 2026-02-01
**Overall Confidence:** HIGH

## Executive Summary

For a cross-platform dotfiles system targeting Mac and Debian Linux with a "single command to development-ready" goal, the recommended stack prioritizes simplicity, active maintenance, and performance. The key insight is that **you don't need a sophisticated dotfile manager**—GNU Stow handles symlinking elegantly, and a well-structured `install.sh` handles the rest.

Your current setup uses oh-my-zsh + nvm + pyenv, which works but has performance and maintenance tradeoffs. The modern stack trades complexity for speed and consolidation.

---

## Recommended Stack

### Dotfile Management

| Technology | Version | Purpose | Confidence |
|------------|---------|---------|------------|
| **GNU Stow** | latest | Symlink management | HIGH |
| **Custom install.sh** | - | Bootstrap orchestration | HIGH |
| **Git** | latest | Version control | HIGH |

**Why GNU Stow over Chezmoi:**
- Your use case (Mac + Debian) doesn't need templating or secrets management
- Stow is a single `brew install stow` or `apt install stow` away
- Transparent symlinks mean you edit files in place—no `chezmoi edit` indirection
- Reversible: `stow -D package` cleanly removes symlinks
- Already a mature, stable tool (less churn than chezmoi)

**Why NOT Chezmoi:**
- Overkill for your scope. Chezmoi shines when you need templates, secrets in 1Password, or managing 5+ different OS variants
- Adds a learning curve and abstraction layer
- Your OS-conditional logic can live in `install.sh` instead of chezmoi templates

**Pattern:** Structure dotfiles as stow packages:
```
~/.dotfiles/
  zsh/
    .zshrc
    .zsh_plugins.txt
  kitty/
    .config/kitty/
      kitty.conf
  tmux/
    .tmux.conf
  nvim/
    .config/nvim/
      init.lua
```

Then: `stow zsh kitty tmux nvim` creates all symlinks.

**Sources:**
- [GNU Stow dotfiles setup (2025)](https://www.penkin.me/development/tools/productivity/configuration/2025/10/20/my-dotfiles-setup-with-gnu-stow.html)
- [Chezmoi comparison table](https://www.chezmoi.io/comparison-table/)
- [System Crafters Stow guide](https://systemcrafters.net/managing-your-dotfiles/using-gnu-stow/)

---

### Shell Configuration

| Technology | Version | Purpose | Confidence |
|------------|---------|---------|------------|
| **Zsh** | system | Shell | HIGH |
| **Antidote** | latest | Plugin manager | HIGH |
| **Starship** | latest | Prompt | HIGH |

**Why Antidote over oh-my-zsh:**
- Your current oh-my-zsh loads slowly (measured by adding plugins)
- Antidote generates a static file—near-instant startup
- You keep the same plugins (zsh-autosuggestions, zsh-syntax-highlighting) but load them faster
- No framework bloat—you pick exactly what you need

**Why NOT oh-my-zsh:**
- Heavy framework with 200+ plugins you'll never use
- Slower startup (noticeable on every new terminal)
- Updates pull in changes you didn't ask for

**Why NOT Zinit:**
- Steeper learning curve (ice modifiers are confusing)
- Turbulent history (original author deleted repo once)
- Antidote gives 90% of the performance benefit with 10% of the complexity

**Why Starship over Powerlevel10k:**
- Powerlevel10k is on "life support" (maintainer stepped back, 2025)
- Starship is actively maintained, cross-shell compatible
- Written in Rust, minimal resource usage
- Single `starship.toml` config file—simpler than p10k configuration wizard
- If you ever switch to fish or bash, prompt config comes with you

**Recommended plugins (minimal set):**
```txt
# ~/.zsh_plugins.txt
zsh-users/zsh-autosuggestions
zsh-users/zsh-completions
zdharma-continuum/fast-syntax-highlighting
```

**Sources:**
- [Antidote official site](https://antidote.sh/)
- [Powerlevel10k life support announcement (2025)](https://hashir.blog/2025/06/powerlevel10k-is-on-life-support-hello-starship/)
- [Zsh plugin manager benchmark](https://github.com/rossmacarthur/zsh-plugin-manager-benchmark)

---

### Version Managers

| Technology | Version | Purpose | Confidence |
|------------|---------|---------|------------|
| **mise** | latest | All language runtimes | HIGH |

**Why mise (replaces nvm, pyenv, and more):**
- Single tool manages Node, Python, Ruby, Rust, Go, and 100+ others
- Written in Rust—fast (no shims, direct PATH modification)
- Pre-built binaries: Python installs in 15 seconds vs 5+ minutes with pyenv
- Compatible with `.tool-versions` files (asdf format) for team projects
- Active development, modern design

**Why NOT keep nvm + pyenv separate:**
- Two tools to install, configure, and maintain
- nvm adds ~200ms shell startup time (it's slow)
- pyenv builds from source (slow, requires build dependencies)
- mise consolidates everything with better performance

**Why NOT asdf:**
- mise is a faster, maintained alternative to asdf
- asdf uses shims (slower command execution)
- mise re-implements tool support in Rust, not shell scripts

**Migration path:**
```bash
# Install mise
brew install mise  # or: curl https://mise.run | sh

# Migrate from nvm
mise use node@20  # replaces nvm

# Migrate from pyenv
mise use python@3.12  # replaces pyenv
```

**Sources:**
- [mise official docs](https://mise.jdx.dev/)
- [mise vs asdf comparison (Better Stack)](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/)
- [Why switch from asdf to mise](https://medium.com/@nidhivya18_77320/why-i-switched-from-asdf-to-mise-and-you-should-too-8962bf6a6308)

---

### Package Management

| Technology | Platform | Purpose | Confidence |
|------------|----------|---------|------------|
| **Homebrew + Brewfile** | Mac & Linux | Package installation | HIGH |
| **apt** | Debian | System packages (fallback) | HIGH |

**Pattern: Brewfile as source of truth:**
```ruby
# Brewfile
brew "stow"
brew "mise"
brew "starship"
brew "fzf"
brew "ripgrep"
brew "fd"
brew "bat"
brew "eza"  # modern ls replacement
brew "lazygit"
brew "tmux"
brew "neovim"

# Mac-only (cask)
cask "kitty" if OS.mac?
cask "raycast" if OS.mac?
```

**Why Homebrew on Linux too:**
- Single Brewfile works cross-platform
- Homebrew gracefully ignores Mac-only casks on Linux
- Consistent tool versions across machines
- 9% of Homebrew users are on Linux (well-tested)
- Homebrew 5.0.0 (Nov 2025) added official ARM64 Linux support

**When to use apt instead:**
- System-level dependencies (build-essential, libssl-dev)
- Packages not in Homebrew
- Server environments where Homebrew isn't appropriate

**Sources:**
- [Homebrew 5.0.0 release notes](https://brew.sh/2025/11/12/homebrew-5.0.0/)
- [Homebrew Bundle documentation](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [Homebrew Linux discussion (2025)](https://github.com/orgs/Homebrew/discussions/5964)

---

### Symlink Tools

| Technology | Version | Purpose | Confidence |
|------------|---------|---------|------------|
| **GNU Stow** | 2.4+ | Symlink farm manager | HIGH |

**Why Stow over custom scripts:**
- Battle-tested, no edge cases to handle yourself
- Automatic conflict detection
- Easy to add/remove packages
- Handles nested directory structures correctly
- Bug fix in 2025 resolved --dotfiles directory issues

**Stow usage pattern:**
```bash
cd ~/.dotfiles
stow zsh       # Links zsh/.zshrc to ~/.zshrc
stow kitty     # Links kitty/.config/kitty to ~/.config/kitty
stow -D tmux   # Unlinks tmux config
stow -R nvim   # Restow (unlink then relink)
```

**Sources:**
- [How I manage dotfiles with GNU Stow](https://tamerlan.dev/how-i-manage-my-dotfiles-using-gnu-stow/)
- [System Crafters Stow guide](https://systemcrafters.net/managing-your-dotfiles/using-gnu-stow/)

---

### Neovim Plugin Management

| Technology | Version | Purpose | Confidence |
|------------|---------|---------|------------|
| **lazy.nvim** | latest | Plugin manager | HIGH |

**Why lazy.nvim:**
- Packer.nvim is unmaintained since August 2023
- 5-15x faster startup than packer
- Better lazy-loading out of the box
- Active development, modern Lua API
- Automatic bytecode compilation

**Sources:**
- [lazy.nvim GitHub](https://github.com/folke/lazy.nvim)
- [Migrating from Packer to lazy.nvim (2025)](https://lyndon.codes/2025/02/05/moving-from-packer-to-lazy-nvim/)
- [15x faster startup after migration](https://vinitkumar.me/2025-11-06-migrating-from-packer-to-lazy-nvim/)

---

### Tmux Plugin Management

| Technology | Version | Purpose | Confidence |
|------------|---------|---------|------------|
| **TPM** | latest | Tmux Plugin Manager | HIGH |

**You already have this.** Keep it—TPM is the standard and your current plugins are the essentials:
- tmux-sensible (baseline settings)
- tmux-resurrect (persist sessions)
- tmux-continuum (auto-save/restore)

**Optional additions:**
- tmux-yank (better copy/paste)
- tmux-sessionx (session picker with fzf)

**Sources:**
- [TPM GitHub](https://github.com/tmux-plugins/tpm)
- [Best Tmux plugins 2025](https://tmuxai.dev/tmux-plugins/)

---

## Alternatives Considered

| Category | Chosen | Alternative | Why Not Alternative |
|----------|--------|-------------|---------------------|
| Dotfile Manager | GNU Stow | Chezmoi | Overkill—no need for templates or secrets |
| Dotfile Manager | GNU Stow | yadm | More complex than stow for simple use case |
| Dotfile Manager | GNU Stow | Custom scripts | Stow handles edge cases already |
| Shell Framework | Antidote | oh-my-zsh | Slower, heavier, more than you need |
| Shell Framework | Antidote | Zinit | Steeper learning curve, turbulent history |
| Prompt | Starship | Powerlevel10k | p10k on life support, Starship is cross-shell |
| Version Manager | mise | nvm + pyenv | Consolidation + performance |
| Version Manager | mise | asdf | mise is faster (no shims) |
| Neovim Plugin | lazy.nvim | packer.nvim | Packer unmaintained, lazy.nvim faster |

---

## What NOT to Use

### Do NOT Use: oh-my-zsh (for new setups)

**Why it's popular:** Easy to get started, tons of plugins
**Why to avoid:**
- Slow shell startup (200-500ms with plugins)
- Pulls in 200+ plugins you won't use
- Updates can break your config
- Better alternatives exist (Antidote + Starship)

**Migration path:** Extract just the plugins you use, configure with Antidote.

### Do NOT Use: nvm

**Why it's popular:** Default Node version manager
**Why to avoid:**
- Adds ~200ms to shell startup
- Only manages Node (need separate tools for Python, etc.)
- mise does the same thing faster and manages more tools

### Do NOT Use: Powerlevel10k (for new setups)

**Why it's popular:** Beautiful prompts, instant prompt feature
**Why to avoid:**
- Maintainer stepped back (2025)—on "life support"
- Zsh-only (can't take config to other shells)
- Starship offers similar aesthetics with active maintenance

### Do NOT Use: Chezmoi (for this project)

**Why it's popular:** Templates, secrets management, cross-platform
**Why to avoid for YOUR use case:**
- Your Mac/Linux differences can be handled in install.sh
- No secrets to manage in dotfiles
- Adds abstraction layer (chezmoi edit vs direct editing)
- Stow is simpler for your scope

---

## Installation Summary

```bash
# Bootstrap script installs these first
brew install stow mise starship fzf ripgrep fd bat eza neovim tmux

# Mac-only
brew install --cask kitty

# Then use stow to link configs
cd ~/.dotfiles
stow zsh kitty tmux nvim

# Activate mise for runtime management
mise use node@20 python@3.12
```

---

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| Stow over Chezmoi | HIGH | Official docs + community patterns align with simple use case |
| Antidote over oh-my-zsh | HIGH | Benchmarks confirm performance, active maintenance |
| mise over nvm/pyenv | HIGH | Official docs, community adoption, verified performance claims |
| Starship over p10k | HIGH | p10k life support confirmed, Starship actively maintained |
| Homebrew cross-platform | HIGH | Official docs, 5.0.0 release notes confirm Linux support |
| lazy.nvim over packer | HIGH | Packer repo states unmaintained, recommends lazy.nvim |

---

## Sources Summary

**Official Documentation (HIGH confidence):**
- [mise Getting Started](https://mise.jdx.dev/getting-started.html)
- [Chezmoi Quick Start](https://www.chezmoi.io/quick-start/)
- [Antidote Official Site](https://antidote.sh/)
- [Homebrew Bundle Documentation](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [lazy.nvim GitHub](https://github.com/folke/lazy.nvim)

**Community Analysis (MEDIUM confidence):**
- [Powerlevel10k Life Support (2025)](https://hashir.blog/2025/06/powerlevel10k-is-on-life-support-hello-starship/)
- [mise vs asdf (Better Stack)](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/)
- [Zsh Plugin Manager Benchmark](https://github.com/rossmacarthur/zsh-plugin-manager-benchmark)
- [GNU Stow Dotfiles Setup (2025)](https://www.penkin.me/development/tools/productivity/configuration/2025/10/20/my-dotfiles-setup-with-gnu-stow.html)
