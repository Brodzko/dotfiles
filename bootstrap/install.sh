#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting dotfiles installation...${NC}"

# Get the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR"

echo -e "\n${YELLOW}Installing Homebrew packages...${NC}"
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Homebrew not found. Please install Homebrew first:${NC}"
    echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Install from Brewfile
brew bundle --file="$DOTFILES_DIR/Brewfile"

echo -e "\n${YELLOW}Stowing dotfiles...${NC}"
if ! command -v stow &> /dev/null; then
    echo -e "${RED}GNU Stow not found. Installing via Homebrew...${NC}"
    brew install stow
fi

# Stow all packages
PACKAGES=(
    "bat"
    "git"
    "karabiner"
    "launchd"
    "nvim"
    "ssh"
    "starship"
    "tig"
    "tmux"
    "tmuxinator"
    "zsh"
)

for package in "${PACKAGES[@]}"; do
    echo -e "  Stowing ${GREEN}${package}${NC}..."
    stow -R "$package" -t "$HOME"
done

echo -e "\n${YELLOW}Setting up zsh...${NC}"
# Create ~/zsh symlink if it doesn't exist (for ZDOTDIR)
if [ ! -L "$HOME/zsh" ]; then
    ln -s "$DOTFILES_DIR/zsh/zsh" "$HOME/zsh"
    echo -e "  Created ${GREEN}~/zsh${NC} symlink"
fi

# Install zinit if not present
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    echo -e "  Installing zinit..."
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

echo -e "\n${YELLOW}Setting up SSH...${NC}"
if [ ! -f "$HOME/.ssh/config" ]; then
    echo -e "  ${YELLOW}Note: Copy $HOME/.ssh/config.example to $HOME/.ssh/config and customize it${NC}"
fi

echo -e "\n${YELLOW}Setting up secrets...${NC}"
if [ ! -f "$HOME/zsh/.zsh_secrets.zsh" ]; then
    echo -e "  ${YELLOW}Note: Copying $HOME/zsh/.zsh_secrets.example.zsh to $HOME/zsh/.zsh_secrets.zsh. Add your secrets here${NC}"
    cp ./zsh/zsh/.zsh_secrets.example.zsh ~/zsh/.zsh_secrets.zsh
fi

echo -e "\n${YELLOW}Setting up LaunchAgents...${NC}"
# Symlink LaunchAgents and load them
LAUNCHAGENTS_SRC="$HOME/.config/launchd/agents"
LAUNCHAGENTS_DST="$HOME/Library/LaunchAgents"

if [ -d "$LAUNCHAGENTS_SRC" ]; then
    mkdir -p "$LAUNCHAGENTS_DST"
    for plist in "$LAUNCHAGENTS_SRC"/*.plist; do
        if [ -f "$plist" ]; then
            plist_name=$(basename "$plist")
            # Create symlink
            ln -sf "$plist" "$LAUNCHAGENTS_DST/$plist_name"
            echo -e "  Linked ${GREEN}$plist_name${NC}"
            # Load the agent
            launchctl unload "$LAUNCHAGENTS_DST/$plist_name" 2>/dev/null || true
            launchctl load "$LAUNCHAGENTS_DST/$plist_name"
            echo -e "  Loaded ${GREEN}$plist_name${NC}"
        fi
    done
fi

echo -e "\n${GREEN}✓ Dotfiles installation complete!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Copy and customize ~/.ssh/config.example → ~/.ssh/config"
echo -e "  2. Copy and customize ~/zsh/.zsh_secrets.example.zsh → ~/zsh/.zsh_secrets.zsh"
echo -e "  3. Run ${GREEN}source ~/.zshenv && source ~/zsh/.zshrc${NC} or restart your terminal"
echo -e "  4. Optional: Run ${GREEN}./bootstrap/macos.sh${NC} to set macOS defaults"
