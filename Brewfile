# Brewfile
#
# Keep entries grouped under their section headings. `brew bundle dump --force`
# flattens this file and drops the comments, so prefer editing by hand or via
# the `badd` helper (see zsh/zsh/brew.zsh).

###############################################################################
# Core utilities                                                              #
###############################################################################
brew "bat"
brew "coreutils"
brew "eza"
brew "fd"
brew "fzf"
brew "gum"
brew "htop"
brew "jq"
brew "pigz"
brew "ripgrep"
brew "starship"
brew "stow"
brew "tmux"
brew "tmuxinator"
brew "tree"
brew "wget"

###############################################################################
# Git & forge tools                                                           #
###############################################################################
brew "gh"
brew "git"
brew "git-delta"
brew "gitleaks"
brew "glab"
brew "jira-cli"
brew "lazygit"
brew "tig"

###############################################################################
# Development tools                                                           #
###############################################################################
brew "fnm"
brew "hyperfine"
brew "neovim"
brew "poetry"
brew "python@3.12"
brew "shellcheck"
brew "uv"
brew "yamllint"

###############################################################################
# Docker & Kubernetes                                                         #
###############################################################################
brew "colima"
brew "dive"
brew "docker"
brew "docker-buildx"
brew "docker-compose"
brew "helm"
brew "kubernetes-cli"

###############################################################################
# Database                                                                    #
###############################################################################
brew "pgcli"
brew "postgresql@14", restart_service: :changed

###############################################################################
# Libraries & misc                                                            #
###############################################################################
brew "ddgr"
# displayplacer: bootstrap/macos.sh needs it to set the display scaling, which
# has no `defaults` key.
brew "displayplacer"
brew "ffmpeg"
brew "gource"
brew "graphviz"
brew "libmagic"
brew "mas"
brew "pandoc"
brew "poppler"
brew "pybind11"
brew "qpdf"
brew "re2"
brew "zbar"
brew "zsh-syntax-highlighting"

###############################################################################
# Casks - Applications                                                        #
###############################################################################
cask "1password"
cask "1password-cli"
cask "applepi-baker"
cask "brave-browser"
cask "firefox"
cask "ghostty"
cask "google-chrome"
cask "iterm2"
cask "keyboardcleantool"
cask "mysides"
cask "ngrok"
cask "obsidian"
cask "openlens"
cask "podman-desktop"
cask "postman"
cask "raycast"
cask "slack"
cask "steam"
cask "supacode"
cask "visual-studio-code"
cask "vlc"

###############################################################################
# Casks - Fonts                                                               #
###############################################################################
cask "font-cascadia-code-nf"
cask "font-fira-code"
cask "font-hack-nerd-font"
cask "font-meslo-lg-nerd-font"

###############################################################################
# VSCode Extensions                                                           #
#                                                                             #
# Locally-installed extensions (pi.pi-vscode-diagnostics, quill.quill-vscode)  #
# are intentionally absent - they are not on the marketplace.                  #
###############################################################################
vscode "ancientlord.nightowl-theme"
vscode "anthropic.claude-code"
vscode "avetis.tokyo-night"
vscode "ckolkman.vscode-postgres"
vscode "dbaeumer.vscode-eslint"
vscode "docker.docker"
vscode "donjayamanne.python-environment-manager"
vscode "eamodio.gitlens"
vscode "enkia.tokyo-night"
vscode "esbenp.prettier-vscode"
vscode "fnando.linter"
vscode "foxundermoon.shell-format"
vscode "github.vscode-github-actions"
vscode "gitlab.gitlab-workflow"
vscode "gruntfuggly.todo-tree"
vscode "hashicorp.terraform"
vscode "haskell.haskell"
vscode "haskell.language-haskell"
vscode "kennylong.kubernetes-yaml-formatter"
vscode "liviuschera.noctis"
vscode "mquandalle.graphql"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-kubernetes-tools.vscode-kubernetes-tools"
vscode "ms-playwright.playwright"
vscode "ms-python.debugpy"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "mtxr.sqltools"
vscode "orta.vscode-twoslash-queries"
vscode "oxc.oxc-vscode"
vscode "pamaron.pytest-runner"
vscode "redhat.vscode-yaml"
vscode "richie5um2.vscode-sort-json"
vscode "robbowen.synthwave-vscode"
vscode "snowflake.snowflake-vsc"
vscode "syler.sass-indented"
vscode "timonwong.shellcheck"
vscode "typescriptteam.native-preview"
vscode "unifiedjs.vscode-mdx"
vscode "vscode-icons-team.vscode-icons"
vscode "wayou.file-icons-mac"
vscode "wesbos.theme-cobalt2"
vscode "xyc.vscode-mdx-preview"
vscode "yoavbls.pretty-ts-errors"
