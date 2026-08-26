---
name: allow
description: Grant or revoke a standing, per-repository allow for one harness block-list category, so this repo stops needing a fresh one-shot TERSE_OPS_DANGER_OK=1/TERSE_OPS_COMMIT_OK=1 marker every time. Invoke directly as /terse-ops:allow <category>, /terse-ops:allow list, or /terse-ops:allow revoke <category|all>.
disable-model-invocation: true
argument-hint: "<category> | list | revoke <category|all>"
arguments: [action]
effort: low
---

Valid categories, matching harness's block list exactly: `commit`, `force-push`, `push-delete`, `reset-hard`, `branch-delete`, `clean-force`, `rm-rf`, `terraform-destroy`, `kubectl-delete`, `drop-table`. `no-verify`/`no-gpg-sign` are never valid here, refuse plainly if asked, that block has no override under any mechanism, see harness.

This command is the only way a standing allow gets created. Never write or edit the allow file on your own initiative, even if the user approves the same category repeatedly in one session, see harness's non-inference rule, this is that rule's durable form.

## `/terse-ops:allow <category>`

1. Reject immediately and plainly if `$action` isn't one of the valid categories above, or is `no-verify`/`no-gpg-sign` — list the valid categories, do nothing else.
2. Resolve the repo root with `git rev-parse --show-toplevel`. If that fails (not inside a git repo), say so and stop.
3. Ensure `<root>/.claude/` exists, then append the category as its own line to `<root>/.claude/terse-ops-allow.local.txt` (create the file with a one-line comment header if it doesn't exist yet) — idempotent, don't add a duplicate line if it's already there.
4. Check whether that file is covered by an existing `.gitignore` (`git check-ignore <path>`). If it isn't, say so plainly and suggest adding `.claude/` to `.gitignore` — don't edit `.gitignore` yourself unless the user separately asks for that, this command's job is the allow file, not the ignore rules.
5. Report in one line: category granted, repo root, and that `/terse-ops:allow revoke <category>` undoes it.

## `/terse-ops:allow list`

Read `<root>/.claude/terse-ops-allow.local.txt` if it exists (same repo-root resolution as above) and report the granted categories, one per line, or "none" if the file doesn't exist or has no category lines.

## `/terse-ops:allow revoke <category>`

Remove that one line from the file if present. Report whether it was actually there to remove.

## `/terse-ops:allow revoke all`

Delete the file entirely if it exists. Report plainly.

Follow output's brevity rules for every report here, this is a one-line confirmation, not a summary essay.
