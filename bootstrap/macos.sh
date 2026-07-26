#!/usr/bin/env bash

# macOS System Preferences Configuration
# Run this script to set up macOS defaults
#
# Note: Some changes require logging out or restarting to take effect
#
# Deliberately NOT `set -e`. Several `defaults` domains are protected by TCC
# (Safari above all) and PlistBuddy errors on keys that don't exist yet on a
# fresh machine. Previously the first such failure aborted the script and
# everything below it silently never ran.

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SKIPPED=()

# Write a default, recording (not aborting on) failures.
d() {
    if ! defaults write "$@" 2>/dev/null; then
        SKIPPED+=("defaults write $1 $2")
        echo -e "  ${RED}✗${NC} $1 $2"
    fi
}

# Set a key in a plist, adding it if it isn't there yet.
plist_set() {
    local file="$1" key="$2" type="$3" value="$4"
    /usr/libexec/PlistBuddy -c "Set ${key} ${value}" "$file" &>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add ${key} ${type} ${value}" "$file" &>/dev/null \
        || SKIPPED+=("PlistBuddy ${key}")
}

echo -e "${GREEN}Configuring macOS defaults...${NC}"

###############################################################################
# General UI/UX                                                               #
###############################################################################

echo -e "\n${YELLOW}Configuring UI/UX...${NC}"

# Ask for sudo up front so the prompt doesn't appear halfway through.
sudo -v || echo -e "  ${YELLOW}No sudo - skipping the few steps that need it.${NC}"

# Disable the sound effects on boot
# (nvram writes fail on Apple Silicon when Secure Boot is at Full Security.)
sudo nvram SystemAudioVolume="%00" 2>/dev/null || SKIPPED+=("nvram SystemAudioVolume")
d NSGlobalDomain com.apple.sound.uiaudio.enabled -int 0

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                #
###############################################################################

echo -e "\n${YELLOW}Configuring input devices...${NC}"

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool FALSE
defaults write com.apple.AppleMultitouchTrackpad "FirstClickThreshold" -int "1"

# Tracking speed. These are the two floats the System Settings sliders write;
# a fresh machine starts at 0.6875 (trackpad) which feels sluggish.
d NSGlobalDomain com.apple.trackpad.scaling -float 1.5
d NSGlobalDomain com.apple.mouse.scaling -float 2

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# fn keys does nothing
defaults write com.apple.HIToolbox AppleFnUsageType -int "0"

###############################################################################
# Input sources                                                               #
###############################################################################

echo -e "\n${YELLOW}Configuring input sources...${NC}"

# U.S. first, Slovak second. The order is the point: macOS activates the first
# enabled layout when a session starts, so a machine whose setup assistant
# picked Slovak keeps logging in with a Slovak layout no matter what the menu
# bar showed last. Both lists have to agree - AppleEnabledInputSources is what
# is available, AppleSelectedInputSources is what is active.
d com.apple.HIToolbox AppleEnabledInputSources -array \
    '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>0</integer><key>KeyboardLayout Name</key><string>U.S.</string></dict>' \
    '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>-11013</integer><key>KeyboardLayout Name</key><string>Slovak</string></dict>' \
    '<dict><key>Bundle ID</key><string>com.apple.CharacterPaletteIM</string><key>InputSourceKind</key><string>Non Keyboard Input Method</string></dict>' \
    '<dict><key>Bundle ID</key><string>com.apple.PressAndHold</string><key>InputSourceKind</key><string>Non Keyboard Input Method</string></dict>'

d com.apple.HIToolbox AppleSelectedInputSources -array \
    '<dict><key>Bundle ID</key><string>com.apple.PressAndHold</string><key>InputSourceKind</key><string>Non Keyboard Input Method</string></dict>' \
    '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>0</integer><key>KeyboardLayout Name</key><string>U.S.</string></dict>'

d com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID -string "com.apple.keylayout.US"

# Per-app input source memory. With this on, macOS remembers a layout per
# application and silently restores it when that app comes forward, which reads
# as "the layout flips back to Slovak on its own". One global layout instead.
d com.apple.HIToolbox AppleGlobalTextInputProperties -dict \
    TextInputGlobalPropertyPerContextInput -bool false

# The user-level plist above only covers an already-running session. Two more
# places decide what the keyboard is *before* the session exists, and neither
# inherits from the user plist:
#
#   1. /Library/Preferences/com.apple.HIToolbox.plist - the login window, and
#      therefore every session started from it. The setup assistant fills this
#      from whatever region was picked during onboarding.
#   2. The Preboot volume - the FileVault password screen shown at boot, before
#      macOS is even up. It keeps its own copy and ignores (1) until resynced.
#
# U.S. is written as the only entry: there is nothing to type at a login prompt
# that needs a second layout, and a single entry means nothing can flip.
HITOOLBOX_SYSTEM="/Library/Preferences/com.apple.HIToolbox"

# `sudo -v` was called at the top, but the timestamp can be cold by now (long
# script, or the caller declined then). Re-prompt rather than skip silently -
# skipping here is invisible in the summary and leaves the login screen wrong.
if ! sudo -n true 2>/dev/null; then
    echo -e "  ${YELLOW}sudo needed for the login window and pre-boot keyboard layout.${NC}"
    sudo -v || true
fi

if sudo -n true 2>/dev/null; then
    US_LAYOUT='<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>0</integer><key>KeyboardLayout Name</key><string>U.S.</string></dict>'

    # Errors are deliberately NOT redirected to /dev/null here. Silencing them is
    # why "I ran it with sudo and the login screen is still wrong" was impossible
    # to diagnose: the write can fail, or appear to succeed and be discarded.
    sudo defaults write "$HITOOLBOX_SYSTEM" AppleEnabledInputSources -array "$US_LAYOUT"
    sudo defaults write "$HITOOLBOX_SYSTEM" AppleSelectedInputSources -array "$US_LAYOUT"
    sudo defaults write "$HITOOLBOX_SYSTEM" AppleCurrentKeyboardLayoutInputSourceID -string "com.apple.keylayout.US"
    sudo defaults write "$HITOOLBOX_SYSTEM" AppleDefaultAsciiInputSource -dict \
        InputSourceKind -string "Keyboard Layout" \
        "KeyboardLayout ID" -int 0 \
        "KeyboardLayout Name" -string "U.S."

    # cfprefsd caches this file and can rewrite it from memory, undoing the
    # writes above. Flush it so what is on disk is what was just written.
    sudo killall cfprefsd 2>/dev/null || true

    # Read the file back rather than trusting exit codes.
    system_layouts="$(sudo plutil -p "${HITOOLBOX_SYSTEM}.plist" 2>/dev/null |
        awk '/"AppleEnabledInputSources"/ { f = 1 }
             f && /KeyboardLayout Name/ { sub(/.*=> "/, ""); sub(/"$/, ""); print }' |
        sort -u | paste -sd, -)"

    if [ "$system_layouts" = "U.S." ]; then
        echo -e "  ${GREEN}✓${NC} login window keyboard layout (U.S. only)"
    else
        echo -e "  ${RED}✗${NC} login window layout is now: ${system_layouts:-<empty>}"
        SKIPPED+=("login window keyboard layout - file still reads: ${system_layouts:-<empty>}")
    fi

    # With FileVault on, the password screen at boot runs before macOS and reads
    # its own copy of the above from the Preboot volume. Without this resync the
    # login window is fixed and the boot screen is still wrong.
    if fdesetup status 2>/dev/null | grep -q 'FileVault is On'; then
        echo -e "  ${YELLOW}FileVault is on - syncing Preboot volume...${NC}"
        if sudo diskutil apfs updatePreboot /; then
            echo -e "  ${GREEN}✓${NC} pre-boot keyboard layout synced"
        else
            SKIPPED+=("pre-boot keyboard layout (diskutil apfs updatePreboot failed)")
        fi
    else
        echo -e "  ${GREEN}✓${NC} FileVault off - no Preboot volume to sync"
    fi
else
    SKIPPED+=("login window + pre-boot keyboard layout (no sudo)")
fi

###############################################################################
# Display scaling                                                             #
###############################################################################

echo -e "\n${YELLOW}Configuring display scaling...${NC}"

# There is no `defaults` key for the scaled resolution - it lives in
# WindowServer state keyed by display UUID - so this needs displayplacer.
#
# The wanted mode is the panel's default: exactly half the native pixel
# dimensions with HiDPI on (3024x1964 -> 1512x982). Any bigger logical size is
# what System Settings calls "More Space", and it makes every point-sized font
# render smaller - iTerm2's 14pt above all, which is what "the font is broken"
# usually turns out to be.
#
# Built-in screen only. On an external panel "native / 2" is not necessarily the
# mode macOS calls Default, so those are left alone.
set_default_scaling() {
    local id="$1" w="$2" h="$3"
    [ -n "$id" ] && [ "$w" -gt 0 ] || return 0

    local target="$((w / 2))x$((h / 2))"
    if displayplacer "id:${id} res:${target} scaling:on" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} built-in display at ${target} (native ${w}x${h})"
    else
        SKIPPED+=("display scaling ${target} for ${id}")
    fi
}

if command -v displayplacer &>/dev/null; then
    dp_id=""
    dp_builtin=0
    dp_w=0
    dp_h=0

    # `displayplacer list` prints one block per screen: a persistent id, a Type
    # line, then every supported mode. The native resolution is simply the
    # largest mode in the block.
    while IFS= read -r line; do
        case "$line" in
            "Persistent screen id: "*)
                [ "$dp_builtin" -eq 1 ] && set_default_scaling "$dp_id" "$dp_w" "$dp_h"
                dp_id="${line#Persistent screen id: }"
                dp_builtin=0
                dp_w=0
                dp_h=0
                ;;
            Type:*built?in*)
                dp_builtin=1
                ;;
            *"mode "*res:*)
                res="${line#*res:}"
                res="${res%% *}"
                mode_w="${res%%x*}"
                mode_h="${res##*x}"
                # Compare total pixels, not width: the panel also advertises
                # letterboxed modes at full width (3024x1890 next to the real
                # 3024x1964), and the widest-wins version of this picked those.
                case "$mode_w$mode_h" in
                    *[!0-9]*) continue ;;
                esac
                if [ $((mode_w * mode_h)) -gt $((dp_w * dp_h)) ]; then
                    dp_w="$mode_w"
                    dp_h="$mode_h"
                fi
                ;;
        esac
    done < <(displayplacer list 2>/dev/null)
    [ "$dp_builtin" -eq 1 ] && set_default_scaling "$dp_id" "$dp_w" "$dp_h"
else
    SKIPPED+=("display scaling (displayplacer missing - run 'brew bundle' first)")
fi

###############################################################################
# Spotlight (Raycast owns Cmd+Space)                                          #
###############################################################################

echo -e "\n${YELLOW}Freeing up Cmd+Space for Raycast...${NC}"

# Hotkey 64 is "Show Spotlight search". Raycast binds Cmd+Space as well, so
# leaving it enabled opens both windows on every press. Hotkey 65 (Cmd+Opt+Space,
# the Finder search window) is left alone.
#
# Only :enabled is flipped - System Settings keeps the key combination in
# :value:parameters, and wiping the whole dict would leave the shortcut
# unassigned if it is ever re-enabled. cfprefsd caches this plist, hence the
# reads around the edit.
defaults read com.apple.symbolichotkeys &>/dev/null
HOTKEYS_PLIST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
if [ -f "$HOTKEYS_PLIST" ]; then
    plist_set "$HOTKEYS_PLIST" ":AppleSymbolicHotKeys:64:enabled" bool false
    defaults read com.apple.symbolichotkeys &>/dev/null
    echo -e "  ${YELLOW}Takes effect after a logout - WindowServer holds the old binding.${NC}"
else
    SKIPPED+=("Spotlight hotkey (no symbolichotkeys plist yet - uncheck it in Settings → Keyboard → Keyboard Shortcuts → Spotlight)")
fi

###############################################################################
# Finder                                                                      #
###############################################################################

echo -e "\n${YELLOW}Configuring Finder...${NC}"

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use icons view and Sort by name by default (and snap to grid)
defaults write com.apple.finder FXPreferredViewStyle -string "icnv"
defaults write com.apple.finder FXArrangeGroupViewBy -string "Name"

# Icon view arrange-by settings. These keys don't exist on a fresh machine, so
# fall back to Add. cfprefsd also caches this plist, hence the flush below.
defaults read com.apple.finder &>/dev/null
FINDER_PLIST="$HOME/Library/Preferences/com.apple.finder.plist"
if [ -f "$FINDER_PLIST" ]; then
    plist_set "$FINDER_PLIST" ":DesktopViewSettings:IconViewSettings:arrangeBy" string name
    plist_set "$FINDER_PLIST" ":StandardViewSettings:IconViewSettings:arrangeBy" string name
    plist_set "$FINDER_PLIST" ":FK_StandardViewSettings:IconViewSettings:arrangeBy" string grid
    defaults read com.apple.finder &>/dev/null
else
    SKIPPED+=("Finder icon view arrangeBy (no plist yet - open Finder once and rerun)")
fi

# Show the ~/Library folder
chflags nohidden ~/Library

# Show the /Volumes folder
sudo chflags nohidden /Volumes 2>/dev/null || SKIPPED+=("chflags nohidden /Volumes")

###############################################################################
# Dock, Dashboard, and hot corners                                           #
###############################################################################

echo -e "\n${YELLOW}Configuring Dock...${NC}"

# Set the icon size of Dock items
defaults write com.apple.dock tilesize -int 48

# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Don't animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0.1

# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0.5

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

###############################################################################
# Safari & WebKit                                                             #
###############################################################################

echo -e "\n${YELLOW}Configuring Safari...${NC}"

# Safari's preferences live inside its sandbox container and are protected by
# TCC. Writing them fails with "Could not write domain com.apple.Safari" unless
# the terminal has Full Disk Access, and several of the old keys no longer do
# anything on current macOS anyway.
#
# Probe with a real write: the container plist is readable by its owner even
# when TCC blocks writes, so a readability check gives a false positive. Only
# attempting a write tells the truth.
if defaults write com.apple.Safari DotfilesWriteProbe -bool true 2>/dev/null; then
    defaults delete com.apple.Safari DotfilesWriteProbe 2>/dev/null

    d com.apple.Safari UniversalSearchEnabled -bool false
    d com.apple.Safari SuppressSearchSuggestions -bool true
    d com.apple.Safari ShowFullURLInSmartSearchField -bool true
    d com.apple.Safari IncludeDevelopMenu -bool true
    d com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    d com.apple.Safari SendDoNotTrackHTTPHeader -bool true
else
    echo -e "  ${YELLOW}Skipping Safari: its prefs are TCC-protected.${NC}"
    echo -e "  ${YELLOW}Grant Full Disk Access to your terminal and rerun, or set these by hand:${NC}"
    echo -e "  ${YELLOW}  Settings → Search: uncheck search-engine suggestions${NC}"
    echo -e "  ${YELLOW}  Settings → Advanced: 'Show full website address' + 'Show features for web developers'${NC}"
    SKIPPED+=("Safari (needs Full Disk Access)")
fi

###############################################################################
# Terminal                                                                    #
###############################################################################

echo -e "\n${YELLOW}Configuring Terminal...${NC}"

# NOTE: domain is com.apple.Terminal with a capital T. The lowercase spelling
# this script used to have silently created a junk domain that nothing reads.

# Only use UTF-8 in Terminal.app
d com.apple.Terminal StringEncodings -array 4

# Enable Secure Keyboard Entry in Terminal.app
d com.apple.Terminal SecureKeyboardEntry -bool true

###############################################################################
# Activity Monitor                                                            #
###############################################################################

echo -e "\n${YELLOW}Configuring Activity Monitor...${NC}"

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Screenshot                                                                  #
###############################################################################

echo -e "\n${YELLOW}Configuring Screenshots...${NC}"

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Done                                                                        #
###############################################################################

if [ ${#SKIPPED[@]} -eq 0 ]; then
    echo -e "\n${GREEN}✓ macOS defaults configured!${NC}"
else
    echo -e "\n${GREEN}✓ macOS defaults configured${NC}, with ${#SKIPPED[@]} skipped:"
    for s in "${SKIPPED[@]}"; do
        echo -e "  ${YELLOW}-${NC} $s"
    done
fi

echo -e "\n${YELLOW}Note: Some changes require a logout/restart to take effect.${NC}"
echo -e "Kill affected applications to apply changes now? (y/n)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    for app in "Activity Monitor" \
        "Dock" \
        "Finder" \
        "SystemUIServer"; do
        killall "${app}" &> /dev/null || true
    done
    echo -e "${GREEN}Applications restarted${NC}"
fi

echo -e "\n${GREEN}Done!${NC}"
