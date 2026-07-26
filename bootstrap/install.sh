#!/usr/bin/env bash

# Dotfiles installer.
#
# Deliberately NOT `set -e`: a single missing Homebrew cask or unpublished
# VSCode extension used to abort the whole script before anything got stowed,
# leaving the machine with no shell config at all. Failures are collected and
# reported at the end instead.

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILURES=()

# Anything this script moves out of the way goes here: stow conflicts, and font
# files that block a cask reinstall. Defined up front because both the font step
# and the stow step use it, and they are far apart.
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

fail() {
    FAILURES+=("$1")
    echo -e "  ${RED}✗ $1${NC}" >&2
}

step() { echo -e "\n${YELLOW}$1${NC}"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR" || exit 1

echo -e "${GREEN}Starting dotfiles installation...${NC}"
echo -e "  dotfiles: ${DOTFILES_DIR}"

###############################################################################
# Prerequisites                                                               #
###############################################################################

step "Checking prerequisites..."

if ! xcode-select -p &>/dev/null; then
    echo -e "  ${RED}Xcode Command Line Tools missing. Run:${NC}"
    echo "    xcode-select --install"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Xcode Command Line Tools"

if ! command -v brew &>/dev/null; then
    # Homebrew may be installed but not yet on PATH in a non-login shell.
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [ -x "$candidate" ] && eval "$("$candidate" shellenv)" && break
    done
fi

if ! command -v brew &>/dev/null; then
    echo -e "  ${RED}Homebrew not found. Install it first:${NC}"
    # shellcheck disable=SC2016  # printing the command verbatim, not running it
    echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Homebrew ($(brew --prefix))"

###############################################################################
# Homebrew packages                                                           #
###############################################################################

step "Installing Homebrew packages..."

# `brew bundle` keeps going after individual failures but exits non-zero, so
# only record the failure and carry on with the rest of the setup.
if ! brew bundle --file="$DOTFILES_DIR/Brewfile" --no-upgrade; then
    fail "brew bundle had failures (see above) - rerun 'brew bundle check --verbose' to list them"
fi

###############################################################################
# Fonts                                                                       #
###############################################################################

# `brew bundle --no-upgrade` asks Homebrew whether a cask is installed, and
# Homebrew answers from its receipt. A font cask whose adoption failed once (it
# refuses to overwrite a hand-installed file of the same name: "existing Font is
# different") leaves a receipt behind with no files on disk. bundle then reports
# it satisfied forever and the font never appears - which is exactly how a
# machine ends up with an iTerm2 profile falling back to Menlo.
#
# So don't trust the receipt: ask the font system whether the family is actually
# registered, and force a reinstall when it isn't.
step "Verifying fonts..."

# Family substring -> cask that provides it. The substring has to appear in
# system_profiler's font list for the family to count as present.
FONT_FAMILIES=(
    "FiraCode:font-fira-code"
    "CascadiaCodeNF:font-cascadia-code-nf"
    "HackNerdFont:font-hack-nerd-font"
)

# Captured once: system_profiler is slow, and piping it into `grep -q` would
# SIGPIPE it on the first match and trip `pipefail`.
fonts_db="$(system_profiler SPFontsDataType 2>/dev/null)"

for entry in "${FONT_FAMILIES[@]}"; do
    family="${entry%%:*}"
    cask="${entry##*:}"

    if [[ $fonts_db == *"$family"* ]]; then
        echo -e "  ${GREEN}✓${NC} $family registered"
        continue
    fi

    echo -e "  ${YELLOW}$family not registered - repairing $cask${NC}"

    # Move loose files of the same family aside first, or the reinstall hits the
    # same adoption conflict that created this mess.
    mkdir -p "$BACKUP_DIR/fonts"
    shopt -s nullglob nocaseglob
    for stray in "$HOME/Library/Fonts/${family}"*; do
        [ -L "$stray" ] && continue
        mv "$stray" "$BACKUP_DIR/fonts/" 2>/dev/null \
            && echo -e "    moved $(basename "$stray") to $BACKUP_DIR/fonts/"
    done
    shopt -u nullglob nocaseglob

    if brew reinstall --cask "$cask"; then
        echo -e "  ${GREEN}✓${NC} reinstalled $cask"
    else
        fail "could not reinstall $cask - $family will be missing"
    fi
done

# Homebrew tags every cask it installs with com.apple.quarantine (it is a
# download from the internet, as far as Gatekeeper is concerned). A quarantined
# bundle has a different TCC identity than the same app unquarantined, so macOS
# treats each launch as a new app and re-asks for Accessibility / Screen
# Recording / Full Disk Access every single time. iTerm2 is the loud one.
#
# HOMEBREW_CASK_OPTS=--no-quarantine (set in zsh/.zshenv) prevents this going
# forward; the loop below repairs bundles installed before that was in place.
#
# Scope is "Homebrew has a cask holding an app of this name", checked against the
# Caskroom. An earlier version scoped by the flag's own agent field (it records
# e.g. "Homebrew\x20Cask") - that silently skipped the app it was written for,
# because a bundle that arrived via Migration Assistant, or was installed by an
# older Homebrew, carries a different agent while still being cask-managed now.
# Apps Homebrew knows nothing about are still left alone, which is the point.
step "Clearing quarantine on Homebrew-installed apps..."

CASKROOM="$(brew --caskroom 2>/dev/null)"

cask_owns_app() {
    local name
    name="$(basename "$1")"
    [ -n "$CASKROOM" ] || return 1
    compgen -G "$CASKROOM/*/*/$name" >/dev/null 2>&1
}

quarantine_cleared=0
shopt -s nullglob
for app in /Applications/*.app "$HOME/Applications"/*.app; do
    xattr "$app" 2>/dev/null | grep -q com.apple.quarantine || continue
    cask_owns_app "$app" || continue

    if xattr -dr com.apple.quarantine "$app" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} unquarantined $(basename "$app")"
        quarantine_cleared=$((quarantine_cleared + 1))
    else
        # SIP or ownership. Worth a loud message: this is the cause of an app
        # re-asking for permissions on every single launch.
        fail "could not clear quarantine on $app (try: sudo xattr -dr com.apple.quarantine '$app')"
    fi
done
shopt -u nullglob

[ "$quarantine_cleared" -eq 0 ] && echo -e "  ${GREEN}✓${NC} nothing quarantined"
###############################################################################
# Stow packages                                                               #
###############################################################################

step "Stowing dotfiles..."

if ! command -v stow &>/dev/null; then
    echo -e "  ${YELLOW}GNU Stow not found, installing...${NC}"
    brew install stow
    hash -r

    # Re-check rather than trusting brew's exit code: if stow still isn't
    # callable, every package below fails one by one for the same reason. Bail
    # out with one clear message instead.
    if ! command -v stow &>/dev/null; then
        echo -e "  ${RED}Cannot continue without stow.${NC}" >&2
        echo -e "  ${RED}Install it manually ('brew install stow') and rerun.${NC}" >&2
        exit 1
    fi
fi
echo -e "  ${GREEN}✓${NC} stow ($(stow --version | head -1))"

DOTFILES_PHYS="$(cd "$DOTFILES_DIR" && pwd -P)"

backup_conflicts() {
    local package="$1"
    local rel target target_dir

    # The only README we skip is the package's own root one (stow ignores it
    # via .stow-local-ignore's ^/README.*). Nested ones - e.g. kickstart's
    # nvim/.config/nvim/README.md - are real config files that stow does link,
    # so they need backing up like anything else. Excluding them by -name left
    # the existing file in place and aborted the whole nvim package.
    while IFS= read -r -d '' file; do
        rel="${file#"$DOTFILES_DIR/$package/"}"
        target="$HOME/$rel"

        # Only real files block stow; existing symlinks get re-pointed by -R.
        [ -f "$target" ] || continue
        [ -L "$target" ] && continue

        # CRITICAL: a stowed *directory* symlink (e.g. ~/zsh -> repo/zsh/zsh)
        # makes repo files look like plain files living under $HOME. Resolving
        # the parent and rejecting anything already inside the repo stops us
        # from "backing up" - i.e. deleting - our own tracked config.
        target_dir="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)" || continue
        case "$target_dir/" in
            "$DOTFILES_PHYS/"*) continue ;;
        esac

        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        mv "$target" "$BACKUP_DIR/$rel"
        echo -e "    ${YELLOW}backed up${NC} ~/$rel"
    done < <(find "$DOTFILES_DIR/$package" -type f \
        ! -name '.DS_Store' ! -name '.stow-local-ignore' \
        ! -path "$DOTFILES_DIR/$package/README.md" -print0)
}

# NOTE: iterm2/ and raycast/ are intentionally absent - they are not stow
# packages (iTerm2 loads its prefs folder directly, Raycast imports a file).
PACKAGES=(
    "bat"
    "git"
    "htop"
    "karabiner"
    "launchd"
    "nvim"
    "ssh"
    "starship"
    "tmux"
    "vscode"
    "zsh"
)

# Packages that must NOT be tree-folded. When the target directory doesn't exist
# yet, stow's default is to symlink the whole directory into the repo - so the
# app then writes all its runtime state there. VSCode is the bad case: a fresh
# machine has no ~/Library/Application Support/Code, so folding would point it
# at the repo and VSCode would dump History/, workspaceStorage/ and caches into
# git. --no-folding creates real directories and symlinks only the leaf files.
NO_FOLDING=("vscode")

for package in "${PACKAGES[@]}"; do
    if [ ! -d "$DOTFILES_DIR/$package" ]; then
        fail "stow: package '$package' does not exist"
        continue
    fi

    stow_opts=(--ignore='\.DS_Store' -R)
    for nf in "${NO_FOLDING[@]}"; do
        [ "$nf" = "$package" ] && stow_opts+=(--no-folding)
    done

    echo -e "  Stowing ${GREEN}${package}${NC}..."
    backup_conflicts "$package"
    stow "${stow_opts[@]}" "$package" -t "$HOME" || fail "stow: $package"
done

if [ -d "$BACKUP_DIR" ]; then
    echo -e "  ${YELLOW}Replaced files were backed up to $BACKUP_DIR${NC}"
fi

###############################################################################
# zsh                                                                         #
###############################################################################

step "Setting up zsh..."

# `stow zsh` already creates ~/zsh; this is only a fallback.
if [ ! -e "$HOME/zsh" ]; then
    ln -s "$DOTFILES_DIR/zsh/zsh" "$HOME/zsh" && echo -e "  Created ${GREEN}~/zsh${NC} symlink"
fi

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    echo -e "  Installing zinit..."
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" || fail "zinit clone"
else
    echo -e "  ${GREEN}✓${NC} zinit already installed"
fi

###############################################################################
# Secrets & local-only config                                                 #
###############################################################################

step "Setting up secrets..."

if [ ! -f "$HOME/zsh/.zsh_secrets.zsh" ]; then
    cp "$DOTFILES_DIR/zsh/zsh/.zsh_secrets.example.zsh" "$HOME/zsh/.zsh_secrets.zsh" \
        && echo -e "  Created ${GREEN}~/zsh/.zsh_secrets.zsh${NC} from the example - add your keys"
else
    echo -e "  ${GREEN}✓${NC} ~/zsh/.zsh_secrets.zsh exists"
fi

step "Setting up SSH..."
if [ ! -f "$HOME/.ssh/config" ]; then
    echo -e "  ${YELLOW}Copy ~/.ssh/config.example to ~/.ssh/config and customize it${NC}"
else
    echo -e "  ${GREEN}✓${NC} ~/.ssh/config exists"
fi

###############################################################################
# iTerm2                                                                      #
###############################################################################

step "Configuring iTerm2..."

ITERM_PREFS="$DOTFILES_DIR/iterm2/preferences"
ITERM_PLIST="$ITERM_PREFS/com.googlecode.iterm2.plist"

if [ -f "$ITERM_PLIST" ]; then
    # Pointing iTerm2 at the folder while it runs is pointless - it rewrites its
    # prefs from memory on quit and wins. The usual way to run this script is
    # *from* iTerm2, so this has to fail loudly with the exact repair command;
    # a soft "skipped" got ignored and the machine kept iTerm2's stock profile,
    # stock font included.
    if pgrep -xq iTerm2; then
        fail "iTerm2 prefs not applied - iTerm2 is running and would overwrite them on quit"
        echo -e "  ${YELLOW}Quit iTerm2, then run this from Terminal.app:${NC}"
        echo "    defaults import com.googlecode.iterm2 '$ITERM_PLIST'"
        echo "    defaults write com.googlecode.iterm2 PrefsCustomFolder -string '$ITERM_PREFS'"
        echo "    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true"
    else
        # Two separate things, and only doing the second is why a fresh machine
        # ended up with no com.googlecode.iterm2 domain at all:
        #
        #   import - populates the domain now, so the very first launch already
        #            has the right profile (FiraCode 14).
        #   the two keys - tell iTerm2 to keep reading the repo from then on.
        if defaults import com.googlecode.iterm2 "$ITERM_PLIST" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} imported $(basename "$ITERM_PLIST")"
        else
            fail "defaults import com.googlecode.iterm2 failed"
        fi

        defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$ITERM_PREFS"
        defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
        # Keep the repo as the source of truth: don't let iTerm2 write back on quit.
        defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2
        echo -e "  ${GREEN}✓${NC} iTerm2 pointed at $ITERM_PREFS"
    fi
else
    fail "iTerm2 prefs missing at $ITERM_PLIST"
fi

###############################################################################
# LaunchAgents                                                                #
###############################################################################

step "Setting up LaunchAgents..."

LAUNCHAGENTS_SRC="$HOME/.config/launchd/agents"
LAUNCHAGENTS_DST="$HOME/Library/LaunchAgents"

if [ -d "$LAUNCHAGENTS_SRC" ]; then
    mkdir -p "$LAUNCHAGENTS_DST"
    shopt -s nullglob
    for plist in "$LAUNCHAGENTS_SRC"/*.plist; do
        plist_name=$(basename "$plist")
        ln -sf "$plist" "$LAUNCHAGENTS_DST/$plist_name"
        launchctl unload "$LAUNCHAGENTS_DST/$plist_name" 2>/dev/null
        if launchctl load "$LAUNCHAGENTS_DST/$plist_name"; then
            echo -e "  Loaded ${GREEN}$plist_name${NC}"
        else
            fail "launchctl load $plist_name"
        fi
    done
    shopt -u nullglob
else
    echo -e "  ${YELLOW}No agents at $LAUNCHAGENTS_SRC (did 'stow launchd' run?)${NC}"
fi

###############################################################################
# Summary                                                                     #
###############################################################################

if [ ${#FAILURES[@]} -eq 0 ]; then
    echo -e "\n${GREEN}✓ Dotfiles installation complete!${NC}"
else
    echo -e "\n${YELLOW}Dotfiles installed, but ${#FAILURES[@]} step(s) failed:${NC}"
    for f in "${FAILURES[@]}"; do
        echo -e "  ${RED}✗${NC} $f"
    done
fi

echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Add secrets to ${GREEN}~/zsh/.zsh_secrets.zsh${NC}"
echo -e "  2. Copy and customize ${GREEN}~/.ssh/config.example → ~/.ssh/config${NC}"
echo -e "  3. AI agent config lives in a separate repo:"
echo -e "       ${GREEN}git clone git@github.com:Brodzko/agent-config.git ~/agent-config${NC}"
echo -e "       ${GREEN}~/agent-config/scripts/sync.sh${NC}"
echo -e "  4. Import Raycast settings from ${GREEN}raycast/*.rayconfig${NC}"
echo -e "  5. Run ${GREEN}exec zsh${NC} or restart your terminal"
echo -e "  6. Optional: ${GREEN}./bootstrap/macos.sh${NC} to set macOS defaults"

[ ${#FAILURES[@]} -eq 0 ]
