# VSCode Configuration

Stowed into `~/Library/Application Support/Code/User/`:

- `settings.json`
- `keybindings.json`
- `snippets/`

Extensions are declared in the repo root `Brewfile` (`vscode "..."` lines) and
installed by `brew bundle`.

## Machine-specific settings

Anything containing an absolute path, work account ID, or site UUID is
deliberately **not** committed here (this repo is public). Add those directly in
VSCode after stowing — but be aware that `settings.json` is a symlink into the
dotfiles repo, so edits land in git. Check `git diff` before committing:

```bash
cd ~/.dotfiles && git diff -- vscode/
```

Known machine-local keys previously stripped from this file:

- `snowflake.connectionsConfigFile` — absolute path to `~/.snowflake/connections.toml`
- `atlascode.jira.*` — work Jira site/account IDs

## Refreshing the extension list

```bash
code --list-extensions | sed 's/.*/vscode "&"/'
```

Skip locally-installed extensions that aren't on the marketplace
(`pi.pi-vscode-diagnostics`, `quill.quill-vscode`) — `brew bundle` cannot
install them and will report a failure every run.
