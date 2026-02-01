# Feature Landscape

**Domain:** Cross-platform dotfiles repository with automated bootstrap
**Researched:** 2026-02-01
**Confidence:** HIGH (well-documented domain, many reference implementations)

## Table Stakes

Features users expect from a dotfiles repository. Missing any of these makes the repo feel incomplete or unreliable.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Single-command bootstrap | Core value prop of dotfiles repos; "curl \| sh" or "./install.sh" | Medium | Must handle both fresh installs and updates |
| OS detection | Cross-platform is meaningless without it; `uname -s` is standard | Low | Darwin vs Linux at minimum |
| Symlink management | How configs get from repo to $HOME; fundamental mechanic | Medium | ln -sf with proper path handling |
| Backup existing files | Users terrified of losing existing configs; trust issue | Medium | Timestamped backup dir or .backup suffix |
| Idempotent installation | Run multiple times safely; essential for updates | Medium | Check before creating, don't duplicate |
| Version control (Git) | Track changes, sync across machines, backup | Low | Already using Git |
| README with install instructions | How do I use this? First thing people look for | Low | One-liner command + what gets installed |
| Shell config (zsh/bash) | Primary config most people care about | Low | Aliases, PATH, prompt, environment |
| Package manager integration | Installing deps is part of "one command setup" | Medium | Homebrew (Mac), apt (Debian) |
| Basic error handling | Script shouldn't silently fail or leave partial state | Medium | set -e, meaningful error messages |

### Why These Are Non-Negotiable

From community consensus and popular repositories (mathiasbynens/dotfiles, holman/dotfiles):

- **Single-command bootstrap**: "A curl \| sh installer offers portable and effortless setup" - this is the core promise
- **Backup before replace**: "Setup backs up existing files to ~/.dotfiles.backups. It is non-destructive, every run" - trust is earned
- **Idempotent**: "Like all good installation scripts, make it idempotent: Running it twice should not add the configuration twice"

## Differentiators

Features that improve quality of life but aren't expected. These separate "works" from "works well."

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Topical organization | Configs grouped by tool (git/, zsh/, tmux/) not flat files | Low | Holman-style organization; easier to navigate |
| Local overrides file | Machine-specific settings without modifying tracked files | Low | ~/.extra or ~/.local sourced after main config |
| Dry-run mode | Preview what will happen before doing it | Low | --dry-run flag showing planned symlinks |
| Verbose/quiet modes | Control output level for debugging vs clean runs | Low | -v for verbose, -q for quiet |
| Selective installation | Install only what you need (e.g., just zsh, skip vim) | Medium | Component flags or interactive prompts |
| Uninstall script | Remove symlinks, restore backups cleanly | Medium | Reverse of install; rarely implemented |
| XDG compliance | Use ~/.config/ instead of ~/. where possible | Low | Modern standard, cleaner home directory |
| Plugin manager integration | TPM for tmux, vim-plug for vim, etc. | Medium | Auto-install on first run |
| Color-coded output | Visual feedback on success/skip/error | Low | Green/yellow/red for status |
| Progress indicators | Know something is happening during long operations | Low | "Installing packages..." with status |
| Private config pattern | Documented way to keep secrets out of repo | Low | .gitignore + template for local secrets file |
| Inline documentation | Comments explaining WHY, not just WHAT | Low | Future-you will thank present-you |
| Keybinding reference | Quick lookup for tmux/vim/etc bindings | Low | KEYBINDINGS.md or cheatsheet |

### High-Value Differentiators (Recommended)

Based on research, these provide most value for effort:

1. **Local overrides file** - Allows customization without merge conflicts; used by mathiasbynens/dotfiles
2. **Topical organization** - Holman's approach makes maintenance easier as repo grows
3. **Dry-run mode** - Builds trust, especially for first-time users or updates
4. **Color-coded output** - Low effort, high UX improvement

## Anti-Features

Features to deliberately NOT build. Common mistakes that add complexity without proportional value.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Template engine | Over-engineering for simple conditionals; adds tooling dependency | Use shell conditionals (`if [[ "$OSTYPE" == darwin* ]]`) |
| Database for state | Dotfiles are files, not an application; tracks what symlinks exist | Filesystem is the source of truth; check with `readlink` |
| Auto-sync daemon | Complexity of background process, failure modes, conflicts | Manual `git pull && ./install.sh` is sufficient |
| GUI installer | Terminal users don't need GUIs; adds massive complexity | Shell script is the interface |
| Multiple branch strategy | One branch per machine creates merge hell | Single branch with conditionals or local overrides |
| Encrypted config files | GPG/age encryption adds key management overhead | Keep secrets out of repo entirely; use local untracked files |
| Custom dotfile manager | Reinventing chezmoi/stow; maintenance burden | Use existing tools OR keep script simple |
| Dependency on non-standard tools | Requiring Python/Ruby/etc. before bootstrap works | Pure POSIX shell or bash for bootstrap |
| Interactive configuration wizard | Adds complexity, breaks automation, rarely better than defaults | Sensible defaults + local overrides file |
| Auto-update mechanism | Pulls changes without user consent; can break things | User runs update explicitly |
| Per-file encryption | Fine-grained encryption is operational nightmare | All-or-nothing: secrets file is excluded, everything else is public |
| Complex rollback system | Version control IS your rollback system | `git checkout` or restore from backup dir |

### Why These Are Traps

From community post-mortems and discussions:

- **Template engines**: "It's best to just go ahead and write some shell script. It's not so hard and will serve as a useful counter-pressure against any urge to over-engineer"
- **Over-engineering secrets**: "Carefully keeping a .gitignore file at the home directory to manage include and exclude lists is risky. At some point, one of the paths gets wrong"
- **Multiple branches**: Creates divergent configurations that become impossible to reconcile

### Complexity Budget

The project constraint is **simplicity**. Every feature must justify its complexity cost:

| Complexity Level | Budget | Current Allocation |
|------------------|--------|-------------------|
| Low (shell conditionals, file operations) | Unlimited | Table stakes |
| Medium (package manager integration, backup strategy) | 3-5 features | Bootstrap, symlinks, backups |
| High (external tools, complex state) | 0-1 features | None recommended |

## Feature Dependencies

```
Core Dependencies (must build in order):
----------------------------------------
OS Detection
    |
    v
Package Manager Integration -----> Language Runtimes (Node, Python, etc.)
    |
    v
Symlink Management -----> Backup Existing Files
    |
    v
Shell Config (zsh) -----> CLI Tools (fzf, ripgrep, etc.)
    |
    v
Terminal Config (kitty) -----> Tmux Config -----> Neovim Config


Optional Dependencies:
----------------------
Local Overrides File <---- depends on ---- Shell Config
Plugin Managers <---- depends on ---- Respective Tool Config
Dry-run Mode <---- depends on ---- Symlink Management
Uninstall Script <---- depends on ---- Symlink Management + Backup
```

### Suggested Build Order

1. **Foundation**: OS detection, basic install.sh structure
2. **Core Loop**: Symlink management with backup
3. **Configs**: Shell, then terminal, then tmux, then neovim
4. **Packages**: Package manager integration, CLI tools
5. **Languages**: Node, Python (optional: Elixir, Rust)
6. **Polish**: Local overrides, dry-run, documentation

## MVP Recommendation

For a minimum viable dotfiles repo, prioritize:

### Must Have (Week 1)
1. `install.sh` with OS detection (Darwin/Linux)
2. Symlink management with backup to timestamped directory
3. Zsh config integration
4. Basic README with install command

### Should Have (Week 2)
1. Package installation (Homebrew/apt)
2. Kitty, tmux, neovim config symlinks
3. Error handling and status output
4. Local overrides file pattern (.extra or .local)

### Nice to Have (Later)
1. CLI tools installation
2. Language runtime setup
3. Dry-run mode
4. Selective installation
5. Keybinding reference

### Explicitly Defer
- Uninstall script (build if someone asks)
- Complex backup rotation (simple timestamped dir is fine)
- Any form of templating beyond shell conditionals
- Interactive prompts (use flags instead)

## Sources

### Primary References
- [GitHub does dotfiles](https://dotfiles.github.io/) - Community hub for dotfiles resources
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) - 31k+ stars, macOS-focused reference
- [holman/dotfiles](https://github.com/holman/dotfiles) - Topic-centric organization pioneer
- [awesome-dotfiles](https://github.com/webpro/awesome-dotfiles) - Curated resource list

### Tool Documentation
- [Dotbot](https://github.com/anishathalye/dotbot) - Lightweight bootstrap tool
- [chezmoi](https://www.chezmoi.io/) - Full-featured dotfile manager
- [GNU Stow](https://www.gnu.org/software/stow/) - Symlink farm manager

### Best Practices
- [The Ultimate Guide to Mastering Dotfiles](https://www.daytona.io/dotfiles/ultimate-guide-to-dotfiles)
- [Manage Your Dotfiles Like a Superhero](https://www.jakewiesler.com/blog/managing-dotfiles)
- [My tips for maintaining dotfiles in source control](https://opensource.com/article/22/2/dotfiles-source-control)
- [Cross-platform dotfiles](https://calvin.me/cross-platform-dotfiles/)

### Cross-Platform Strategies
- [Cross-platform dotfile management with dotbot](https://brianschiller.com/blog/2024/08/05/cross-platform-dotbot/)
- [Bas Nijholt's dotfiles](https://www.nijho.lt/post/dotfiles/) - Practical cross-platform setup
