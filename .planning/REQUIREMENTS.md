# Requirements: Dotfiles

**Defined:** 2026-02-01
**Core Value:** New machine to development-ready in minutes with a single command.

## v1 Requirements

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

## v2 Requirements

### Enhanced Bootstrap

- **BOOT-05**: Remote bootstrap via `curl | bash` for fresh machines
- **BOOT-06**: Selective install (choose specific components)

### Shell Improvements

- **SHELL-05**: Shell startup time under 100ms

### Additional Integrations

- **APP-05**: Git config with conditional includes for work/personal

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
| BOOT-01 | TBD | Pending |
| BOOT-02 | TBD | Pending |
| BOOT-03 | TBD | Pending |
| BOOT-04 | TBD | Pending |
| SHELL-01 | TBD | Pending |
| SHELL-02 | TBD | Pending |
| SHELL-03 | TBD | Pending |
| SHELL-04 | TBD | Pending |
| APP-01 | TBD | Pending |
| APP-02 | TBD | Pending |
| APP-03 | TBD | Pending |
| APP-04 | TBD | Pending |
| PKG-01 | TBD | Pending |
| PKG-02 | TBD | Pending |
| PKG-03 | TBD | Pending |
| LANG-01 | TBD | Pending |
| LANG-02 | TBD | Pending |
| LANG-03 | TBD | Pending |
| LANG-04 | TBD | Pending |
| DOC-01 | TBD | Pending |
| DOC-02 | TBD | Pending |
| DOC-03 | TBD | Pending |
| DOC-04 | TBD | Pending |

**Coverage:**
- v1 requirements: 23 total
- Mapped to phases: 0
- Unmapped: 23 ⚠️

---
*Requirements defined: 2026-02-01*
*Last updated: 2026-02-01 after initial definition*
