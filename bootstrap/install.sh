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

# Stow refuses to overwrite a real (non-symlink) file. A fresh machine ships or
# generates plenty of those - ~/.gitconfig, VSCode's settings.json, ~/.tmux.conf
# - and each one aborts the whole package. Move them aside first.
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DOTFILES_PHYS="$(cd "$DOTFILES_DIR" && pwd -P)"

backup_conflicts() {
    local package="$1"
    local rel target target_dir
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
        ! -name '.DS_Store' ! -name '.stow-local-ignore' ! -name 'README.md' -print0)
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
if [ -d "$ITERM_PREFS" ]; then
    if pgrep -xq iTerm2; then
        echo -e "  ${YELLOW}iTerm2 is running - quit it and rerun, or set the prefs folder manually${NC}"
        echo -e "  ${YELLOW}(Settings → General → Preferences → load from custom folder)${NC}"
    else
        defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$ITERM_PREFS"
        defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
        # Keep the repo as the source of truth: don't let iTerm2 write back on quit.
        defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2
        echo -e "  ${GREEN}✓${NC} iTerm2 pointed at $ITERM_PREFS"
    fi
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
