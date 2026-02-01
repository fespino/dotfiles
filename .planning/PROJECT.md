# Dotfiles

## What This Is

A cross-platform dotfiles repository with an automated bootstrap system for Mac and Debian Linux. Run one script on a fresh machine and have a complete development environment ready in minutes — shell, terminal, editor, languages, and CLI tools all configured.

## Core Value

New machine to development-ready in minutes with a single command.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Bootstrap script (`./install.sh`) that detects OS and handles full setup
- [ ] OS-conditional logic in configs for Mac vs Linux path differences
- [ ] Zsh config with aliases, paths, prompt, environment variables
- [ ] Kitty terminal config (fonts, colors, keybindings)
- [ ] Tmux config with keybindings, status bar, plugins
- [ ] Neovim config (existing setup, integrated into bootstrap)
- [ ] Package installation via Homebrew (Mac) and apt (Debian)
- [ ] Language runtime setup: Node.js, Python
- [ ] Optional language support: Elixir, Rust
- [ ] CLI tools installation: fzf, ripgrep, bat, etc.
- [ ] Symlink management with backup of existing files
- [ ] README with installation instructions and overview
- [ ] Inline comments explaining config sections
- [ ] Decision log documenting why choices were made
- [ ] Keybinding reference for tmux, neovim, etc.

### Out of Scope

- i3 window manager config — Linux desktop-specific, not needed for both platforms
- GUI application configs — focus on terminal-based development
- Work-specific configs — this is personal dev environment only
- Docker/container setup — separate concern from dotfiles

## Context

**Existing configs in this repo:**
- `.zshrc` — current shell config
- `kitty/` — terminal configuration
- `tmux/` — tmux with TPM plugin manager
- `i3/` — window manager (Linux-specific, may keep separate)

**Path differences to handle:**
- Homebrew: `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel Mac)
- Linux: standard `/usr/bin`, `/usr/local/bin`
- Config locations may differ between systems

**Target systems:**
- macOS (primary development machine)
- Debian-based Linux (servers, secondary machines)

## Constraints

- **Simplicity**: Conditionals in config files rather than templates or separate files — keeps everything in one place
- **Idempotent**: Script should be safe to run multiple times without breaking things
- **Backup safety**: Always backup existing files before replacing with symlinks
- **No sudo for dotfiles**: Package installation may need sudo, but symlink operations should not

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| OS conditionals vs separate files | Single source of truth, easier to maintain, path differences are minor | — Pending |
| Single install.sh vs Makefile | Simpler UX, one command to remember, can still be modular internally | — Pending |
| Backup and replace strategy | Safe default, preserves user's existing configs, reversible | — Pending |

---
*Last updated: 2026-02-01 after initialization*
