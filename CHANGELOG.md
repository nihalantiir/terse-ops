# Changelog

## 0.4.0 - 2026-08-26

- Hook: added `terraform destroy`, `kubectl delete`, and raw `DROP TABLE` to the destructive-command block list
- Hook: added a Windows-safe path — a PowerShell twin of `block-dangerous.sh` so the harness still runs without Git Bash/WSL present
- Hook: `git commit` block now has a scoped, explicit override for the one turn the user directly asks for a commit (see `harness`)
- Skill: `output` documents an on-request maximum-compression style, distinct from the default (no persistent mode/state)
- README: added a "Role of terse-ops" section on composing with domain-specific plugins

## 0.3.0 - 2026-08-25

- Added `budget` skill: never trigger metered/billed/out-of-session usage on your own initiative
- Added `economy` skill: keep tool-call and delegation overhead proportional to the task
- Added `reasoning` skill: `effort` field scope and limits, grounded in the actual documented behavior (not assumed)
- `/terse-ops:route` runs at `effort: low`
- README: removed CLI install instructions in favor of an "Updating" section covering `/plugin marketplace update` + `/plugin install`, identical in the CLI and the claude.ai/code web app

## 0.2.0 - 2026-08-25

- Added `research` skill: verify time-sensitive external facts instead of asserting from stale training data
- Added `researcher` agent (web/external lookup) and `architect` agent (deep-reasoning planning pass)
- Hook: added `git branch -D`, `git clean -f` (any flag combo), and `git push --delete` to the block list
- Added `/terse-ops:route` and `/terse-ops:verify-now` — explicit-invoke-only commands
- Added `evals/` — `claude plugin eval` cases for the hook blocks and `output`'s brevity rule (early access, not yet runnable) plus a manual-trigger CI workflow

## 0.1.0 - 2026-08-25

- Initial scaffold: `output`, `orchestrate`, `verify`, `harness`, `auto`, `fail-fast` skills
- `scout`, `builder`, `checker` agents
- `PreToolUse` hook blocking `git commit`, `git push --force`, `--no-verify`/`--no-gpg-sign`, `git reset --hard`, `rm -rf`
