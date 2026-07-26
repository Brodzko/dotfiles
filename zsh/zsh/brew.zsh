# Your path to your Brewfile
MY_BREWFILE="$HOME/.dotfiles/Brewfile"

# Installs a brew formula OR cask and adds to Brewfile
badd() {
  local package_name
  local brewfile_line
  
  # Find the actual package name, ignoring options
  for arg in "$@"; do
    if [[ "$arg" != -* ]]; then
      package_name="$arg"
      break
    fi
  done

  # Check for empty package name
  if [[ -z "$package_name" ]]; then
    echo "Usage: badd [options] <package-name>" >&2
    echo "Example: badd jq" >&2
    echo "Example: badd --cask visual-studio-code" >&2
    return 1
  fi

  # Check if --cask is present anywhere in the arguments
  if [[ " $@ " =~ " --cask " ]]; then
    brewfile_line="cask \"$package_name\""
  else
    brewfile_line="brew \"$package_name\""
  fi

  echo "==> Installing '$package_name' with options: $@"
  if brew install "$@"; then
    # Add the line to the file, but check if it's already there.
    # NOTE: do NOT sort the Brewfile - it is hand-grouped under section
    # comments and sorting shreds that structure.
    if grep -q -x "$brewfile_line" "$MY_BREWFILE"; then
      echo "==> '$package_name' is already in $MY_BREWFILE"
    else
      echo "==> Adding '$package_name' to $MY_BREWFILE"
      echo "$brewfile_line" >> "$MY_BREWFILE"
      echo "==> Move it into the right section when you get a chance."
    fi
  else
    echo "Failed to install '$package_name'. Brewfile not updated." >&2
  fi
}