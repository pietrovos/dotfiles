---
name: chezmoi-tracking
description: Use whenever editing a user dotfile or configuration file to add newly managed portable targets to chezmoi after the edit.
---

# Chezmoi Tracking

After editing a portable user configuration or dotfile, check whether its
target is managed with `chezmoi source-path <target>`.

- If it is not managed, run `chezmoi add <target>` before finishing the task.
- If it is already managed, ensure its source reflects the edit with `chezmoi diff <target>`.
- Do not add intentionally machine-local settings: themes, backgrounds,
  monitors, input or sensitivity, autostart, environment, portal settings,
  or credentials.
- Do not add targets excluded by `~/.local/share/chezmoi/.chezmoiignore`.
- Do not commit or push unless the user asks.

Apply this rule to every user configuration edit, including files outside
`~/.config/`, unless an exclusion above applies.
