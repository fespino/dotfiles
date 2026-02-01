# Phase 0: Initial Fixes - Research

**Researched:** 2026-02-01
**Domain:** Dotfiles security, XDG configuration, shell scripting, pre-commit hooks
**Confidence:** HIGH

## Summary

This phase addresses critical security and hygiene gaps in the dotfiles repository before building the bootstrap system. The four requirements (INIT-01 through INIT-04) are foundational and prevent serious issues like secret exposure and configuration portability problems.

The research confirms:
1. A comprehensive `.gitignore` is essential and should be created immediately
2. XDG Base Directory specification is well-documented and straightforward to implement in zsh
3. Current `.zshrc` has already been fixed - no hardcoded `/Users/fespino/` or `/home/fespino/` paths remain
4. Gitleaks is the recommended choice for pre-commit secret scanning due to speed and broad detection coverage

**Primary recommendation:** Create `.gitignore` first, then add XDG variables to `.zshrc`, then install pre-commit with gitleaks. The hardcoded path requirement (INIT-03) appears already satisfied.

## Standard Stack

The established tools for this phase:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| pre-commit | latest | Hook framework | De facto standard, language-agnostic, well-maintained |
| gitleaks | 8.24.2 | Secret scanning | Fast, 160+ secret types, active development |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| detect-secrets | 1.5.0 | Alternative scanner | If lower false positives needed (enterprise focus) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| gitleaks | detect-secrets | detect-secrets has lower false positives but fewer built-in rules |
| gitleaks | truffleHog | truffleHog scans git history more thoroughly but slower |

**Installation:**
```bash
# macOS
brew install pre-commit gitleaks

# Linux (Ubuntu/Debian)
pip install pre-commit
# gitleaks: download from GitHub releases or use pre-commit's Docker image
```

## Architecture Patterns

### Recommended .gitignore Structure

The `.gitignore` must cover:
1. **Secret files** - Private keys, certificates, credentials
2. **Environment files** - `.env*`, local config overrides
3. **SSH directory** - Never commit `.ssh/`
4. **Application credentials** - AWS, npm, etc.
5. **Local overrides** - Files with `.local` suffix for machine-specific settings

```gitignore
# Secrets and credentials
*.pem
*.key
*.pfx
*.p12
*.crt
*.cer
id_*
!*.pub

# Environment and local config
.env
.env.*
*.local
.secrets*
.netrc
.npmrc

# SSH directory
.ssh/

# Application credentials
.aws/credentials
.docker/config.json

# Sensitive history
.bash_history
.zsh_history
.node_repl_history

# Editor/IDE local files
.vscode/settings.json
.idea/
```

### XDG Base Directory Setup

Place these at the TOP of `.zshrc` (before any other configuration):

```bash
# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Ensure directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
```

**Key insight:** The `${VAR:-default}` syntax respects existing values while providing defaults. This is the idiomatic pattern.

### Pre-commit Configuration

`.pre-commit-config.yaml` at repository root:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.24.2
    hooks:
      - id: gitleaks
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Secret detection | Custom grep patterns | gitleaks | 160+ secret types, entropy detection, maintained regex |
| Pre-commit framework | Manual git hook scripts | pre-commit | Handles installation, updates, multiple hooks |
| .gitignore patterns | Ad-hoc additions | Established templates | Community-tested, covers edge cases |

**Key insight:** Secret detection via custom grep is unreliable. Gitleaks uses heuristics including entropy analysis, not just regex matching.

## Common Pitfalls

### Pitfall 1: Incomplete .gitignore on Day 1
**What goes wrong:** Secrets committed early, then stuck in git history forever
**Why it happens:** .gitignore added after initial commits; history cleaning is complex
**How to avoid:** Create .gitignore as FIRST file before any other work
**Warning signs:** Files without .gitignore in initial commits

### Pitfall 2: XDG Variables Set Too Late
**What goes wrong:** Applications read defaults before XDG vars are set
**Why it happens:** XDG exports placed after oh-my-zsh or other tool initialization
**How to avoid:** Set XDG variables at very top of .zshrc, before sourcing anything
**Warning signs:** Config files still appearing in $HOME instead of $XDG_CONFIG_HOME

### Pitfall 3: Pre-commit Install Forgotten After Clone
**What goes wrong:** Hooks not active, secrets can be committed
**Why it happens:** `pre-commit install` must run in every clone
**How to avoid:** Add to install.sh or README prominently; consider setup script
**Warning signs:** `git commit` succeeds without hook output

### Pitfall 4: Gitleaks Blocking Legitimate Content
**What goes wrong:** False positives on example API keys, documentation
**Why it happens:** Gitleaks pattern matching is aggressive
**How to avoid:** Use `.gitleaks.toml` allowlist or inline `# gitleaks:allow` comments
**Warning signs:** Unable to commit documentation with example secrets

## Code Examples

### Complete .gitignore for Dotfiles

```gitignore
# Source: Community best practices (multiple dotfiles repos)

#-------------------------------------------------------------------------------
# SECRETS - Never commit these
#-------------------------------------------------------------------------------

# Private keys and certificates
*.pem
*.key
*.pfx
*.p12
id_rsa*
id_dsa*
id_ecdsa*
id_ed25519*
# Allow public keys
!*.pub

# SSH directory (contains sensitive config)
.ssh/

# Environment files
.env
.env.*
.envrc

# Local override files (machine-specific secrets)
*.local
.secrets
.secrets.*

# Credential files
.netrc
.npmrc
.pypirc
credentials
credentials.*
*credentials*

# Cloud provider credentials
.aws/credentials
.aws/config
.gcloud/
.azure/

# Application tokens
.docker/config.json
.kube/config

#-------------------------------------------------------------------------------
# HISTORY FILES - May contain sensitive commands
#-------------------------------------------------------------------------------
.bash_history
.zsh_history
.python_history
.node_repl_history
.lesshst
.wget-hsts

#-------------------------------------------------------------------------------
# LOCAL/EDITOR FILES
#-------------------------------------------------------------------------------
.DS_Store
*.swp
*.swo
*~
.idea/
.vscode/settings.json
```

### XDG Setup in .zshrc

```bash
# Source: XDG Base Directory Specification (freedesktop.org)
# Place at TOP of .zshrc, before any other configuration

# Core XDG directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Ensure directories exist (safe to run multiple times)
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

# Optional: Move zsh config to XDG (requires .zshenv in $HOME)
# export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
# export HISTFILE="$XDG_STATE_HOME/zsh/history"
```

### Pre-commit Installation Script

```bash
#!/bin/bash
# Source: pre-commit.com, gitleaks GitHub

# Install pre-commit framework
if command -v brew &>/dev/null; then
  brew install pre-commit
elif command -v pip &>/dev/null; then
  pip install pre-commit
else
  echo "Warning: Cannot install pre-commit. Install manually."
  exit 1
fi

# Install hooks into repository
cd "$(dirname "$0")" || exit 1
pre-commit install

echo "Pre-commit hooks installed. Gitleaks will scan for secrets on each commit."
```

### .pre-commit-config.yaml

```yaml
# Source: https://github.com/gitleaks/gitleaks

repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.24.2
    hooks:
      - id: gitleaks
```

### Optional: .gitleaks.toml for False Positive Handling

```toml
# Source: gitleaks documentation

[allowlist]
  description = "Allowlist for known false positives"

  # Allow specific files
  paths = [
    '''README\.md''',
    '''docs/.*''',
  ]

  # Allow specific patterns (example keys in docs)
  regexes = [
    '''EXAMPLE_.*''',
    '''test_.*_key''',
  ]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual grep for secrets | Entropy-based detection (gitleaks) | 2020+ | Catches high-entropy strings, not just patterns |
| Scattered dotfiles in $HOME | XDG Base Directory | 2010 (spec), 2020+ (adoption) | Cleaner home directory, easier backup |
| Git hook shell scripts | pre-commit framework | 2017+ | Language-agnostic, auto-updating hooks |

**Deprecated/outdated:**
- Manual `.git/hooks/pre-commit` scripts: Use pre-commit framework instead
- Hardcoded username paths: Always use `$HOME` variable

## Findings by Requirement

### INIT-01: .gitignore for Secrets
**Status:** Not yet implemented
**Action:** Create `.gitignore` file with comprehensive patterns
**Confidence:** HIGH - patterns well-established in community

### INIT-02: XDG Base Directories
**Status:** Not yet implemented
**Action:** Add XDG exports at top of `.zshrc`
**Confidence:** HIGH - specification is official and well-documented

### INIT-03: Fix Hardcoded Paths
**Status:** ALREADY COMPLETE
**Evidence:** Grep of entire repository found no `/Users/fespino/` or `/home/fespino/` in actual config files (only in documentation/planning files describing the issue)
**Confidence:** HIGH - verified via grep search

### INIT-04: Pre-commit Secret Scanning
**Status:** Not yet implemented
**Action:** Install pre-commit with gitleaks hook
**Recommendation:** Use gitleaks over detect-secrets
**Rationale:**
  - Faster execution
  - 160+ built-in secret types
  - Simpler setup (no baseline management required)
  - Active development
**Confidence:** HIGH - gitleaks is widely recommended, verified via official docs

## Open Questions

1. **ZDOTDIR migration scope:** Should `.zshrc` be moved to `$XDG_CONFIG_HOME/zsh/` as part of this phase, or defer to later?
   - What we know: Requires `.zshenv` in `$HOME` to set ZDOTDIR
   - Recommendation: Defer - adds complexity, not strictly required for XDG compliance

2. **History file relocation:** Move `.zsh_history` to `$XDG_STATE_HOME`?
   - What we know: Possible with HISTFILE variable
   - Recommendation: Defer - can cause issues if not done carefully

## Sources

### Primary (HIGH confidence)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/0.6/) - Official specification
- [XDG Base Directory - ArchWiki](https://wiki.archlinux.org/title/XDG_Base_Directory) - Comprehensive implementation guide
- [gitleaks GitHub](https://github.com/gitleaks/gitleaks) - Official documentation
- [pre-commit.com](https://pre-commit.com/) - Official pre-commit framework docs

### Secondary (MEDIUM confidence)
- [Homebrew Formulae - pre-commit](https://formulae.brew.sh/formula/pre-commit) - Installation instructions
- [Secret Scanning in CI pipelines using Gitleaks](https://dev.to/sirlawdin/secret-scanning-in-ci-pipelines-using-gitleaks-and-pre-commit-hook-1e3f) - Practical setup guide
- [Yelp/detect-secrets GitHub](https://github.com/Yelp/detect-secrets) - Alternative tool documentation

### Tertiary (LOW confidence)
- Community dotfiles repositories - .gitignore patterns
- Web search results - General best practices

## Metadata

**Confidence breakdown:**
- .gitignore patterns: HIGH - community consensus, multiple sources agree
- XDG setup: HIGH - official specification, ArchWiki verification
- Hardcoded paths status: HIGH - verified via grep of repository
- Pre-commit/gitleaks: HIGH - official documentation consulted

**Research date:** 2026-02-01
**Valid until:** 2026-03-01 (patterns and tools stable)
