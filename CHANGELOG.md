# Changelog

## 0.6.0 - 2026-08-26

- Fixed a real cross-segment false-positive bug in both hook scripts: every pattern check previously scanned the *entire* raw command line, so a compound command (`&&`/`;`/`|`) could trip a rule meant for a completely different clause (e.g. `git log && echo "committed"` blocked as a commit attempt). All checks now run per-segment.
- Fixed three long-flag substring false positives found via testing: `git branch --set-upstream-to=origin/DEV`, `git clean --exclude=foo.log`, and `rm --preserve-root --one-file-system` were each incorrectly blocked because a long flag's own argument text happened to contain a trigger letter.
- Narrowed `kubectl delete` to allow plain pod deletes (a controller reschedules them — closer to a restart than a deletion) while still blocking everything else; `--all-namespaces` still blocks even for pods.
- Added `compose` skill: how terse-ops behaves alongside domain-specific plugins — it owns voice/routing/safety/spend, never the domain work; safety rules win on conflict.
- Preloaded `budget`, `economy`, and `compose` onto all 5 agents' `skills:` frontmatter (previously only `output`/`harness`/`fail-fast`/`research` were preloaded — the others were still technically discoverable via the Skill tool, but not guaranteed in context at agent startup).
- Tagged as `terse-ops--v0.6.0`.

## 0.5.0 - 2026-08-26

- Added `/terse-ops:status` — reports current phase, anything the harness hook has blocked this session, and open items, read from the conversation itself
- Evals: added cases for the `terraform destroy`, `kubectl delete`, and `DROP TABLE` hook blocks added in 0.4.0

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
