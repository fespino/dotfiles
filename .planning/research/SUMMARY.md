# Research Summary

**Project:** Cross-Platform Dotfiles with Automated Bootstrap
**Domain:** Developer Environment Configuration
**Researched:** 2026-02-01
**Confidence:** HIGH

## Executive Summary

This is a well-understood domain with mature tooling and established best practices. The recommended approach is straightforward: use GNU Stow for symlink management, a single `install.sh` for orchestration, and Homebrew as the cross-platform package manager. The current repository has good structure (app-per-directory) but lacks the install script and symlink management needed for single-command bootstrap.

The recommended stack modernizes the existing setup: replace oh-my-zsh with Antidote for faster shell startup, replace nvm/pyenv with mise for unified runtime management, and replace Powerlevel10k with Starship (p10k is on "life support" as of 2025). These changes consolidate tools while improving performance. The architecture follows the "symlink farm" pattern where configs live in `~/.dotfiles` and get linked to their expected locations.

Key risks center on the bootstrap phase: accidentally committing secrets, destructively overwriting existing configs, and non-idempotent install scripts. All are preventable with proper `.gitignore`, backup-before-link strategy, and existence checks. The shell configuration phase carries performance risk (slow startup from eager NVM/pyenv loading), mitigated by using mise which lazy-loads by default.

## Key Recommendations

### Stack

**Core technologies (HIGH confidence on all):**

1. **GNU Stow** for symlink management - transparent, reversible, no learning curve; simpler than Chezmoi for this scope
2. **Antidote** for zsh plugins - static generation means near-instant startup; replaces oh-my-zsh bloat
3. **Starship** for prompt - actively maintained (unlike Powerlevel10k), cross-shell compatible, simple config
4. **mise** for language runtimes - single tool replaces nvm + pyenv; Rust-based, fast, lazy by default
5. **Homebrew + Brewfile** for packages - works cross-platform, single source of truth

**What to migrate away from:**
- oh-my-zsh (slow, heavy)
- nvm (slow shell startup, single-purpose)
- pyenv (builds from source, slow)
- Powerlevel10k (maintainer stepped back 2025)

### Table Stakes Features

Must-have features users expect from any dotfiles repo:

1. **Single-command bootstrap** - `./install.sh` or `curl | sh` for complete setup
2. **OS detection** - `uname -s` to differentiate Darwin vs Linux
3. **Backup existing files** - timestamped backup directory before overwriting anything
4. **Idempotent installation** - running twice produces same result without errors
5. **Package manager integration** - Homebrew (Mac/Linux) and apt (Debian fallback)
6. **README with install instructions** - one-liner command + what gets installed

**Differentiators worth building:**
- Local overrides file (`.zshrc.local`) for machine-specific config without merge conflicts
- Topical organization (already have this - app-per-directory)
- Dry-run mode (`--dry-run` flag showing planned changes)
- Color-coded output (green/yellow/red for status)

**Explicitly defer:**
- Uninstall script (build if someone asks)
- Template engine (shell conditionals are enough)
- Interactive configuration wizard (use flags instead)

### Architecture

The architecture follows the symlink farm pattern: configs stored in `~/.dotfiles/app/.config/app/` mirror the target structure, so `stow app` (or manual `ln -sf`) links them correctly. Each application gets its own directory.

**Directory structure:**
```
~/.dotfiles/
  install.sh          # Entry point
  scripts/            # Helper functions, per-platform package scripts
  zsh/.zshrc          # -> ~/.zshrc
  kitty/.config/kitty/* # -> ~/.config/kitty/*
  tmux/.tmux.conf     # -> ~/.tmux.conf
  nvim/.config/nvim/* # -> ~/.config/nvim/*
```

**Current structure issues to fix:**
- `.zshrc` in root needs to move to `zsh/.zshrc`
- kitty missing `.config/kitty/` nesting
- tmux uses `tmux.conf` but should be `.tmux.conf`

**Key patterns:**
- Idempotent installation (check before creating)
- Graceful degradation (optional components can fail)
- Configuration sourcing chain (split .zshrc into modular files)
- OS-conditional configuration (single file handles Mac/Linux)

### Critical Pitfalls to Avoid

1. **Committing secrets to Git** - Add comprehensive `.gitignore` from day one (`.env*`, `*.pem`, `.ssh/`, credentials). Use pre-commit hooks with secret scanning.

2. **Non-idempotent install script** - Guard all symlink creation with existence checks. Use `ln -sf` carefully or prefer stow. Test by running install.sh twice.

3. **Destructive symlink overwrites** - Always backup before overwriting: `mkdir -p ~/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)` and move existing files there.

4. **Hardcoded absolute paths** - Current .zshrc has `/Users/fespino/` hardcoded. Use `$HOME` or `~` everywhere. Detect Homebrew path dynamically based on architecture.

5. **Slow shell startup** - Current nvm/pyenv eager loading adds 500ms+. Replace with mise (lazy by default) or use lazy-loading patterns.

6. **Interactive prompts in scripts** - Use `apt-get -y`, `NONINTERACTIVE=1` for Homebrew, `--unattended` for oh-my-zsh.

## Build Order

Based on dependencies and pitfall phase-mapping, implement in this order:

### Phase 1: Foundation & Safety
**Rationale:** Must establish safe patterns before anything else; prevents data loss and security issues
**Delivers:** Secure `.gitignore`, directory restructure, core helper functions
**Addresses:** Project structure, backup strategy
**Avoids:** Pitfall #1 (secrets), #3 (overwrites), #4 (hardcoded paths)

### Phase 2: Core Bootstrap
**Rationale:** Once safety is in place, create the install script shell
**Delivers:** Minimal `install.sh` with OS detection, symlink creation, backup
**Addresses:** Single-command bootstrap, idempotency
**Avoids:** Pitfall #2 (non-idempotent), #5 (interactive prompts)

### Phase 3: Shell Configuration
**Rationale:** Shell is loaded first, sets up environment for everything else
**Delivers:** Modernized zsh config with Antidote + Starship, lazy-loaded runtimes
**Uses:** Antidote, Starship, mise
**Avoids:** Pitfall #6 (slow startup), #7 (OMZ race condition)

### Phase 4: Package Management
**Rationale:** With shell working, automate package installation
**Delivers:** Brewfile, packages.txt, platform-specific install scripts
**Addresses:** Package manager integration, CLI tools
**Avoids:** Pitfall #10 (sudo timeout), #12 (BSD vs GNU differences)

### Phase 5: Application Configs
**Rationale:** Packages installed, now configure them
**Delivers:** Kitty, tmux, neovim configs with plugin bootstrap
**Addresses:** Terminal, multiplexer, editor setup
**Avoids:** Pitfall #8 (TPM missing), #9 (lazy.nvim bootstrap), #14 (fonts)

### Phase 6: Language Runtimes
**Rationale:** With mise installed in Phase 3, configure language versions
**Delivers:** Node, Python, optional Rust/Elixir setup
**Avoids:** Pitfall #16 (version file compatibility)

### Phase 7: Polish & Documentation
**Rationale:** Core functionality complete, add nice-to-haves
**Delivers:** Dry-run mode, remote bootstrap (`curl | sh`), keybindings reference
**Addresses:** Local overrides, documentation

### Phase Ordering Rationale

- **Safety first:** Phases 1-2 establish patterns that prevent data loss throughout
- **Dependencies respected:** Shell (Phase 3) must work before packages (Phase 4) can be tested
- **Incremental value:** Each phase delivers something usable; can stop after Phase 3 for MVP
- **Pitfall alignment:** Critical pitfalls addressed in early phases, moderate in later phases

### Research Flags

**Phases likely needing deeper research:**
- **Phase 3 (Shell):** Migration from oh-my-zsh to Antidote may need iteration; test shell startup time
- **Phase 5 (App Configs):** lazy.nvim bootstrap is well-documented but verify your specific plugin setup

**Phases with standard patterns (skip research-phase):**
- **Phase 1, 2:** Core bash scripting patterns are well-established
- **Phase 4:** Homebrew/apt patterns are standard
- **Phase 6:** mise usage is straightforward once installed

## Open Questions

1. **Which CLI tools to include in Brewfile?** Current research suggests: fzf, ripgrep, fd, bat, eza, lazygit. Confirm based on actual usage.

2. **Keep TPM or switch?** Current tmux uses TPM with sensible/resurrect/continuum. Research says keep it. Consider adding tmux-yank and tmux-sessionx.

3. **Neovim plugin configuration scope?** Verify lazy.nvim bootstrap code exists. Consider whether to commit `lazy-lock.json`.

4. **Git identity handling?** Install script could prompt for git email/name if not set, or document as manual post-install step.

5. **ARM vs x86 detection needed?** Homebrew paths differ on Apple Silicon. Need to detect and handle.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official docs verified, community consensus clear |
| Features | HIGH | Multiple reference implementations, well-documented patterns |
| Architecture | HIGH | Stow pattern documented by GNU, community adoption |
| Pitfalls | HIGH | Verified against multiple sources, common failure modes documented |

**Overall confidence:** HIGH

All research areas had authoritative sources (official documentation, well-maintained community projects, recent 2024-2025 articles). The dotfiles domain is mature with stable best practices.

### Gaps to Address

- **Actual shell startup time:** Need to benchmark current .zshrc vs proposed Antidote setup
- **Elixir/Rust requirements:** Not clear if these are needed; defer to Phase 6 if wanted
- **Work vs personal git config:** May need `includeIf` setup for different email contexts

## Sources

### Primary (HIGH confidence)
- [mise official docs](https://mise.jdx.dev/) - runtime management
- [GNU Stow manual](https://www.gnu.org/software/stow/manual/) - symlink behavior
- [Homebrew Bundle docs](https://docs.brew.sh/Brew-Bundle-and-Brewfile) - Brewfile usage
- [lazy.nvim GitHub](https://github.com/folke/lazy.nvim) - plugin manager bootstrap

### Secondary (MEDIUM confidence)
- [dotfiles.github.io](https://dotfiles.github.io/) - community patterns
- [Holman's dotfiles](https://github.com/holman/dotfiles) - topical organization
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) - macOS reference
- [Powerlevel10k life support (2025)](https://hashir.blog/2025/06/powerlevel10k-is-on-life-support-hello-starship/) - p10k status

### Tertiary (verified but specialized)
- [Zsh plugin manager benchmark](https://github.com/rossmacarthur/zsh-plugin-manager-benchmark) - performance data
- [mise vs asdf (Better Stack)](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/) - comparison

---
*Research completed: 2026-02-01*
*Ready for roadmap: yes*
