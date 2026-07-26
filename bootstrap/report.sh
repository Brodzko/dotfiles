#!/usr/bin/env bash

# Dumps everything needed to diagnose a misbehaving machine into one file.
#
# Read-only: it never writes a preference, installs anything, or changes state.
# It asks for sudo only to read the root-owned login window plist.
#
# The point is to move real output off the affected machine instead of guessing
# from a machine that works. Usage:
#
#   ./bootstrap/report.sh
#   git checkout -B debug/report && git add -f bootstrap/report-*.txt
#   git commit -m "chore: Machine report" && git push -fu origin debug/report

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$DOTFILES_DIR/bootstrap/report-$(scutil --get LocalHostName 2>/dev/null || hostname -s).txt"

: > "$OUT"

# Run a command and record it with its exit status. Output is captured whole -
# never piped into something that exits early, which would SIGPIPE the producer
# and (under pipefail) misreport a working command as broken.
cap() {
    local label="$1"
    shift
    {
        echo "=============================================================="
        echo "### $label"
        echo "\$ $*"
    } >> "$OUT"
    local output status
    output="$("$@" 2>&1)"
    status=$?
    {
        printf '%s\n' "$output"
        echo "[exit $status]"
        echo
    } >> "$OUT"
}

echo "Collecting into $OUT"
echo "sudo is needed once, to read the root-owned login window plist."
sudo -v || echo "No sudo - the login window section will be incomplete."

###############################################################################
# Identity - above all, WHICH COMMIT of the dotfiles is actually checked out.  #
###############################################################################

cap "macOS version" sw_vers
cap "model" sysctl -n hw.model
cap "dotfiles HEAD" git -C "$DOTFILES_DIR" log --oneline -3
cap "dotfiles status" git -C "$DOTFILES_DIR" status --short --branch
cap "FileVault" fdesetup status

###############################################################################
# Keyboard                                                                    #
###############################################################################

cap "login window plist (root-owned, drives the login screen)" \
    sudo plutil -p /Library/Preferences/com.apple.HIToolbox.plist

# The two keys that actually decide the login screen, isolated. Reading them out
# of the full dump above is error-prone: AppleInputSourceHistory sits right next
# to AppleEnabledInputSources and looks identical at a glance.
cap "login window: enabled input sources only" \
    sudo plutil -extract AppleEnabledInputSources json -o - \
    /Library/Preferences/com.apple.HIToolbox.plist
cap "login window: input source history only" \
    sudo plutil -extract AppleInputSourceHistory json -o - \
    /Library/Preferences/com.apple.HIToolbox.plist
cap "user plist (drives the logged-in session)" \
    plutil -p "$HOME/Library/Preferences/com.apple.HIToolbox.plist"
cap "per-app input source memory" \
    defaults read com.apple.HIToolbox AppleGlobalTextInputProperties
cap "current layout" \
    defaults read com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID

# Whether the Preboot volume even holds a copy to sync, and how old it is.
cap "preboot volumes" diskutil apfs list

# The actual source of the boot screen's keyboard: the Preboot volume's snapshot
# of this user's enabled input sources. Neither HIToolbox plist above controls
# it; only `diskutil apfs updatePreboot` refreshes it. Its mtime says when.
for candidate in /System/Volumes/Preboot/*/var/db/AllUsersInfo.plist; do
    [ -f "$candidate" ] || continue
    cap "preboot snapshot mtime" ls -la "$candidate"
    cap "boot screen input sources for $(id -un)" \
        /usr/libexec/PlistBuddy -c "Print :$(id -un):InputSources" "$candidate"
done

###############################################################################
# Fonts                                                                       #
###############################################################################

cap "font files in ~/Library/Fonts" ls -la "$HOME/Library/Fonts"
cap "font files in /Library/Fonts" ls -la /Library/Fonts
cap "font casks per Homebrew's receipts" brew list --cask
cap "font cask contents (hack)" brew list --cask font-hack-nerd-font
cap "font cask contents (fira)" brew list --cask font-fira-code

# What the font system actually knows about, which is what apps see. Grep is
# fine here because the producer is a file, not a pipe.
{
    echo "=============================================================="
    echo "### registered font families (per family match count)"
} >> "$OUT"
fonts_db="$(system_profiler SPFontsDataType 2>/dev/null)"
echo "fonts_db length: ${#fonts_db}" >> "$OUT"
for family in FiraCode HackNerdFont CascadiaCodeNF Menlo; do
    count="$(printf '%s' "$fonts_db" | grep -ci "$family")"
    echo "$family: $count" >> "$OUT"
done
echo >> "$OUT"

###############################################################################
# Quarantine                                                                  #
###############################################################################

{
    echo "=============================================================="
    echo "### quarantine flags on installed apps"
} >> "$OUT"
shopt -s nullglob
for app in /Applications/*.app "$HOME/Applications"/*.app; do
    flag="$(xattr -p com.apple.quarantine "$app" 2>/dev/null)"
    caskroom="$(brew --caskroom 2>/dev/null)"
    owned="no"
    [ -n "$caskroom" ] && compgen -G "$caskroom/*/*/$(basename "$app")" >/dev/null 2>&1 && owned="yes"
    printf '%-45s cask=%-3s quarantine=%s\n' "$(basename "$app")" "$owned" "${flag:-none}" >> "$OUT"
done
shopt -u nullglob
echo >> "$OUT"

cap "iTerm.app signature" codesign -dv --verbose=2 /Applications/iTerm.app

###############################################################################
# iTerm2                                                                      #
###############################################################################

cap "iTerm2 prefs folder setting" defaults read com.googlecode.iterm2 PrefsCustomFolder
cap "iTerm2 load-from-folder setting" defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder
cap "iTerm2 running?" pgrep -xl iTerm2

{
    echo "=============================================================="
    echo "### iTerm2 fonts: live domain vs repo"
    defaults read com.googlecode.iterm2 "New Bookmarks" 2>/dev/null |
        grep -E '"(Normal Font|Non Ascii Font|Use Non-ASCII Font)"' 2>&1
    echo "--- repo ---"
    plutil -p "$DOTFILES_DIR/iterm2/preferences/com.googlecode.iterm2.plist" 2>/dev/null |
        grep -E '"(Normal Font|Non Ascii Font|Use Non-ASCII Font)"' 2>&1
    echo
} >> "$OUT"

###############################################################################
# Doctor                                                                      #
###############################################################################

cap "doctor.sh" "$DOTFILES_DIR/bootstrap/doctor.sh"

echo
echo "Done: $OUT"
echo
echo "Send it over with:"
echo "  cd $DOTFILES_DIR"
echo "  git checkout -B debug/report"
echo "  git add -f bootstrap/$(basename "$OUT")"
echo "  git commit -m 'chore: Machine report'"
echo "  git push -fu origin debug/report"
