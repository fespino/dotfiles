# Roadmap: Dotfiles

## Overview

This roadmap transforms a collection of config files into a cross-platform bootstrap system. Starting with safety foundations (gitignore, backup patterns) and the core install script, we build outward through shell configuration, package management, application configs, language runtimes, and documentation. Each phase delivers something usable - after Phase 3, you have a working shell on any machine.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [ ] **Phase 0: Initial Fixes** - Address critical gaps in current dotfiles
- [ ] **Phase 1: Foundation** - Safety patterns, directory structure, core install.sh
- [ ] **Phase 2: Shell Configuration** - Zsh with Antidote + Starship, cross-platform paths
- [ ] **Phase 3: Package Management** - Brewfile for Mac, apt list for Debian, CLI tools
- [ ] **Phase 4: Application Configs** - Kitty, tmux, neovim with auto-bootstrap
- [ ] **Phase 5: Language Runtimes** - Node, Python via mise; optional Elixir, Rust
- [ ] **Phase 6: Documentation** - README, inline comments, decision log, keybindings

### v2 Milestone

- [ ] **Phase 7: Enhanced Bootstrap** - Remote install, selective components, robustness
- [ ] **Phase 8: Polish** - Fast startup, git config per-platform, credential helpers

## Phase Details

### Phase 0: Initial Fixes
**Goal**: Fix critical gaps in current dotfiles before building the bootstrap system
**Depends on**: Nothing (first phase)
**Requirements**: INIT-01, INIT-02, INIT-03, INIT-04
**Success Criteria** (what must be TRUE):
  1. `.gitignore` exists and prevents committing secrets (*.pem, .env*, .ssh/, credentials)
  2. XDG base directories are set in shell config (`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`)
  3. All hardcoded `/Users/fespino/` and `/home/fespino/` paths in .zshrc replaced with `$HOME`
  4. Pre-commit hook installed that scans for secrets (gitleaks or detect-secrets)
**Plans**: TBD

Plans:
- [ ] 00-01: TBD

### Phase 1: Foundation
**Goal**: User can run install.sh to safely set up symlinks with backup protection
**Depends on**: Nothing (first phase)
**Requirements**: BOOT-01, BOOT-02, BOOT-03, BOOT-04
**Success Criteria** (what must be TRUE):
  1. User can run `./install.sh` and see setup begin
  2. Script correctly detects macOS vs Linux and reports it
  3. Existing config files are backed up to timestamped directory before symlink creation
  4. User can run `./install.sh --dry-run` to preview changes without executing
  5. Running install.sh twice produces same result without errors (idempotent)
**Plans**: TBD

Plans:
- [ ] 01-01: TBD

### Phase 2: Shell Configuration
**Goal**: User has a fast, modern zsh setup that works identically on Mac and Linux
**Depends on**: Phase 1
**Requirements**: SHELL-01, SHELL-02, SHELL-03, SHELL-04
**Success Criteria** (what must be TRUE):
  1. Zsh config loads without errors on both macOS and Debian Linux
  2. Plugins load via Antidote (not oh-my-zsh) with fast startup
  3. Starship prompt renders with custom configuration
  4. User can create ~/.zshrc.local for machine-specific overrides that auto-load
**Plans**: TBD

Plans:
- [ ] 02-01: TBD

### Phase 3: Package Management
**Goal**: Essential packages install automatically based on detected platform
**Depends on**: Phase 2
**Requirements**: PKG-01, PKG-02, PKG-03
**Success Criteria** (what must be TRUE):
  1. Brewfile exists and `brew bundle` installs all Mac packages
  2. Debian package list exists and apt installs packages automatically
  3. CLI tools (fzf, ripgrep, bat, etc.) are installed and available in PATH
**Plans**: TBD

Plans:
- [ ] 03-01: TBD

### Phase 4: Application Configs
**Goal**: Terminal applications are configured and ready to use after install
**Depends on**: Phase 3
**Requirements**: APP-01, APP-02, APP-03, APP-04
**Success Criteria** (what must be TRUE):
  1. Kitty terminal config is symlinked and kitty launches with custom settings
  2. Tmux config is symlinked and TPM auto-installs plugins on first run
  3. Neovim config is symlinked and lazy.nvim auto-bootstraps on first launch
  4. Nerd Fonts are installed and terminal displays icons correctly
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

### Phase 5: Language Runtimes
**Goal**: Language development environments are available via mise
**Depends on**: Phase 2 (mise installed via shell config)
**Requirements**: LANG-01, LANG-02, LANG-03, LANG-04
**Success Criteria** (what must be TRUE):
  1. User can install Node.js via `mise use node@lts`
  2. User can install Python via `mise use python@3.12`
  3. User can optionally install Elixir via mise (not installed by default)
  4. User can optionally install Rust via rustup (not installed by default)
**Plans**: TBD

Plans:
- [ ] 05-01: TBD

### Phase 6: Documentation
**Goal**: Users can understand, use, and modify the dotfiles independently
**Depends on**: Phase 4 (configs exist to document)
**Requirements**: DOC-01, DOC-02, DOC-03, DOC-04, DOC-05
**Success Criteria** (what must be TRUE):
  1. README explains installation, directory structure, and usage
  2. Config files contain inline comments explaining each section
  3. Decision log documents why specific tools/approaches were chosen
  4. Keybinding reference exists for quick tmux and neovim shortcut lookup
  5. CLAUDE.md provides context for Claude Code (structure, conventions, anti-patterns)
**Plans**: TBD

Plans:
- [ ] 06-01: TBD

---

## v2 Milestone

### Phase 7: Enhanced Bootstrap
**Goal**: Bootstrap is robust, flexible, and works from a fresh machine with one curl command
**Depends on**: Phase 6 (v1 complete)
**Requirements**: BOOT-05, BOOT-06, BOOT-07, BOOT-08
**Success Criteria** (what must be TRUE):
  1. User can run `curl -sL <url> | bash` to bootstrap from a fresh machine
  2. User can selectively install components (e.g., `./install.sh --only shell,tmux`)
  3. Sudo credentials don't timeout during long package installations
  4. Scripts work identically on macOS (BSD) and Linux (GNU) without errors
**Plans**: TBD

Plans:
- [ ] 07-01: TBD

### Phase 8: Polish
**Goal**: Optimized performance and seamless git workflow across machines
**Depends on**: Phase 7
**Requirements**: SHELL-05, APP-05, APP-06
**Success Criteria** (what must be TRUE):
  1. Shell startup time is under 100ms (`time zsh -i -c exit`)
  2. Git config uses conditional includes for work vs personal repos
  3. Git credential helper auto-configured per platform (osxkeychain on Mac, cache on Linux)
**Plans**: TBD

Plans:
- [ ] 08-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Initial Fixes | 0/TBD | Not started | - |
| 1. Foundation | 0/TBD | Not started | - |
| 2. Shell Configuration | 0/TBD | Not started | - |
| 3. Package Management | 0/TBD | Not started | - |
| 4. Application Configs | 0/TBD | Not started | - |
| 5. Language Runtimes | 0/TBD | Not started | - |
| 6. Documentation | 0/TBD | Not started | - |
| **v2 Milestone** |  |  |  |
| 7. Enhanced Bootstrap | 0/TBD | Not started | - |
| 8. Polish | 0/TBD | Not started | - |

---
*Created: 2026-02-01*
*Updated: 2026-02-01 — added Phase 0, v2 milestone (Phases 7-8)*
*Depth: standard (9 phases across 2 milestones)*
*Coverage: 35/35 requirements mapped (28 v1 + 7 v2)*
