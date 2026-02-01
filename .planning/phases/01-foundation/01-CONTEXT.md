# Phase 1: Foundation - Context

**Gathered:** 2026-02-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Core install.sh script that detects OS (macOS vs Linux), backs up existing config files, and creates symlinks safely. Includes dry-run mode for previewing changes. Must be idempotent — running twice produces same result.

Package installation, shell configuration, and application configs are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Backup Strategy
- Backups stored in `~/.dotfiles-backup/`
- Prompt user if backup already exists for a file (don't silently overwrite)
- Claude's discretion: folder naming (timestamped vs single), what to backup (symlinks or not), dry-run backup preview, summary messaging

### Output & Feedback
- Normal verbosity by default (show key steps, not every operation)
- Colors with auto-detect (colors when TTY, plain when piped)
- Status indicators: symbols (✓ ✗ →) not text
- Claude's discretion: --verbose flag for debugging

### Error Handling
- If existing file (not symlink): backup & replace automatically
- If already correct symlink: skip with note ("already linked")
- If symlink pointing elsewhere: prompt user before replacing
- Claude's discretion: fail fast vs continue on individual failures

### Script Structure
- Support `--help` with full help text (usage, options, examples)
- Claude's discretion: single file vs modular, config file vs hardcoded mappings, bash vs POSIX sh

### Claude's Discretion
- Backup folder naming scheme
- Whether to backup existing symlinks
- Dry-run backup preview behavior
- Backup summary verbosity
- --verbose flag implementation
- Failure mode (fail fast vs continue)
- File structure (single vs modular)
- Symlink mapping location (in-script vs config file)
- Shell choice (bash vs POSIX sh)
- Restore command inclusion

</decisions>

<specifics>
## Specific Ideas

- User prefers prompts over silent overwrites for conflict scenarios
- Output should feel informative but not noisy — "key steps" level
- Visual symbols (✓ ✗ →) preferred over ASCII [OK] style

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-02-01*
