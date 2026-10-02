---
name: github-push
description: Use whenever the user asks to push, commit and push, publish changes, or upload a repository to GitHub. Review the intended changes, write concise change-focused commit messages without AI attribution, and verify the push.
---

# GitHub push

## Commit message preference

Write commit messages about what changed in the project. Follow the repository's
existing style and use concise, concrete language.

- Do not mention AI, assistants, models, agents, prompts, or generation tools as
  the source of the work.
- Do not add generated-by lines, assistant signatures, or AI co-author trailers.
- If the project itself involves AI, describe relevant functionality accurately;
  the preference concerns attribution of the editing work.
- Use the existing Git author identity. Do not change Git configuration, invent
  authorship claims, or remove existing attribution or team credits from files.

Examples:

- `Improve mission-control dashboard and fire animations`
- `Fix queued-task test timing`
- `Add project reports and demo recording`

## Workflow

1. Identify the repository and intended scope from the request and conversation.
   A request to push completed work authorizes committing that work when needed.
2. Inspect `git status`, `git diff`, `git log --oneline -10`, the current branch,
   upstream tracking, and remotes. Read applicable repository instructions.
3. Review untracked files as well as tracked changes. Preserve unrelated work;
   stage only intended files, and never commit credentials or secrets.
4. Run checks appropriate to the changes. Reuse successful checks from the
   current session when no subsequent change invalidates them. For large assets,
   confirm they fit the remote's file-size limits.
5. Fetch the intended remote and check for divergence. Resolve ordinary push
   blockers without discarding work. Do not force-push, rewrite existing commits,
   amend, skip hooks, or change Git configuration unless explicitly requested.
6. Stage explicit paths, inspect the staged diff and summary, and commit using
   the message preference above. If hooks reject the commit, fix the issue and
   create a new commit without bypassing the hooks.
7. Push the current branch to its intended upstream. If no upstream is set,
   confirm the target from the repository context before setting one.
8. Verify the local commit matches the remote branch after pushing. Report the
   repository URL, branch, commit hash, and any remaining uncommitted changes.

Use `gh` for GitHub-specific operations such as repository lookup, pull requests,
or checks. Creating a pull request is separate from pushing; do it only when
requested. Do not push unrelated configuration repositories as a side effect.
