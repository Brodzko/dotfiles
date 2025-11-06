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
    echo "==> Adding '$package_name' to $MY_BREWFILE"
    # Add the line to the file, but check if it's already there
    if ! grep -q -x "$brewfile_line" "$MY_BREWFILE"; then
      echo "$brewfile_line" >> "$MY_BREWFILE"
      # Optional: Sort the file to keep it clean
      sort -u "$MY_BREWFILE" -o "$MY_BREWFILE"
    else
      echo "==> '$package_name' is already in $MY_BREWFILE"
    fi
  else
    echo "Failed to install '$package_name'. Brewfile not updated." >&2
  fi
}