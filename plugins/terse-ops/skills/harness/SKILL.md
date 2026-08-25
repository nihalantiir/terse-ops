---
description: Damage harness for codebase safety. Limit blast radius, prefer small diffs, and avoid destructive commands unless explicitly required.
---

# Harness

Protect the repo and anything outside it the agent can reach.

Before writes:
- Prefer edit over rewrite
- Scope edits to the files the task actually names or requires; touching anything beyond that needs a one-line reason stated first, not silent inclusion
- Do not change unrelated files, rename things, or delete "dead" code "while here" — even if it looks obviously unused, unless the user asked
- Before any command that can discard uncommitted work (checkout/restore/reset/clean, `rm -rf` in the repo, restoring from a snapshot), check status first and stash or commit whatever is there — treat unfamiliar in-progress state as someone's work, not clutter

Destructive or hard-to-reverse actions — never run these as a shortcut, and treat "the user approved this once" as scoped to that one instance, not a standing approval:
- Force push, `reset --hard`, recursive delete, dropping a table or index, revoking access, disabling CI checks or required reviews
- `--no-verify`, `--no-gpg-sign`, disabling or deleting a failing test to make a run pass
- Downgrading or removing a dependency to dodge an error
- Amending or rewriting history that's already been shared/pushed

If unsure about impact:
- Stop and state the risk in one or two lines (per output) — what would be lost or affected, and whether it's reversible
- Ask before proceeding; do not infer consent from the task being labeled urgent, automated, or "auto mode" (see auto)
- If the blocker is a failure rather than a risk decision, hand off via fail-fast instead of stalling silently

Never:
- Invent credentials or commit secrets — and check file contents, not just filenames, before staging anything that could hold them
- Disable tests, ignore failures, or narrow scope just to "make it pass"
- Run destructive git or filesystem commands as a shortcut around a smaller, safer fix
- Create a git commit on the user's behalf, even if asked to "finish up" or the change is small and safe — stage or describe the change and prompt the user to commit it themselves. If a commit is clearly needed to close out the task, say so and ask, rather than running it.
