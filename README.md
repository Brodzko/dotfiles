# Dotfiles

Personal macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

- macOS
- [Homebrew](https://brew.sh/)
- Git

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/Brodzko/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Run the installation script:
   ```bash
   ./bootstrap/install.sh
   ```

3. (Optional) Apply macOS system defaults:
   ```bash
   ./bootstrap/macos.sh
   ```

4. Set up secrets:
   ```bash
   cp ~/zsh/.zsh_secrets.example.zsh ~/zsh/.zsh_secrets.zsh
   # Edit the file and add your secrets
   ```

5. Restart your terminal or source the configuration:
   ```bash
   source ~/.zshenv && source ~/zsh/.zshrc
   ```

## What's Included

### Shell
- **zsh** - Shell configuration with zinit plugin manager
  - Plugins: syntax-highlighting, autosuggestions, fzf-tab, and more
  - Custom Git, GitLab, and Jira integrations
  - Tab title updates with directory and git branch
- **starship** - Fast, customizable prompt

### Terminal
- **tmux** - Terminal multiplexer configuration
- **tmuxinator** - tmux session management

### Development Tools
- **git** - Git configuration with delta for better diffs
- **tig** - Text-mode interface for Git
- **nvim** - Neovim configuration
- **bat** - Cat clone with syntax highlighting

### System
- **karabiner** - Keyboard customization
- **ssh** - SSH configuration template (copy from `.ssh/config.example`)

### Package Management
- **Brewfile** - All Homebrew packages (formulas and casks)

## Structure

```
.dotfiles/
├── bootstrap/          # Installation and setup scripts
│   ├── install.sh     # Main installation script
│   ├── macos.sh       # macOS system preferences
│   └── Brewfile       # Homebrew packages
├── bat/               # bat configuration
├── git/               # Git config and themes
├── iterm2/            # iTerm2 Dynamic Profiles (optional)
├── karabiner/         # Karabiner keyboard customization
├── nvim/              # Neovim configuration
├── ssh/               # SSH config template
├── starship/          # Starship prompt config
├── tig/               # tig configuration
├── tmux/              # tmux configuration
├── tmuxinator/        # tmux session layouts
└── zsh/               # zsh configuration
    └── zsh/           # Actual zsh configs (ZDOTDIR)
        ├── git/       # Git-related functions
        ├── gitlab/    # GitLab integrations
        └── jira/      # Jira integrations
```

## Manual Setup Required

Some configurations require manual setup after installation:

1. **SSH Config**: Copy `~/.ssh/config.example` to `~/.ssh/config` and customize
2. **Zsh Secrets**: Copy `~/zsh/.zsh_secrets.example.zsh` to `~/zsh/.zsh_secrets.zsh` and add API keys
3. **Stow symlinks**: The install script handles this, but if needed manually:
   ```bash
   cd ~/.dotfiles
   stow zsh git tmux nvim  # etc.
   ```

## How It Works

This setup uses [GNU Stow](https://www.gnu.org/software/stow/) to manage symlinks. Each directory in `.dotfiles/` represents a "package" that can be stowed independently.

When you run `stow <package>` from the dotfiles directory, it creates symlinks in your home directory that point to files in the package directory.

For example:
```bash
cd ~/.dotfiles
stow zsh
# Creates: ~/.zshenv -> .dotfiles/zsh/.zshenv
# Creates: ~/zsh -> .dotfiles/zsh/zsh (ZDOTDIR - where the real zsh config lives)
```

Note: zsh configuration uses `ZDOTDIR` to keep config files in `~/zsh/` instead of cluttering `~/`. The `~/.zshenv` file sets this variable, then zsh looks for `.zshrc` in `$ZDOTDIR`.

## Key Features

### Shell Configuration
- **ZDOTDIR**: zsh configuration lives in `~/zsh/` instead of cluttering `~/`
- **Zinit**: Fast plugin manager with turbo mode
- **Custom integrations**: Git utilities, GitLab CLI helpers, Jira integration
- **fzf**: Fuzzy finder integration for files and directories

### Development
- **Delta**: Beautiful git diffs with syntax highlighting
- **eza**: Modern `ls` replacement with git integration
- **Git fuzzy**: Interactive git workflows

### Terminal Multiplexing
- **tmux**: Configured for development workflows
- **tmuxinator**: Pre-configured layouts for different projects

## Updating

To update your dotfiles:

```bash
cd ~/.dotfiles
git pull
./bootstrap/install.sh  # Re-stow everything
```

To update Homebrew packages:

```bash
brew bundle --file=~/.dotfiles/Brewfile
```

To regenerate the Brewfile with your current packages:

```bash
cd ~/.dotfiles
brew bundle dump --force
```

## Uninstalling

To remove symlinks for a specific package:

```bash
cd ~/.dotfiles
stow -D <package>  # e.g., stow -D zsh
```

## Dependencies

Key tools that must be installed (via Brewfile):

- **stow** - Symlink manager
- **fzf** - Fuzzy finder
- **fd** - Modern find alternative
- **eza** - Modern ls replacement
- **bat** - Cat with syntax highlighting
- **delta** - Git diff viewer
- **starship** - Shell prompt
- **tmux** - Terminal multiplexer
- **tmuxinator** - tmux session manager
- **tig** - Git TUI
- **neovim** - Text editor

## Customization

### Adding a new package

1. Create a new directory in `.dotfiles/`
2. Add your config files with the correct structure (e.g., `.config/app/config`)
3. Add the package to the `PACKAGES` array in `bootstrap/install.sh`
4. Run `stow <package>` to test

### Modifying existing configs

Just edit the files in `.dotfiles/` - changes are reflected immediately since they're symlinked.

## License

MIT

## Author

Martin Brodziansky
