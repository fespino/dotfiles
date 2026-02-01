# Requirements: Dotfiles

**Defined:** 2026-02-01
**Core Value:** New machine to development-ready in minutes with a single command.

## v1 Requirements

### Initial (Phase 0)

- [x] **INIT-01**: Repository has .gitignore preventing secrets from being committed
- [x] **INIT-02**: XDG base directories configured to reduce home directory clutter
- [x] **INIT-03**: Existing .zshrc hardcoded paths fixed to use $HOME
- [x] **INIT-04**: Pre-commit hooks scan for secrets before allowing commits

### Bootstrap

- [ ] **BOOT-01**: User can run `./install.sh` to set up entire environment
- [ ] **BOOT-02**: Script detects OS (Mac vs Linux) and adjusts behavior accordingly
- [ ] **BOOT-03**: Script backs up existing config files before replacing with symlinks
- [ ] **BOOT-04**: Script supports dry-run mode to preview changes without executing

### Shell

- [ ] **SHELL-01**: Zsh config works on both Mac and Linux with correct paths
- [ ] **SHELL-02**: Zsh plugins managed via Antidote (replaces oh-my-zsh)
- [ ] **SHELL-03**: Prompt rendered via Starship with custom configuration
- [ ] **SHELL-04**: User can create `~/.zshrc.local` for machine-specific overrides

### Applications

- [ ] **APP-01**: Kitty terminal config symlinked and working
- [ ] **APP-02**: Tmux config symlinked with TPM auto-installed on first run
- [ ] **APP-03**: Neovim config symlinked with lazy.nvim auto-bootstrapped
- [ ] **APP-04**: Nerd Fonts installed for terminal icons
- [ ] **APP-07**: gh CLI config symlinked with custom settings (editor, browser, protocol)
- [ ] **APP-08**: gh aliases configured for common workflows
- [ ] **APP-09**: Git aliases integrate with gh (e.g., `git pr` → `gh pr create`)

### Packages

- [ ] **PKG-01**: Brewfile defines Mac packages, installed via `brew bundle`
- [ ] **PKG-02**: apt package list defines Debian packages, installed automatically
- [ ] **PKG-03**: CLI tools installed: fzf, ripgrep, bat, and other essentials

### Language Runtimes

- [ ] **LANG-01**: Node.js installable via mise
- [ ] **LANG-02**: Python installable via mise
- [ ] **LANG-03**: Elixir optionally installable/uninstallable via mise
- [ ] **LANG-04**: Rust optionally installable/uninstallable via rustup

### Documentation

- [ ] **DOC-01**: README explains installation, structure, and usage
- [ ] **DOC-02**: Config files contain inline comments explaining sections
- [ ] **DOC-03**: Decision log documents why specific tools/approaches were chosen
- [ ] **DOC-04**: Keybinding reference provides quick lookup for tmux, neovim shortcuts
- [ ] **DOC-05**: CLAUDE.md provides context for Claude Code to work with dotfiles

## v2 Requirements

### Enhanced Bootstrap

- **BOOT-05**: Remote bootstrap via `curl | bash` for fresh machines
- **BOOT-06**: Selective install (choose specific components)
- **BOOT-07**: Sudo keep-alive pattern prevents timeout during long installs
- **BOOT-08**: Scripts use portable constructs or abstract BSD vs GNU differences

### Shell Improvements

- **SHELL-05**: Shell startup time under 100ms

### Additional Integrations

- **APP-05**: Git config with conditional includes for work/personal
- **APP-06**: Git credential helper configured per platform (osxkeychain/cache)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Linuxbrew | Native apt on Linux is simpler, no need for Homebrew compatibility layer |
| i3 config | Linux desktop-specific, not needed for cross-platform dev environment |
| GUI application configs | Focus is terminal-based development |
| SSH key generation | Security-sensitive, handled manually |
| Work-specific configs | Personal dev environment only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INIT-01 | Phase 0 | Complete |
| INIT-02 | Phase 0 | Complete |
| INIT-03 | Phase 0 | Complete |
| INIT-04 | Phase 0 | Complete |
| BOOT-01 | Phase 1 | Pending |
| BOOT-02 | Phase 1 | Pending |
| BOOT-03 | Phase 1 | Pending |
| BOOT-04 | Phase 1 | Pending |
| SHELL-01 | Phase 2 | Pending |
| SHELL-02 | Phase 2 | Pending |
| SHELL-03 | Phase 2 | Pending |
| SHELL-04 | Phase 2 | Pending |
| PKG-01 | Phase 3 | Pending |
| PKG-02 | Phase 3 | Pending |
| PKG-03 | Phase 3 | Pending |
| APP-01 | Phase 4 | Pending |
| APP-02 | Phase 4 | Pending |
| APP-03 | Phase 4 | Pending |
| APP-04 | Phase 4 | Pending |
| APP-07 | Phase 4 | Pending |
| APP-08 | Phase 4 | Pending |
| APP-09 | Phase 4 | Pending |
| LANG-01 | Phase 5 | Pending |
| LANG-02 | Phase 5 | Pending |
| LANG-03 | Phase 5 | Pending |
| LANG-04 | Phase 5 | Pending |
| DOC-01 | Phase 6 | Pending |
| DOC-02 | Phase 6 | Pending |
| DOC-03 | Phase 6 | Pending |
| DOC-04 | Phase 6 | Pending |
| DOC-05 | Phase 6 | Pending |
| BOOT-05 | Phase 7 (v2) | Pending |
| BOOT-06 | Phase 7 (v2) | Pending |
| BOOT-07 | Phase 7 (v2) | Pending |
| BOOT-08 | Phase 7 (v2) | Pending |
| SHELL-05 | Phase 8 (v2) | Pending |
| APP-05 | Phase 8 (v2) | Pending |
| APP-06 | Phase 8 (v2) | Pending |

**Coverage:**
- v1 requirements: 31 total (Phases 0-6)
- v2 requirements: 7 total (Phases 7-8)
- Mapped to phases: 38
- Unmapped: 0

---
*Requirements defined: 2026-02-01*
*Last updated: 2026-02-01 after roadmap creation*
