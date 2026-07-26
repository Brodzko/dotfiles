export ZDOTDIR="${HOME}/zsh"
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

# Don't let Homebrew tag casks with com.apple.quarantine. A quarantined bundle
# has a different TCC identity than the same app unquarantined, so macOS asks
# for Accessibility / Screen Recording / Full Disk Access again on every launch.
# These are casks from a Brewfile in a repo I control, not random downloads.
export HOMEBREW_CASK_OPTS="--no-quarantine"
