#!/usr/bin/env bash
set -euo pipefail

# install.sh - Dotfiles bootstrap script
# Sets up symlinks from this repository to your home directory
# Safely backs up existing files before replacing them
#
# Compatible with Bash 3.2+ (macOS default)

#===============================================================================
# Constants
#===============================================================================

# Calculate DOTFILES_DIR from script location (works even if called from elsewhere)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

BACKUP_DIR="${HOME}/.dotfiles-backup"
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_SESSION_DIR=""

#===============================================================================
# Options (set via command line)
#===============================================================================

DRY_RUN=false
VERBOSE=false

#===============================================================================
# Color/Output Functions (TTY-aware)
#===============================================================================

# Detect color support - use colors when outputting to terminal, plain when piped
if [[ -t 1 ]] && [[ -n "${TERM:-}" ]] && [[ "${TERM}" != "dumb" ]]; then
    COLOR_RESET='\033[0m'
    COLOR_GREEN='\033[0;32m'
    COLOR_RED='\033[0;31m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BLUE='\033[0;34m'
    SYMBOL_OK='✓'
    SYMBOL_FAIL='✗'
    SYMBOL_ARROW='→'
else
    COLOR_RESET=''
    COLOR_GREEN=''
    COLOR_RED=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    SYMBOL_OK='[OK]'
    SYMBOL_FAIL='[FAIL]'
    SYMBOL_ARROW='-->'
fi

success() {
    printf "%b%s%b %s\n" "$COLOR_GREEN" "$SYMBOL_OK" "$COLOR_RESET" "$1"
}

error() {
    printf "%b%s%b %s\n" "$COLOR_RED" "$SYMBOL_FAIL" "$COLOR_RESET" "$1" >&2
}

info() {
    printf "%b%s%b %s\n" "$COLOR_YELLOW" "$SYMBOL_ARROW" "$COLOR_RESET" "$1"
}

debug() {
    if [[ "$VERBOSE" == true ]]; then
        printf "%b  %s%b\n" "$COLOR_BLUE" "$1" "$COLOR_RESET"
    fi
}

#===============================================================================
# Utility Functions
#===============================================================================

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

# Wrapper for commands - respects dry-run mode
execute() {
    if [[ "$DRY_RUN" == true ]]; then
        info "[dry-run] $*"
    else
        "$@"
    fi
}

# Backup a file before replacing it
backup_file() {
    local file="$1"

    # Initialize session backup dir on first backup
    if [[ -z "$BACKUP_SESSION_DIR" ]]; then
        BACKUP_SESSION_DIR="$BACKUP_DIR/$BACKUP_TIMESTAMP"
        execute mkdir -p "$BACKUP_SESSION_DIR"
    fi

    # Preserve directory structure in backup (relative to HOME)
    local relative_path="${file#$HOME/}"
    local backup_path="$BACKUP_SESSION_DIR/$relative_path"

    # Create parent directory for backup
    execute mkdir -p "$(dirname "$backup_path")"
    execute mv "$file" "$backup_path"

    if [[ "$DRY_RUN" == false ]]; then
        info "Backed up: $file $SYMBOL_ARROW $backup_path"
    fi
}

# Create symlink safely with backup and conflict handling
safe_link() {
    local source="$1"
    local target="$2"

    debug "Checking: $target"

    # Check if source exists
    if [[ ! -e "$source" ]]; then
        error "Source does not exist: $source"
        return 1
    fi

    # Already correct symlink - skip
    if [[ -L "$target" ]]; then
        local current_target
        current_target=$(readlink "$target")
        if [[ "$current_target" == "$source" ]]; then
            info "Already linked: $target"
            return 0
        fi

        # Symlink pointing elsewhere - prompt user
        if [[ -t 0 ]]; then
            # Interactive mode - prompt
            printf "%bWarning:%b %s currently points to %s\n" "$COLOR_YELLOW" "$COLOR_RESET" "$target" "$current_target"
            printf "Replace with link to %s? [y/N] " "$source"
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                info "Skipped: $target"
                return 0
            fi
            # User approved - remove old symlink and create new one
            execute rm "$target"
        else
            # Non-interactive mode - skip with warning
            error "Skipped (non-interactive): $target points elsewhere ($current_target)"
            return 0
        fi
    fi

    # Existing file (not symlink) - backup first
    if [[ -e "$target" ]]; then
        debug "Found existing file: $target"
        backup_file "$target"
    fi

    # Create parent directory if needed
    local target_dir
    target_dir=$(dirname "$target")
    if [[ ! -d "$target_dir" ]]; then
        debug "Creating directory: $target_dir"
        execute mkdir -p "$target_dir"
    fi

    # Create symlink
    execute ln -sfn "$source" "$target"

    if [[ "$DRY_RUN" == false ]]; then
        success "Linked: $target $SYMBOL_ARROW $source"
    fi
}

#===============================================================================
# Help Text
#===============================================================================

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
    ./install.sh -v           # Verbose output
EOF
}

#===============================================================================
# Argument Parsing
#===============================================================================

# Parse all arguments (both long and short options)
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            error "Invalid option: $1"
            show_help
            exit 1
            ;;
        *)
            # Ignore positional arguments
            shift
            ;;
    esac
done

#===============================================================================
# Symlink Mappings
#===============================================================================

# Define symlinks using parallel arrays (Bash 3.2 compatible)
# LINK_SOURCES[i] -> LINK_TARGETS[i]

LINK_SOURCES=(
    # Shell configuration
    "${DOTFILES_DIR}/.zshrc"

    # Kitty terminal (XDG compliant)
    "${DOTFILES_DIR}/kitty"

    # Tmux configuration
    "${DOTFILES_DIR}/tmux/tmux.conf"

    # Vim configuration
    "${DOTFILES_DIR}/vim"

    # Scripts
    "${DOTFILES_DIR}/bin/cht.sh"
)

LINK_TARGETS=(
    # Shell configuration
    "${HOME}/.zshrc"

    # Kitty terminal (XDG compliant)
    "${XDG_CONFIG_HOME:-$HOME/.config}/kitty"

    # Tmux configuration
    "${HOME}/.tmux.conf"

    # Vim configuration
    "${HOME}/.vim"

    # Scripts
    "${HOME}/.local/bin/cht.sh"
)

#===============================================================================
# Main
#===============================================================================

main() {
    local os
    os=$(detect_os)

    # Header
    echo ""
    if [[ "$DRY_RUN" == true ]]; then
        info "DRY RUN - No changes will be made"
        echo ""
    fi
    printf "Setting up dotfiles on %b%s%b...\n" "$COLOR_GREEN" "$os" "$COLOR_RESET"
    echo ""

    # Track results for summary
    local linked=0
    local skipped=0
    local backed_up=0
    local count=${#LINK_SOURCES[@]}

    # Process each symlink
    for ((i=0; i<count; i++)); do
        local source="${LINK_SOURCES[$i]}"
        local target="${LINK_TARGETS[$i]}"

        # Track if we'll backup
        if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
            backed_up=$((backed_up + 1))
        fi

        # Create symlink
        if safe_link "$source" "$target"; then
            # Check if it was actually linked vs skipped
            if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
                linked=$((linked + 1))
            else
                skipped=$((skipped + 1))
            fi
        fi
    done

    # Summary
    echo ""
    echo "─────────────────────────────────────────"
    if [[ "$DRY_RUN" == true ]]; then
        printf "%bDry run complete%b\n" "$COLOR_YELLOW" "$COLOR_RESET"
        printf "Would link: %d files\n" "$linked"
        if [[ $backed_up -gt 0 ]]; then
            printf "Would backup: %d files to %s/\n" "$backed_up" "$BACKUP_DIR"
        fi
    else
        printf "%bInstallation complete%b\n" "$COLOR_GREEN" "$COLOR_RESET"
        printf "Linked: %d files\n" "$linked"
        if [[ -n "$BACKUP_SESSION_DIR" ]] && [[ -d "$BACKUP_SESSION_DIR" ]]; then
            printf "Backups: %s/\n" "$BACKUP_SESSION_DIR"
        fi
    fi
    if [[ $skipped -gt 0 ]]; then
        printf "Skipped: %d files\n" "$skipped"
    fi
    echo ""
}

main "$@"
