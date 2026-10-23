# Git

## Ownership

- Check the branch, `git status --short`, and relevant diffs before editing. Read this file again when the checkout is dirty and before committing.
- Treat unrelated modified, staged, and untracked files as someone else's work. Never overwrite, revert, stash, clean, or discard them.
- If another change overlaps a file, inspect and isolate your edits before staging. A path belongs to your commit only when all included changes are yours.
- Do not create worktrees, switch branches, amend, rebase, or perform destructive history operations unless requested. An explicit user instruction takes precedence.

## Commit Each Coherent Change

1. Inspect the final owned diff and staged paths. Run the smallest relevant checks from [Testing](TESTING.md).
2. Stage only explicit owned paths, for example `git add -- AGENTS.md CLAUDE.md`. Never use `git add .`, `git add -A`, or broad path globs.
3. Commit only those paths with a conventional subject, for example `git commit -m "docs: update agent rules" -- AGENTS.md CLAUDE.md`. Check for mixed ownership before using a whole-file pathspec.
4. Inspect the resulting commit and run `git status --short` again. Leave unrelated work intact.
5. Include the commit hash and subject in the final response. Do not claim the task is complete if the required commit failed.

## Failures And Publishing

- Never use `--no-verify` or otherwise bypass hooks. Fix failures in owned changes and retry; report unrelated blockers without rewriting someone else's work.
- Re-read status and affected files before retrying a failed edit or commit.
- Do not push, publish releases, or change signing credentials unless the user requests that action. A local development signature is not distribution signing or notarisation.
