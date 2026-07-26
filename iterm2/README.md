# iTerm2 Configuration

This directory will contain your iTerm2 preferences once configured.

## Setup

`bootstrap/install.sh` does this automatically:

```bash
defaults write com.googlecode.iterm2 PrefsCustomFolder -string ~/.dotfiles/iterm2/preferences
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
```

**iTerm2 must be quit when this runs** - it overwrites its prefs on exit and will
clobber the change otherwise. The installer detects a running iTerm2 and tells
you to do it by hand instead.

## Manual fallback

1. **Configure iTerm2 to use this folder**:
   - Open iTerm2
   - Go to: **Preferences → General → Preferences**
   - Check ☑️ **"Load preferences from a custom folder or URL"**
   - Click **"Browse"** and select: `~/.dotfiles/iterm2/preferences`
   - Check ☑️ **"Save changes to folder when iTerm2 quits"** (optional, for auto-save)

2. **Your settings are now tracked**:
   - iTerm2 will create `com.googlecode.iterm2.plist` in the preferences folder
   - Any changes you make will be saved there
   - Git will track your iTerm2 configuration

3. **On a new machine**:
   - Follow step 1 above to point iTerm2 to `~/.dotfiles/iterm2/preferences`
   - Your settings will be loaded automatically

## Note on Stow

This package is deliberately **not** in the `PACKAGES` array in
`bootstrap/install.sh`. Instead:
- The `preferences/` folder stays in your dotfiles
- You manually configure iTerm2 to load/save from this location
- iTerm2 handles the syncing itself

This is iTerm2's recommended approach for syncing preferences.
