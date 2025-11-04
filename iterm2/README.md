# iTerm2 Configuration

This directory will contain your iTerm2 preferences once configured.

## Setup Instructions

To manage your iTerm2 settings with dotfiles:

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
   - Run `stow iterm2` (creates symlink to preferences folder)
   - Follow step 1 above to point iTerm2 to the folder
   - Your settings will be loaded automatically

## Current Status

Run the setup instructions above to start tracking your iTerm2 configuration.

## Note on Stow

This package doesn't use Stow in the traditional way. Instead:
- The `preferences/` folder stays in your dotfiles
- You manually configure iTerm2 to load/save from this location
- iTerm2 handles the syncing itself

This is iTerm2's recommended approach for syncing preferences.
