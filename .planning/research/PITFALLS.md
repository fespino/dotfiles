# Pitfalls Research: Cross-Platform Dotfiles

**Domain:** Cross-platform dotfiles with automated bootstrap
**Researched:** 2026-02-01
**Confidence:** HIGH (verified against multiple community sources and official documentation)

---

## Critical Mistakes

These cause rewrites, data loss, or fundamentally broken setups.

### 1. Committing Secrets to Git

**What goes wrong:** API keys, SSH keys, tokens, or passwords get committed to the dotfiles repository. Once pushed, secrets are exposed in git history forever and can be scraped by automated bots within minutes.

**Why it happens:**
- `.zshrc` contains `export API_KEY="..."` for convenience
- SSH config references key files that get accidentally added
- `.gitconfig` contains credentials or signing keys
- Copy-pasting configs without sanitizing

**Warning signs:**
- Files containing `export *_KEY=`, `export *_TOKEN=`, `export *_SECRET=`
- Any file in `.ssh/` directory staged for commit
- `.netrc`, `.npmrc`, or credential helper configs staged

**Prevention:**
1. Add comprehensive `.gitignore` from day one:
   ```
   .env*
   *.pem
   *.key
   *credentials*
   .ssh/
   .netrc
   .npmrc
   .aws/credentials
   ```
2. Use git pre-commit hooks with secret scanning (e.g., `detect-secrets`, `gitleaks`)
3. Store secrets in password manager (1Password, Bitwarden) with template references
4. Use `.envrc` files with direnv that are git-ignored

**Address in phase:** Phase 1 (Core Bootstrap) - set up `.gitignore` before any other work

**Sources:**
- [Why Your Public Dotfiles are a Security Minefield](https://medium.com/@instatunnel/why-your-public-dotfiles-are-a-security-minefield-fc9bdff62403)
- [Managing dotfiles and secret with chezmoi](https://blog.arkey.fr/2020/04/01/manage_dotfiles_with_chezmoi/)

---

### 2. Non-Idempotent Install Script

**What goes wrong:** Running `install.sh` twice breaks things. Symlinks get doubled, configs get appended multiple times, packages reinstall and overwrite customizations.

**Why it happens:**
- Using `ln -s` without checking if symlink exists
- Appending to files without checking if content already present
- No guards around package installation
- Assuming fresh system on every run

**Warning signs:**
- `install.sh` has no `if` statements or existence checks
- Files contain duplicated configuration blocks
- Symlinks point to symlinks (chains)
- Script fails on second run with "file exists" errors

**Prevention:**
1. Guard all symlink creation:
   ```bash
   [ -L ~/.zshrc ] || ln -s "$DOTFILES/.zshrc" ~/.zshrc
   ```
2. Use `ln -sf` carefully (overwrites) or prefer tools like GNU Stow
3. For file appends, check if content exists first:
   ```bash
   grep -q "DOTFILES_MARKER" ~/.bashrc || echo "# DOTFILES_MARKER" >> ~/.bashrc
   ```
4. Test by running `install.sh` twice on a fresh VM

**Address in phase:** Phase 1 (Core Bootstrap) - fundamental to install script design

**Sources:**
- [Dotfiles with idempotent bootstrap script](https://github.com/Xe0n0/dotfiles)
- [Managing Dotfiles With Chezmoi](https://budimanjojo.com/2021/12/13/managing-dotfiles-with-chezmoi/)

---

### 3. Destructive Symlink Overwrites

**What goes wrong:** User has existing configs (`.zshrc`, `.vimrc`) that get silently overwritten. Hours of personal customization lost.

**Why it happens:**
- Using `ln -sf` blindly (force overwrites)
- No backup step before symlinking
- Assuming dotfiles repo is authoritative

**Warning signs:**
- Install script uses `ln -sf` without backup
- No `.backup/` directory or dated backup files
- User's existing files have no recovery path

**Prevention:**
1. Always backup before overwriting:
   ```bash
   backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
   mkdir -p "$backup_dir"
   [ -f ~/.zshrc ] && mv ~/.zshrc "$backup_dir/"
   ```
2. Use GNU Stow which refuses to overwrite non-symlinks
3. Provide `--force` flag for intentional overwrites, safe default otherwise
4. Document recovery: "Your old configs are in ~/.dotfiles-backup/"

**Address in phase:** Phase 1 (Core Bootstrap) - critical safety feature

**Sources:**
- [Using GNU Stow to Manage Symbolic Links](https://systemcrafters.net/managing-your-dotfiles/using-gnu-stow/)
- [Managing dotfiles with GNU Stow](https://venthur.de/2021-12-19-managing-dotfiles-with-stow.html)

---

### 4. Hardcoded Absolute Paths

**What goes wrong:** Configs break when username differs, home directory location differs, or switching between Mac and Linux.

**Why it happens:**
- `/Users/fespino/.dotfiles` hardcoded instead of `$HOME/.dotfiles`
- macOS paths assumed (`/opt/homebrew`) without Linux alternatives
- Different username on different machines

**Warning signs (visible in current .zshrc):**
- `/Users/fespino/` appears in configs
- `/home/fespino/` in same file (inconsistent)
- No `$HOME` or `~` usage
- Homebrew paths without architecture detection

**Prevention:**
1. Always use `$HOME` or `~`, never hardcoded usernames
2. Detect Homebrew path dynamically:
   ```bash
   if [ -d "/opt/homebrew" ]; then
     BREW_PREFIX="/opt/homebrew"
   elif [ -d "/usr/local/Homebrew" ]; then
     BREW_PREFIX="/usr/local"
   fi
   ```
3. Use `$(dirname "$0")` or `$DOTFILES` variable for repo location
4. grep for hardcoded paths in CI: `grep -r "/Users/\|/home/" --include="*.sh"`

**Address in phase:** Phase 1 (Core Bootstrap) and Phase 2 (Shell Config) - fix existing hardcoded paths

**Sources:**
- [Cross-platform dotfile Management with dotbot](https://brianschiller.com/blog/2024/08/05/cross-platform-dotbot/)
- [Sharing .dotfiles cross-platform](https://dev.to/amcsi/sharing-dotfiles-cross-platform-with-a-shell-script-o2j)

---

### 5. Interactive Prompts in Automated Scripts

**What goes wrong:** Install script hangs waiting for user input. In CI/CD or unattended installs, this means infinite wait or timeout failure.

**Why it happens:**
- Package managers prompt for confirmation
- Installers ask questions (Homebrew, oh-my-zsh)
- `read` commands without timeout
- Commands expecting TTY input

**Warning signs:**
- Script works locally but hangs in CI
- `apt-get install` without `-y` flag
- Homebrew install without `NONINTERACTIVE=1`
- `read -p "Continue?"` without fallback

**Prevention:**
1. All package managers use non-interactive flags:
   ```bash
   apt-get install -y package
   NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. oh-my-zsh with unattended install:
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
   ```
3. Default answers for all prompts
4. Test in Docker container without TTY

**Address in phase:** Phase 1 (Core Bootstrap) - ensure all package installation is non-interactive

**Sources:**
- [Homebrew Non-Interactive Installation](https://docs.brew.sh/Installation)
- [Dotfiles automating macOS system configuration](https://kalis.me/dotfiles-automating-macos-system-configuration/)

---

## Moderate Pitfalls

These cause delays, frustration, or tech debt but are recoverable.

### 6. Slow Shell Startup (NVM/Pyenv Eager Loading)

**What goes wrong:** Shell takes 1-3 seconds to start. Every new terminal tab is painful. Users disable dotfiles entirely.

**Why it happens (visible in current .zshrc):**
- NVM loaded eagerly on every shell: `[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"`
- Pyenv init runs on every prompt: `eval "$(pyenv init --path)"`
- Multiple `compinit` calls
- Too many oh-my-zsh plugins

**Warning signs:**
- `time zsh -i -c exit` shows >500ms
- Noticeable delay opening new terminal
- Users start shells with `--no-rcs` to avoid slowness

**Prevention:**
1. Lazy load NVM (oh-my-zsh has built-in support):
   ```bash
   zstyle ':omz:plugins:nvm' lazy yes
   ```
2. Cache pyenv init:
   ```bash
   # Install zsh-evalcache plugin
   _evalcache pyenv init -
   ```
3. Consider replacing NVM with fnm (Rust, faster)
4. Consider replacing pyenv/nvm/rbenv with mise (single tool, lazy by default)
5. Only call `compinit` once per day:
   ```bash
   autoload -Uz compinit
   if [ $(date +'%j') != $(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null) ]; then
     compinit
   else
     compinit -C
   fi
   ```

**Address in phase:** Phase 2 (Shell Config) - optimize .zshrc load time

**Sources:**
- [Speeding Up Zsh](https://www.joshyin.cc/blog/speeding-up-zsh)
- [Fix slow ZSH startup due to NVM](https://dev.to/thraizz/fix-slow-zsh-startup-due-to-nvm-408k)
- [Achieving 30ms Zsh Startup](https://dev.to/tmlr/achieving-30ms-zsh-startup-40n1)

---

### 7. Oh-My-Zsh Symlink Race Condition

**What goes wrong:** oh-my-zsh installer renames your symlinked `.zshrc` to `.zshrc-pre-oh-my-zsh`, breaking your setup.

**Why it happens:**
- OMZ installer backs up existing `.zshrc`
- Your symlink gets moved, original target unchanged
- Shell now loads OMZ default config, not your dotfiles

**Warning signs:**
- `.zshrc-pre-oh-my-zsh` appears after install
- Symlink broken: `ls -la ~/.zshrc` shows regular file
- Custom aliases and config gone after OMZ install

**Prevention:**
1. Install OMZ with `--keep-zshrc` flag:
   ```bash
   sh -c "$(curl -fsSL ...)" "" --unattended --keep-zshrc
   ```
2. Order operations: install OMZ first, then symlink `.zshrc`
3. Or: install OMZ to custom location, source in your `.zshrc`

**Address in phase:** Phase 2 (Shell Config) - order of operations in install script

**Sources:**
- [OMZ Installation](https://github.com/ohmyzsh/ohmyzsh)
- [Z-shell/Oh-My-ZSH](https://falkor-dotfiles.readthedocs.io/en/latest/oh-my-zsh/README/)

---

### 8. TPM Not Cloned Before tmux Runs

**What goes wrong:** tmux starts, tries to load TPM plugins, fails silently. Status bar broken, keybindings missing.

**Why it happens:**
- `tmux.conf` references `~/.tmux/plugins/tpm/tpm`
- TPM not cloned during install
- `prefix + I` doesn't work because TPM itself is missing

**Warning signs:**
- tmux starts but no plugins work
- `~/.tmux/plugins/` directory empty or missing
- "returned 127" error in tmux

**Prevention:**
1. Clone TPM in install script:
   ```bash
   [ -d ~/.tmux/plugins/tpm ] || \
     git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```
2. Auto-install plugins after clone:
   ```bash
   tmux new-session -d "sleep 1"
   sleep 0.1
   ~/.tmux/plugins/tpm/bin/install_plugins
   ```
3. Document: "After first tmux start, press `prefix + I` to install plugins"

**Address in phase:** Phase 3 (Tmux Config) - TPM bootstrap in install script

**Sources:**
- [TPM Troubleshooting](https://github.com/tmux-plugins/tpm/blob/master/docs/tpm_not_working.md)
- [Bootstrap your Dotfiles with dotbot](https://www.elliotdenolf.com/blog/bootstrap-your-dotfiles-with-dotbot)

---

### 9. Neovim Plugin Manager Bootstrap Missing

**What goes wrong:** Neovim opens with errors, no plugins loaded, LSP not working.

**Why it happens:**
- lazy.nvim expects bootstrap code in `init.lua`
- Clone step missing or path wrong
- Plugin lock file from different machine causes conflicts

**Warning signs:**
- `:checkhealth lazy` fails
- Neovim shows Lua errors on startup
- `~/.local/share/nvim/lazy/` empty

**Prevention:**
1. Ensure lazy.nvim bootstrap code is present:
   ```lua
   local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
   if not vim.loop.fs_stat(lazypath) then
     vim.fn.system({"git", "clone", "--filter=blob:none",
       "https://github.com/folke/lazy.nvim.git", lazypath})
   end
   vim.opt.rtp:prepend(lazypath)
   ```
2. Consider NOT committing `lazy-lock.json` (or document its purpose)
3. Run `:Lazy sync` on first start

**Address in phase:** Phase 4 (Neovim Config) - verify bootstrap code exists

**Sources:**
- [lazy.nvim Installation](https://lazy.folke.io/installation)
- [Ultimate Neovim Setup Guide](https://dev.to/slydragonn/ultimate-neovim-setup-guide-lazynvim-plugin-manager-23b7)

---

### 10. Sudo Password Timeout During Long Installs

**What goes wrong:** Install script starts, asks for sudo, user enters password, then 20 minutes later apt-get fails because sudo timed out.

**Why it happens:**
- Long-running operations between sudo commands
- Compiling from source takes time
- Downloading large packages on slow connection

**Warning signs:**
- Script fails midway with "sudo: a password is required"
- Inconsistent failures depending on network speed

**Prevention:**
1. Use sudo keep-alive pattern at script start:
   ```bash
   # Ask for password upfront
   sudo -v

   # Keep sudo alive in background
   while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
   ```
2. Group all sudo operations together at start
3. Consider which operations actually need sudo (symlinks don't)

**Address in phase:** Phase 1 (Core Bootstrap) - sudo handling at script top

**Sources:**
- [Dotfiles automating macOS](https://kalis.me/dotfiles-automating-macos-system-configuration/)
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)

---

### 11. Git Config User Identity Not Set

**What goes wrong:** First commit fails with "Please tell me who you are." Git refuses to work until identity set.

**Why it happens:**
- `.gitconfig` committed with personal email
- Fresh machine has no git identity
- User expected to set this manually

**Warning signs:**
- Git commands fail immediately after bootstrap
- `.gitconfig` in repo has someone else's email

**Prevention:**
1. Prompt for git identity during install (if not set):
   ```bash
   if [ -z "$(git config --global user.email)" ]; then
     read -p "Git email: " git_email
     git config --global user.email "$git_email"
   fi
   ```
2. Or use git config templates and `includeIf` for work/personal
3. Document clearly: "After install, run `git config --global user.email you@example.com`"

**Address in phase:** Phase 1 (Core Bootstrap) - interactive setup or clear docs

---

### 12. BSD vs GNU Tool Differences

**What goes wrong:** Shell scripts work on Linux but fail on macOS (or vice versa). `sed -i`, `readlink`, `date` all behave differently.

**Why it happens:**
- macOS uses BSD versions of core utils
- Linux uses GNU versions
- Flags and behavior differ subtly

**Warning signs:**
- `sed -i 's/foo/bar/' file` fails on macOS (needs `sed -i '' 's/foo/bar/' file`)
- `readlink -f` doesn't work on macOS
- Date formatting differs

**Prevention:**
1. Install GNU tools on macOS via Homebrew:
   ```bash
   brew install coreutils gnu-sed
   ```
2. Use portable alternatives:
   ```bash
   # Instead of readlink -f
   realpath() { python3 -c "import os; print(os.path.realpath('$1'))"; }
   ```
3. Abstract differences in helper functions
4. Test on both platforms (GitHub Actions matrix)

**Address in phase:** Phase 1 (Core Bootstrap) - use portable constructs

**Sources:**
- [Cross-Platform Dotfiles](https://calvin.me/cross-platform-dotfiles/)

---

## Common Annoyances

Fixable issues that cause friction.

### 13. Home Directory Pollution

**What goes wrong:** Home directory cluttered with dozens of dotfiles/directories. Hard to see what's yours vs what applications created.

**Why it happens:**
- Applications ignore XDG Base Directory spec
- Default configs drop files in `$HOME`
- No organization structure

**Warning signs:**
- `ls -la ~` shows 50+ items
- Can't tell which dotfiles are yours to manage
- Backup/sync becomes unreliable

**Prevention:**
1. Use XDG directories where supported:
   ```bash
   export XDG_CONFIG_HOME="$HOME/.config"
   export XDG_DATA_HOME="$HOME/.local/share"
   export XDG_CACHE_HOME="$HOME/.cache"
   ```
2. Configure apps to use XDG (many support it with env vars)
3. Run `xdg-ninja` to audit and clean up

**Address in phase:** Phase 2 (Shell Config) - set XDG vars in `.zshrc`

**Sources:**
- [XDG Base Directory - ArchWiki](https://wiki.archlinux.org/title/XDG_Base_Directory)
- [Clean your home folder with XDG](https://dev.to/ccoveille/clean-your-home-folder-discover-xdg-3ooh)

---

### 14. Font/Icon Issues in Terminal

**What goes wrong:** Prompt shows broken characters, file icons are boxes, Neovim statusline garbled.

**Why it happens:**
- Nerd Fonts not installed
- Wrong font configured in terminal
- Font installed but not loaded by system

**Warning signs:**
- `?` or box characters in prompt
- Icons in NERDTree/nvim-tree don't render
- Status bar symbols missing

**Prevention:**
1. Kitty has built-in Nerd Fonts symbols (no patched font needed)
2. For other terminals, install Nerd Fonts:
   ```bash
   # macOS
   brew tap homebrew/cask-fonts
   brew install --cask font-fira-code-nerd-font

   # Linux
   # Download from nerdfonts.com, place in ~/.local/share/fonts
   fc-cache -fv
   ```
3. Use `kitty +list-fonts` to verify fonts available
4. In kitty.conf, use `symbol_map` for Nerd Font ranges

**Address in phase:** Phase 3 (Terminal Config) - font installation in bootstrap

**Sources:**
- [Kitty and Nerd Fonts](https://erwin.co/kitty-and-nerd-fonts/)
- [Kitty FAQ on Fonts](https://sw.kovidgoyal.net/kitty/faq/)

---

### 15. Credential Helper Platform Mismatch

**What goes wrong:** Git keeps asking for password because credential helper is wrong for platform.

**Why it happens:**
- `.gitconfig` sets `credential.helper = osxkeychain` (macOS only)
- Linux needs different helper (`cache` or `store`)
- Windows needs `wincred`

**Warning signs:**
- Git prompts for credentials on every push
- "credential-osxkeychain is not a git command" error on Linux

**Prevention:**
1. Use conditional includes in `.gitconfig`:
   ```gitconfig
   [includeIf "gitdir:/Users/"]
     path = ~/.gitconfig-macos
   [includeIf "gitdir:/home/"]
     path = ~/.gitconfig-linux
   ```
2. Or set in install script per-platform:
   ```bash
   if [[ "$OSTYPE" == "darwin"* ]]; then
     git config --global credential.helper osxkeychain
   else
     git config --global credential.helper cache
   fi
   ```

**Address in phase:** Phase 1 (Core Bootstrap) - platform-specific git config

---

### 16. Version Manager File Compatibility

**What goes wrong:** `.tool-versions` or `.nvmrc` not recognized, wrong language version loaded.

**Why it happens:**
- asdf needs `legacy_version_file = yes` in `.asdfrc` to read `.nvmrc`
- mise uses different format than asdf by default
- Fuzzy versions (e.g., `node 20`) not compatible with all tools

**Warning signs:**
- `nvm use` works but `asdf` doesn't pick up version
- Different node/python version than expected
- "No version set" errors

**Prevention:**
1. If using asdf, enable legacy file support:
   ```bash
   echo "legacy_version_file = yes" >> ~/.asdfrc
   ```
2. If using mise, use `--pin` for exact versions:
   ```bash
   mise use --pin node@20.11.0
   ```
3. Stick to one version manager across team/projects

**Address in phase:** Phase 5 (Language Runtimes)

**Sources:**
- [Configure asdf legacy_version_file](https://github.com/thoughtbot/dotfiles/issues/654)
- [mise FAQ](https://mise.jdx.dev/faq.html)

---

## Edge Cases to Handle

### 17. Clone into Non-Empty Home Directory

**Problem:** `git clone` into `~` fails because directory isn't empty.

**Solution:** Use bare repo pattern or clone to `~/.dotfiles` and symlink.

---

### 18. First Run Without Internet

**Problem:** Install script assumes connectivity for package downloads, fails completely offline.

**Solution:** Check connectivity first, skip package installation gracefully:
```bash
if ! ping -c 1 github.com &>/dev/null; then
  echo "Warning: No internet. Skipping package installation."
fi
```

---

### 19. Running as Root

**Problem:** Install script run with `sudo ./install.sh` creates files owned by root.

**Solution:** Check and refuse:
```bash
if [ "$EUID" -eq 0 ]; then
  echo "Don't run as root. Script will ask for sudo when needed."
  exit 1
fi
```

---

### 20. Different Architecture (ARM vs x86)

**Problem:** Homebrew paths differ on Apple Silicon vs Intel Macs.

**Solution:** Detect architecture:
```bash
if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi
```

---

### 21. Existing oh-my-zsh Installation

**Problem:** OMZ already installed, reinstall fails or creates conflicts.

**Solution:** Check and skip:
```bash
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh already installed, skipping"
else
  # install
fi
```

---

### 22. SSH vs HTTPS for Git Remotes

**Problem:** Dotfiles repo uses SSH URL but new machine doesn't have SSH keys set up yet.

**Solution:** Clone via HTTPS initially, provide script to switch to SSH later:
```bash
git remote set-url origin git@github.com:user/dotfiles.git
```

---

## Phase-Specific Warnings Summary

| Phase | Critical Pitfalls | Must Address |
|-------|-------------------|--------------|
| Phase 1: Core Bootstrap | #1 Secrets, #2 Idempotency, #3 Overwrites, #4 Hardcoded paths, #5 Interactive prompts, #10 Sudo timeout | Secure `.gitignore`, safe symlink strategy, portable paths |
| Phase 2: Shell Config | #6 Slow startup, #7 OMZ race, #13 Home pollution | Lazy load NVM/pyenv, XDG variables |
| Phase 3: Terminal/Tmux | #8 TPM missing, #14 Fonts | TPM clone in bootstrap, font installation |
| Phase 4: Neovim | #9 Plugin bootstrap | Verify lazy.nvim bootstrap present |
| Phase 5: Languages | #16 Version files | Consistent version manager setup |
| All Phases | #11 Git identity, #12 BSD/GNU, #15 Credential helper | Platform detection, portable scripts |

---

## Sources

- [Why Your Public Dotfiles are a Security Minefield](https://medium.com/@instatunnel/why-your-public-dotfiles-are-a-security-minefield-fc9bdff62403)
- [Managing Dotfiles With Chezmoi](https://budimanjojo.com/2021/12/13/managing-dotfiles-with-chezmoi/)
- [Using GNU Stow to Manage Symbolic Links](https://systemcrafters.net/managing-your-dotfiles/using-gnu-stow/)
- [Cross-platform dotfile Management with dotbot](https://brianschiller.com/blog/2024/08/05/cross-platform-dotbot/)
- [Speeding Up Zsh](https://www.joshyin.cc/blog/speeding-up-zsh)
- [TPM Troubleshooting](https://github.com/tmux-plugins/tpm/blob/master/docs/tpm_not_working.md)
- [lazy.nvim Installation](https://lazy.folke.io/installation)
- [XDG Base Directory - ArchWiki](https://wiki.archlinux.org/title/XDG_Base_Directory)
- [Dotfiles automating macOS](https://kalis.me/dotfiles-automating-macos-system-configuration/)
- [Cross-Platform Dotfiles](https://calvin.me/cross-platform-dotfiles/)
- [mise FAQ](https://mise.jdx.dev/faq.html)
- [Kitty FAQ](https://sw.kovidgoyal.net/kitty/faq/)
