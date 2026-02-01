# Phase 1: Foundation - Research

**Researched:** 2026-02-01
**Domain:** Bash scripting for dotfiles bootstrap (safety, idempotency, OS detection, symlinks)
**Confidence:** HIGH

## Summary

Phase 1 builds the core `install.sh` script with OS detection, safe symlink creation with backups, dry-run mode, and proper error handling. The domain is well-established with decades of shell scripting patterns and extensive community documentation on dotfiles management.

The key challenges are:
1. **Idempotency** - Running twice produces same result without errors
2. **Safety** - Never destroy user data; backup before replacing
3. **Cross-platform** - Handle macOS vs Linux differences (especially BSD vs GNU tools)
4. **User experience** - Color output, clear messaging, dry-run preview

**Primary recommendation:** Use pure Bash (not POSIX sh) for better readability and features like `[[ ]]` tests. Implement safety-first defaults with explicit backup, prompt on conflicts, and `--dry-run` preview. Keep the script self-contained in a single file for Phase 1.

## Standard Stack

The established tools and patterns for this domain:

### Core
| Tool | Purpose | Why Standard |
|------|---------|--------------|
| **Bash 3.2+** | Script interpreter | Available on macOS (ships with 3.2) and Linux; sufficient for all needed features |
| **ln -sfn** | Symlink creation | The `-f` force, `-s` symbolic, `-n` no-dereference flags are idempotent |
| **mkdir -p** | Directory creation | Already idempotent; creates parents if missing, no error if exists |
| **readlink** | Check symlink target | Available on both platforms (macOS and Linux) for basic usage |
| **tput** | Terminal capability detection | Portable color detection via terminfo database |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| **date +%Y%m%d_%H%M%S** | Timestamp for backup dirs | Creating unique backup folder names |
| **uname -s** | OS detection | Distinguish Darwin (macOS) from Linux |
| **uname -m** | Architecture detection | Distinguish arm64 from x86_64 for Homebrew paths |
| **test / [ ]** | Conditionals | File existence, symlink checks, TTY detection |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pure Bash | POSIX sh | POSIX more portable but less readable; Bash available everywhere needed |
| Manual symlinks | GNU Stow | Stow adds dependency; manual is simpler for Phase 1 scope |
| Custom backup | rsync | rsync overkill; cp/mv sufficient for single files |

**No installation needed:** All tools are built into macOS and standard Linux distributions.

## Architecture Patterns

### Recommended Script Structure

```
install.sh (single file for Phase 1)
├── Shebang & strict mode
├── Constants & configuration
├── Color/output functions
├── Utility functions (OS detection, backup, symlink)
├── Help text function
├── Argument parsing
├── Main logic
└── Exit with status
```

### Pattern 1: Strict Mode Header

**What:** Enable bash strict mode at script start
**When to use:** Always, at the top of every bash script
**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# -e: Exit on error
# -u: Error on undefined variables
# -o pipefail: Pipeline fails if any command fails
```
**Source:** [Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/)

### Pattern 2: Dry-Run Mode

**What:** Preview changes without executing them
**When to use:** When user passes `--dry-run` or `-n` flag
**Example:**
```bash
DRY_RUN=false

execute() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

# Usage
execute ln -sfn "$source" "$target"
execute mkdir -p "$backup_dir"
```
**Source:** [KodeKloud - no-op Commands](https://notes.kodekloud.com/docs/Advanced-Bash-Scripting/Good-Practices-applied/no-op-Commands)

### Pattern 3: TTY-Aware Color Output

**What:** Use colors when outputting to terminal, plain text when piped
**When to use:** All user-facing output
**Example:**
```bash
# Detect color support
if [[ -t 1 ]] && [[ -n "${TERM:-}" ]] && [[ "${TERM}" != "dumb" ]]; then
    COLOR_RESET='\033[0m'
    COLOR_GREEN='\033[0;32m'
    COLOR_RED='\033[0;31m'
    COLOR_YELLOW='\033[0;33m'
    SYMBOL_OK='✓'
    SYMBOL_FAIL='✗'
    SYMBOL_ARROW='→'
else
    COLOR_RESET=''
    COLOR_GREEN=''
    COLOR_RED=''
    COLOR_YELLOW=''
    SYMBOL_OK='[OK]'
    SYMBOL_FAIL='[FAIL]'
    SYMBOL_ARROW='->'
fi

success() { printf "${COLOR_GREEN}${SYMBOL_OK}${COLOR_RESET} %s\n" "$1"; }
error() { printf "${COLOR_RED}${SYMBOL_FAIL}${COLOR_RESET} %s\n" "$1" >&2; }
info() { printf "${COLOR_YELLOW}${SYMBOL_ARROW}${COLOR_RESET} %s\n" "$1"; }
```
**Source:** [Baeldung - Terminal Colors](https://www.baeldung.com/linux/terminal-colors)

### Pattern 4: Idempotent Symlink Creation

**What:** Create symlink safely, backing up existing files
**When to use:** For every symlink operation
**Example:**
```bash
safe_link() {
    local source="$1"
    local target="$2"

    # Already correct symlink - skip
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        info "Already linked: $target"
        return 0
    fi

    # Symlink pointing elsewhere - prompt user
    if [[ -L "$target" ]]; then
        local current_target
        current_target=$(readlink "$target")
        echo "Warning: $target currently points to $current_target"
        read -p "Replace with link to $source? [y/N] " -r
        if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
            info "Skipped: $target"
            return 0
        fi
    fi

    # Existing file (not symlink) - backup first
    if [[ -e "$target" ]]; then
        backup_file "$target"
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    # Create symlink
    execute ln -sfn "$source" "$target"
    success "Linked: $target -> $source"
}
```
**Source:** [How to write idempotent Bash scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/)

### Pattern 5: Timestamped Backup Directory

**What:** Backup existing files before overwriting
**When to use:** When replacing user files with symlinks
**Example:**
```bash
BACKUP_DIR="$HOME/.dotfiles-backup"
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_SESSION_DIR=""

backup_file() {
    local file="$1"

    # Initialize session backup dir on first backup
    if [[ -z "$BACKUP_SESSION_DIR" ]]; then
        BACKUP_SESSION_DIR="$BACKUP_DIR/$BACKUP_TIMESTAMP"
        execute mkdir -p "$BACKUP_SESSION_DIR"
    fi

    # Preserve directory structure in backup
    local relative_path="${file#$HOME/}"
    local backup_path="$BACKUP_SESSION_DIR/$relative_path"

    execute mkdir -p "$(dirname "$backup_path")"
    execute mv "$file" "$backup_path"
    info "Backed up: $file -> $backup_path"
}
```
**Source:** [Dotfiles Pitfalls Research](../.planning/research/PITFALLS.md)

### Pattern 6: OS Detection

**What:** Detect macOS vs Linux for platform-specific behavior
**When to use:** When paths or commands differ between platforms
**Example:**
```bash
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

OS=$(detect_os)

# Use in conditionals
if [[ "$OS" == "macos" ]]; then
    # macOS-specific logic
fi
```
**Source:** [Dotfiles Architecture Research](../.planning/research/ARCHITECTURE.md)

### Pattern 7: Argument Parsing with Long Options

**What:** Parse both short (-h, -n) and long (--help, --dry-run) options
**When to use:** For user-friendly CLI interface
**Example:**
```bash
show_help() {
    cat << 'EOF'
Usage: install.sh [OPTIONS]

Set up dotfiles by creating symlinks from this repository to your home directory.
Existing files are backed up to ~/.dotfiles-backup/ before being replaced.

Options:
    -h, --help      Show this help message
    -n, --dry-run   Preview changes without making them
    -v, --verbose   Show detailed output

Examples:
    ./install.sh              # Run installation
    ./install.sh --dry-run    # Preview what would happen
    ./install.sh -n           # Same as --dry-run
EOF
}

# Parse arguments (handle long options manually, then getopts for short)
for arg in "$@"; do
    case "$arg" in
        --help)    show_help; exit 0 ;;
        --dry-run) DRY_RUN=true ;;
        --verbose) VERBOSE=true ;;
        -*) ;;  # Let getopts handle short options
        *) ;;
    esac
done

# Reset for getopts
OPTIND=1
while getopts ":hnv" opt; do
    case "$opt" in
        h) show_help; exit 0 ;;
        n) DRY_RUN=true ;;
        v) VERBOSE=true ;;
        \?) error "Invalid option: -$OPTARG"; exit 1 ;;
    esac
done
```
**Source:** [Baeldung - Parse Command Line Arguments](https://www.baeldung.com/linux/bash-parse-command-line-arguments)

### Anti-Patterns to Avoid

- **Using `ln -sf` without checking** - Can silently destroy files; always backup first
- **Hardcoded paths like `/Users/fespino/`** - Use `$HOME` for portability
- **Running as root** - Symlinks should be owned by user; refuse if `$EUID -eq 0`
- **Missing error handling** - Always use `set -euo pipefail`
- **Colors without TTY check** - Breaks piped output; always check `[ -t 1 ]`

## Don't Hand-Roll

Problems that look simple but have edge cases:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Symlink target checking | String comparison | `readlink` command | Handles relative paths, normalizes |
| Timestamped names | Custom format | `date +%Y%m%d_%H%M%S` | Consistent, sortable format |
| Color codes | Manual escape sequences | `tput` for detection, ANSI for output | Portable terminal capability detection |
| Argument parsing | Manual string parsing | `getopts` + long option preprocessing | Handles edge cases, standard pattern |

**Key insight:** Bash built-ins and coreutils handle edge cases already. Focus on orchestration, not reimplementing utilities.

## Common Pitfalls

### Pitfall 1: Non-Idempotent Symlinks

**What goes wrong:** Running install.sh twice creates symlink chains or errors
**Why it happens:** Using `ln -sf` without checking if symlink already exists and points to correct target
**How to avoid:** Check with `readlink` before creating; use `-n` flag to prevent following existing symlinks
**Warning signs:** `ls -la` shows symlink pointing to symlink, or "file exists" errors on second run

### Pitfall 2: Destructive Overwrites Without Backup

**What goes wrong:** User's existing `.zshrc` with custom settings is destroyed
**Why it happens:** Using `ln -sf` which removes target first
**How to avoid:** Always check if target exists and is a regular file; backup before replacing
**Warning signs:** No `.dotfiles-backup/` directory, user reports losing settings

### Pitfall 3: Hardcoded User Paths

**What goes wrong:** Script fails on different machine with different username
**Why it happens:** Paths like `/Users/fespino/.dotfiles` instead of `$HOME/.dotfiles`
**How to avoid:** Always use `$HOME` or `~`; calculate DOTFILES_DIR from script location
**Warning signs:** Grep for `/Users/` or `/home/` in script

### Pitfall 4: Colors Break Piped Output

**What goes wrong:** Output contains garbage characters when piped to file or another command
**Why it happens:** ANSI escape codes output without checking if stdout is a terminal
**How to avoid:** Check `[ -t 1 ]` before using colors; provide `--no-color` option
**Warning signs:** `./install.sh | tee log.txt` has escape sequences in log

### Pitfall 5: Prompts Hang in Non-Interactive Environments

**What goes wrong:** Script hangs waiting for input in CI or when run non-interactively
**Why it happens:** `read` without timeout, prompts without checking TTY
**How to avoid:** Check `[ -t 0 ]` before prompting; provide timeout with `-t`; accept `--yes` flag for automation
**Warning signs:** Script works locally but hangs in CI

### Pitfall 6: BSD vs GNU Tool Differences

**What goes wrong:** Script works on Linux but fails on macOS (or vice versa)
**Why it happens:** macOS uses BSD versions of coreutils; flags differ
**How to avoid:** Use portable constructs; `readlink` without `-f` works on both; test on both platforms
**Warning signs:** `readlink -f` fails on macOS; `sed -i` fails on macOS (needs `sed -i ''`)

## Code Examples

### Complete OS Detection Function

```bash
# Source: Community standard pattern
detect_os() {
    local os
    case "$(uname -s)" in
        Darwin) os="macos" ;;
        Linux)  os="linux" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        *)      os="unknown" ;;
    esac
    echo "$os"
}

# Homebrew path differs on Apple Silicon vs Intel
detect_brew_prefix() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}
```

### Complete Backup Function with Prompt

```bash
# Source: User decision from CONTEXT.md
BACKUP_DIR="${HOME}/.dotfiles-backup"

backup_with_prompt() {
    local file="$1"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${timestamp}/$(basename "$file")"

    # Check if backup already exists (different session)
    if [[ -d "${BACKUP_DIR}" ]] && [[ -n "$(ls -A "${BACKUP_DIR}" 2>/dev/null)" ]]; then
        info "Existing backups found in ${BACKUP_DIR}"
    fi

    mkdir -p "$(dirname "$backup_path")"
    mv "$file" "$backup_path"
    success "Backed up: $file -> $backup_path"
}
```

### Complete Symlink Mapping

```bash
# Source: User decision - hardcoded mappings in script
declare -A SYMLINKS=(
    # Shell
    ["${DOTFILES_DIR}/.zshrc"]="${HOME}/.zshrc"

    # Kitty (XDG compliant)
    ["${DOTFILES_DIR}/kitty"]="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"

    # Tmux
    ["${DOTFILES_DIR}/tmux/tmux.conf"]="${HOME}/.tmux.conf"

    # Vim
    ["${DOTFILES_DIR}/vim"]="${HOME}/.vim"

    # Scripts
    ["${DOTFILES_DIR}/bin/cht.sh"]="${HOME}/.local/bin/cht.sh"
)

install_symlinks() {
    for source in "${!SYMLINKS[@]}"; do
        local target="${SYMLINKS[$source]}"
        safe_link "$source" "$target"
    done
}
```

### User Prompt for Symlink Conflicts

```bash
# Source: User decision from CONTEXT.md - prompt for wrong symlinks
prompt_replace_symlink() {
    local target="$1"
    local new_source="$2"
    local current_source
    current_source=$(readlink "$target")

    # Don't prompt if not a TTY (non-interactive)
    if [[ ! -t 0 ]]; then
        error "Cannot prompt in non-interactive mode. Use --force to replace symlinks."
        return 1
    fi

    printf "${COLOR_YELLOW}Warning:${COLOR_RESET} %s currently points to %s\n" "$target" "$current_source"
    printf "Replace with link to %s? [y/N] " "$new_source"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0  # User approved
    else
        return 1  # User declined
    fi
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| POSIX sh for portability | Bash for readability | N/A - both valid | Bash 3.2+ available on all target platforms |
| GNU Stow dependency | Manual symlinks in script | N/A - scope decision | Fewer dependencies, more control |
| Silent overwrites | Backup-first with prompt | Always best practice | User trust, data safety |
| Global colors | TTY-aware colors | Best practice since terminals | Works in pipelines |

**Deprecated/outdated:**
- Using `[ ]` instead of `[[ ]]` in Bash (the latter has better string handling)
- Using `echo -e` for colors (use `printf` for portability)
- Sourcing from `/etc/profile.d/` for dotfiles (use explicit sourcing)

## Open Questions

Things that couldn't be fully resolved:

1. **Symlink vs Copy for Non-Symlink-Aware Apps**
   - What we know: Most apps handle symlinks fine
   - What's unclear: Are there any configs in this repo that need copying instead?
   - Recommendation: Default to symlinks; add copy option if specific issues found

2. **Restore Command Scope**
   - What we know: User deferred this to Claude's discretion
   - What's unclear: How complex should restore be in Phase 1?
   - Recommendation: Document manual restore from backup dir; defer restore script to later phase

3. **Verbose Mode Scope**
   - What we know: User wants `--verbose` for debugging
   - What's unclear: What additional output in verbose mode?
   - Recommendation: In verbose mode, show every file check and decision; normal mode shows only actions taken

## Sources

### Primary (HIGH confidence)
- [How to write idempotent Bash scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/) - Symlink, mkdir, grep patterns
- [Baeldung - Terminal Colors](https://www.baeldung.com/linux/terminal-colors) - TTY detection, tput usage
- [Baeldung - Parse Command Line Arguments](https://www.baeldung.com/linux/bash-parse-command-line-arguments) - getopts patterns
- [FLOZz Bash Colors](https://misc.flogisoft.com/bash/tip_colors_and_formatting) - ANSI escape codes reference

### Secondary (MEDIUM confidence)
- [KodeKloud - no-op Commands](https://notes.kodekloud.com/docs/Advanced-Bash-Scripting/Good-Practices-applied/no-op-Commands) - Dry-run patterns
- [Medium - Tips for Better Bash Scripts](https://medium.com/@rafal.kedziorski/tips-for-better-bash-scripts-36a9ce88dfa8) - General best practices
- [Linuxize - Bash read Command](https://linuxize.com/post/bash-read/) - User input patterns

### Existing Project Research
- `.planning/research/ARCHITECTURE.md` - Directory structure, component patterns
- `.planning/research/PITFALLS.md` - Common mistakes, safety patterns
- `.planning/research/FEATURES.md` - Feature landscape, MVP scope

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Bash/coreutils are universal, patterns well-documented
- Architecture: HIGH - Community consensus on script structure
- Pitfalls: HIGH - Drawn from existing project research and multiple sources
- Code examples: HIGH - Verified patterns from authoritative sources

**Research date:** 2026-02-01
**Valid until:** 2026-03-01 (stable domain, low churn)
