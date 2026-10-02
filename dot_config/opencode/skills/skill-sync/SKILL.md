---
name: skill-sync
description: Use whenever creating, installing, adding, importing, or renaming a user-global skill in OpenCode or Claude Code. Keep custom skills shared by linking Claude Code's skill folder to the OpenCode original and tracking both paths in chezmoi.
---

# Share new skills between OpenCode and Claude Code

Apply this workflow before finishing any task that adds a user-global skill.

## Shared layout

- Store custom skill originals in `~/.config/opencode/skills/<name>/`.
- Create a relative directory symlink at `~/.claude/skills/<name>` pointing to
  `../../.config/opencode/skills/<name>`.
- Keep `SKILL.md` and all supporting files together in the original directory.
  Editing through either path then updates the same files.
- Package-managed skills such as `omarchy` and `diagnose-crash` already have
  shared links to their package originals. Preserve those links.
- This workflow covers user-global skills. Keep project-scoped skills in their
  project unless the user asks to make them global. Built-in skills without local
  files cannot be shared through a symlink.

## Workflow

1. Inspect both skill locations, including existing symlinks, before writing.
   Use the skill's actual folder name and matching frontmatter `name`.
2. Create or install new custom skills in the OpenCode original directory.
   If a skill was just created as a real directory under `~/.claude/skills/`,
   relocate that whole directory to the OpenCode location, preserving its
   supporting files. First check that the destination is absent.
3. Create the Claude Code link after confirming its parent directory exists.
   For example, for a skill named `my-skill`:

   ```bash
   ln -s "../../.config/opencode/skills/my-skill" "$HOME/.claude/skills/my-skill"
   ```

   If the existing link already resolves to the intended original, leave it in
   place. Do not overwrite a different link or directory. Inspect any collision;
   consolidate identical copies only after comparing every file, and ask the
   user how to resolve differing content before replacing it. Avoid symlink
   loops and dangling links.
4. Track both the original directory and the symlink in chezmoi:

   ```bash
   chezmoi add "$HOME/.config/opencode/skills/my-skill" "$HOME/.claude/skills/my-skill"
   ```

   Honor the exclusions in `chezmoi-tracking`. When converting a previously
   tracked copy to a symlink, remove only that target's obsolete directory entry
   from chezmoi with `chezmoi forget` before adding the link. This forgets source
   tracking; it does not remove the live target. Do not commit or push unless asked.
5. Verify that `SKILL.md` is readable through both paths and refers to the same
   file, and that supporting files are accessible through the link. Confirm
   chezmoi tracks the Claude Code target as a symlink and that `chezmoi diff`
   for both paths is empty.
6. For a rename, update the original folder, frontmatter name, Claude Code link,
   and chezmoi entries together. Remove an obsolete link only after verifying
   that it belongs to the renamed skill.
7. Tell the user to quit and restart OpenCode and start a new Claude Code session
   so the newly added skill is discovered.

These instructions run when an agent adds a skill. They are not a filesystem
watcher; skills added manually outside an agent session need this workflow too.
