# Custom OpenCode updater

The user timer `opencode-custom-update.timer` checks upstream `origin/dev`
daily at 04:00, with up to 30 minutes of jitter. A missed run is caught up
when the user service manager next runs.

The updater uses `~/projects/opencode-custom` as its custom source. It
captures HEAD plus all tracked staged and unstaged changes, merges upstream
in a private detached worktree, and reapplies the local patch with Git's
three-way merge. It does not commit, push, or modify your source checkout.
Untracked source files and unfinished Git operations stop the update.

Each changed candidate must pass frozen-lockfile dependency installation,
TUI and CLI type checks, the TUI test suite, a native terminal-only build,
and executable version/help smoke checks. The Bun version pinned by the
candidate is used, installing it through mise if necessary.

Only a passing build replaces the installed executable, by atomic rename.
Running processes keep their old executable. The previous build is retained
for rollback. Failed updates leave the current build installed and send a
critical desktop notification; successful installations send a normal one.

`~/.local/bin/opencode` uses the managed executable when available and falls
back to the original local build before the first successful update. It
disables upstream's built-in auto-updater for this custom build.

## Commands

```sh
# Run an update now (journal records its output)
systemctl --user start opencode-custom-update.service

# Check merges without building/installing
opencode-custom-update --check

# Installed version and last-run result
opencode-custom-update --status

# Logs and schedule
journalctl --user -u opencode-custom-update.service
systemctl --user list-timers opencode-custom-update.timer

# Restore the previous binary
opencode-custom-update --rollback

# Retry a rolled-back build or rebuild unchanged inputs
opencode-custom-update --force

# Disable automatic updates
systemctl --user disable --now opencode-custom-update.timer

# Test updater isolation, conflict handling, and rollback in temporary repos
python ~/.config/opencode-custom-updater/test-updater.py
```

A rollback holds the rejected input version until upstream or local source
changes, unless `--force` is used. Restart OpenCode to pick up a replaced
binary. Sessions started before this updater was installed use the old
source-tree executable; close and reopen those via `opencode` once.

Updater state, captured patches, worktree, and the latest log live in
`${XDG_STATE_HOME:-~/.local/state}/opencode-custom-updater/`. Executables and
installation metadata live in
`${XDG_DATA_HOME:-~/.local/share}/opencode-custom/bin/`. These generated files
are machine-local and are not managed by chezmoi.

The launcher, updater script, timer/service definitions, and these notes
are managed by chezmoi. On another machine, enable the timer after cloning
the custom source and installing Bun/mise.
