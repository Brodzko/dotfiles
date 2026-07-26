#!/usr/bin/env bash

# Reports what this machine actually looks like next to what the dotfiles
# expect. Read-only: it never writes a preference, installs anything, or asks
# for sudo. Run it on a machine that behaves wrong and compare the output with a
# machine that behaves right.

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
DIM='\033[2m'
NC='\033[0m'

FAILED=0

section() { echo -e "\n${YELLOW}$1${NC}"; }

# ok <label> <actual>
ok() { echo -e "  ${GREEN}✓${NC} $1: $2"; }

# bad <label> <actual> <expected>
bad() {
    FAILED=$((FAILED + 1))
    echo -e "  ${RED}✗${NC} $1: ${RED}$2${NC} ${DIM}(expected: $3)${NC}"
}

# want <label> <actual> <expected>
want() {
    if [ "$2" = "$3" ]; then ok "$1" "$2"; else bad "$1" "${2:-<unset>}" "$3"; fi
}

info() { echo -e "  ${DIM}$1: $2${NC}"; }

# Read a user default, printing nothing when the key or domain is missing.
read_default() { defaults read "$1" "$2" 2>/dev/null; }

###############################################################################
# Machine                                                                     #
###############################################################################

section "Machine"

info "macOS" "$(sw_vers -productVersion) ($(sw_vers -buildVersion))"
info "model" "$(sysctl -n hw.model)"
info "host" "$(scutil --get ComputerName 2>/dev/null || hostname)"

###############################################################################
# Display                                                                     #
###############################################################################

section "Display scaling"

# The built-in panel should run at exactly half its native pixel size with HiDPI
# on - that is System Settings' "Default". Anything larger is "More Space" and
# shrinks every point-sized font, iTerm2's included.
if command -v displayplacer &>/dev/null; then
    dp_out="$(displayplacer list 2>/dev/null)"
    current="$(printf '%s\n' "$dp_out" | awk '/built.in screen/{f=1} f && /^Resolution:/{print $2; exit}')"
    native="$(printf '%s\n' "$dp_out" | awk '
        /built.in screen/ { f = 1 }
        f && match($0, /res:[0-9]+x[0-9]+/) {
            split(substr($0, RSTART + 4, RLENGTH - 4), r, "x")
            if (r[1] * r[2] > best) { best = r[1] * r[2]; w = r[1]; h = r[2] }
        }
        END { if (w) print w "x" h }')"

    if [ -n "$native" ]; then
        info "built-in native" "$native"
        want "built-in logical" "$current" "$((${native%%x*} / 2))x$((${native##*x} / 2))"
    else
        bad "built-in display" "not found in displayplacer output" "one built-in screen"
    fi
else
    bad "displayplacer" "missing" "brew bundle installs it"
fi

###############################################################################
# Fonts                                                                       #
###############################################################################

section "Fonts"

# iTerm2's profile asks for FiraCode-Regular 14. A missing font file makes it
# fall back silently, which reads as "iTerm2's font is broken".
for font in FiraCode-Regular.ttf CascadiaCodeNF.ttf; do
    if [ -f "$HOME/Library/Fonts/$font" ] || [ -f "/Library/Fonts/$font" ]; then
        ok "$font" "installed"
    else
        bad "$font" "not in ~/Library/Fonts or /Library/Fonts" "installed by its cask"
    fi
done

info "fira files present" "$(find "$HOME/Library/Fonts" /Library/Fonts -maxdepth 1 -iname 'firacode*' 2>/dev/null | wc -l | tr -d ' ')"
info "font casks" "$(brew list --cask 2>/dev/null | grep -c '^font-')"

###############################################################################
# iTerm2                                                                      #
###############################################################################

section "iTerm2"

ITERM_PREFS="$HOME/.dotfiles/iterm2/preferences"

want "PrefsCustomFolder" "$(read_default com.googlecode.iterm2 PrefsCustomFolder)" "$ITERM_PREFS"
want "LoadPrefsFromCustomFolder" "$(read_default com.googlecode.iterm2 LoadPrefsFromCustomFolder)" "1"

live_font="$(read_default com.googlecode.iterm2 "New Bookmarks" | sed -n 's/.*"Normal Font" = "\(.*\)";/\1/p' | head -1)"
repo_font="$(plutil -p "$ITERM_PREFS/com.googlecode.iterm2.plist" 2>/dev/null |
    sed -n 's/.*"Normal Font" => "\(.*\)"/\1/p' | head -1)"
want "profile font" "$live_font" "$repo_font"

if pgrep -xq iTerm2; then
    echo -e "  ${YELLOW}!${NC} iTerm2 is running - it rewrites its prefs from memory on quit,"
    echo -e "    so any fix has to be applied from Terminal.app with iTerm2 quit."
fi

# Repeated permission prompts on every launch mean TCC cannot match the app to
# the grant it stored: a broken/ad-hoc signature (bundle copied while running,
# or by Migration Assistant) or a quarantined copy running from elsewhere.
for app in /Applications/iTerm.app "$HOME/Applications/iTerm.app" "$HOME/Downloads/iTerm.app"; do
    [ -d "$app" ] && info "bundle" "$app"
done

if [ -d /Applications/iTerm.app ]; then
    if codesign --verify --strict /Applications/iTerm.app 2>/dev/null; then
        ok "code signature" "valid"
    else
        bad "code signature" "invalid" "valid - fix with: brew reinstall --cask iterm2"
    fi
    if xattr /Applications/iTerm.app 2>/dev/null | grep -q com.apple.quarantine; then
        bad "quarantine flag" "set" "absent - fix with: xattr -dr com.apple.quarantine /Applications/iTerm.app"
    else
        ok "quarantine flag" "absent"
    fi
else
    bad "iTerm.app" "not in /Applications" "installed by the iterm2 cask"
fi

###############################################################################
# Keyboard                                                                    #
###############################################################################

section "Keyboard layout"

# Two plists: the user one covers the running session, the root-owned system one
# is what the login window - and therefore every session after a restart - uses.
first_source() {
    plutil -p "$1" 2>/dev/null |
        awk '/"AppleEnabledInputSources"/ { f = 1 }
             f && /KeyboardLayout Name/ { sub(/.*=> "/, ""); sub(/"$/, ""); print; exit }'
}

want "user first input source" "$(first_source "$HOME/Library/Preferences/com.apple.HIToolbox.plist")" "U.S."
want "login window first input source" "$(first_source /Library/Preferences/com.apple.HIToolbox.plist)" "U.S."
want "current layout" "$(read_default com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID)" "com.apple.keylayout.US"

###############################################################################
# Shortcuts & input                                                           #
###############################################################################

section "Shortcuts and input"

# Hotkey 64 is Spotlight's Cmd+Space. It has to be off or Raycast's binding
# opens both windows. Changes only apply after a logout.
spotlight_enabled="$(/usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:64:enabled" \
    "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist" 2>/dev/null)"
want "Spotlight Cmd+Space" "$spotlight_enabled" "false"
want "Raycast hotkey" "$(read_default com.raycast.macos raycastGlobalHotkey)" "Command-49"

want "trackpad tracking speed" "$(read_default NSGlobalDomain com.apple.trackpad.scaling)" "1.5"
want "mouse tracking speed" "$(read_default NSGlobalDomain com.apple.mouse.scaling)" "2"

###############################################################################
# Brewfile                                                                    #
###############################################################################

section "Brewfile"

if brew bundle check --file="$HOME/.dotfiles/Brewfile" --no-upgrade &>/dev/null; then
    ok "brew bundle" "satisfied"
else
    bad "brew bundle" "unsatisfied" "run: brew bundle check --file=~/.dotfiles/Brewfile --verbose --no-upgrade"
fi

###############################################################################
# Summary                                                                     #
###############################################################################

if [ "$FAILED" -eq 0 ]; then
    echo -e "\n${GREEN}✓ Everything matches.${NC}"
else
    echo -e "\n${RED}$FAILED check(s) failed.${NC} Fix with ./bootstrap/macos.sh and ./bootstrap/install.sh,"
    echo -e "then log out and back in - keyboard layout and hotkeys are only re-read at login."
fi

[ "$FAILED" -eq 0 ]
