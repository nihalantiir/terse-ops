# Changelog

## 1.1.0 - 2026-08-26

- Tagged as `terse-ops--v1.0.0`.
- Removed the Mermaid architecture diagram from the root README (looked bad rendered).
- Added a wiki [Prompt Guide](https://github.com/nihalantiir/terse-ops/wiki/Prompt-Guide) page: `CLAUDE.md` phrase-to-command mappings so plain language ("verify that", "watch spend", "run autonomously") triggers the real on-demand skill via its actual `/terse-ops:<name>` command, plus a session-starter prompt for one-off sessions. No plugin code changes — `CLAUDE.md` is read in full every session, so this reuses that existing mechanism rather than reverting 0.7.0's ambient-footprint thinning.
- Simplifying pass now that the wiki is the canonical deep reference: trimmed the plugin README's "Known limitations" and "Hooks" sections from full prose to short summaries linking to the wiki's `Known Limitations` and `Hooks and Safety` pages (the block-list table stays inline, it's a useful quick reference). Refreshed stale skill/page counts across the wiki (`allow` wasn't reflected in a couple of intro lines).
- This is the final release in this push. From here: documented, deliberate trade-offs only, no known open bugs.

## 1.0.0 - 2026-08-26

- Tagged as `terse-ops--v0.12.0`.
- First stable release. What that means concretely: hook-enforced safety with both a one-shot override and a durable, per-repo standing allow (`/terse-ops:allow`); 46 ungated, CI-verified hook test cases plus a parity check between the two hand-synced interpreters; a manifest-validation CI job; a published wiki (9 pages, footer, two architecture/decision diagrams) alongside both READMEs; and no known open bugs, only documented, deliberate trade-offs (see the READMEs' "Known limitations" and the wiki's Known Limitations page).
- Final consistency pass: both READMEs and the wiki now reflect the 46-case suite, the `validate`/`parity` CI jobs, and the standing-allow's session-root scoping gap discovered while shipping 0.11.0/0.12.0. Root README gained a `tests/` bullet that was missing (only `evals/` was listed before, despite `tests/` being the suite that actually runs).
- No functional changes beyond the consistency pass above — this release is about the state being verified and documented as stable, not new behavior.

## 0.12.0 - 2026-08-26

- Tagged as `terse-ops--v0.11.0`.
- CI: added a `validate` job running `claude plugin validate` on every push/PR (previously only a documented local dev step), and a `parity` job that runs both `run-tests.sh` and `run-tests.ps1` on one runner and fails if their reported totals ever diverge, catching the two hand-synced hook scripts (or their test suites) drifting apart.
- Fixed a real test-isolation bug found while re-running the suite locally: the baseline `run_case`/`Invoke-Case` helpers didn't scaffold their own directory, so a real standing allow granted in the repo the suite is run from (see 0.11.0) could leak into cases expecting a plain block. Both now run from a fresh, `.git`-free temp directory, matching how `run_case_repo`/`Invoke-CaseInRepo` were already isolated. CI was never affected (fresh checkout, no local allow file ever exists there), but local runs now behave identically regardless of ambient state.
- Discovered and documented a real scoping nuance in the standing-allow mechanism while using it for real: the hook checks the allow file from its own launch directory, which tracks the Claude Code session's project root, not any `cd` embedded earlier in the same compound command. `cd other-repo && git commit ...` as one Bash call is checked against the session's project root, not `other-repo`. Documented in `harness` and the wiki's Known Limitations page as an accepted imprecision, the same category as per-segment splitting not understanding quoting.
- Added `.gitattributes` (`* text=auto eol=lf`) — `block-dangerous.sh` is the actual safety boundary, and a Windows contributor with `core.autocrlf=true` could otherwise silently get CRLF line endings in it on checkout.
- Added the missing `keywords` array to `.claude-plugin/marketplace.json` (present in `plugin.json`, absent here), and added `hooks`/`delegation` to both.
- Added a Mermaid architecture diagram to the root README and a decision-flow diagram to the wiki's Hooks and Safety page (GitHub renders Mermaid natively in both).
- Added a wiki footer (`_Footer.md`, rendered on every page automatically) linking back to Home, the repo, and Releases.

## 0.11.0 - 2026-08-26

- Tagged as `terse-ops--v0.10.0`.
- Added a standing, per-repository allow mechanism: `/terse-ops:allow <category>` grants a durable exception for one hook block-list category (`commit`, `force-push`, `push-delete`, `reset-hard`, `branch-delete`, `clean-force`, `rm-rf`, `terraform-destroy`, `kubectl-delete`, `drop-table`) so it stops needing a fresh `TERSE_OPS_DANGER_OK=1`/`TERSE_OPS_COMMIT_OK=1` marker every time in that repo. `/terse-ops:allow list`/`revoke <category|all>` to inspect or undo. Backed by `.claude/terse-ops-allow.local.txt` at the repo root (walked up from cwd, no `git` subprocess in the hot path), not committed by default. `--no-verify`/`--no-gpg-sign` has no path through this, structurally, same as the one-shot marker.
- This closes a real friction point: the existing one-shot marker, used correctly with genuine explicit consent, could still get blocked by a separate Claude Code platform safety layer unrelated to this plugin. The standing allow gives a durable alternative for repeat cases in one's own repo, set up only via explicit, deliberate command, never inferred.
- Extended both hook scripts (`block-dangerous.sh`/`.ps1`) with the repo-root walk-up and category-file check; every overridable block's denial message now names the exact `/terse-ops:allow <category>` to run.
- Added 9 new test cases to both `tests/run-tests.sh` and `run-tests.ps1` (46 total, up from 37) covering the grant, category scoping, `--no-verify`'s absolute exemption, an inert file outside any repo, the nested-subdirectory walk-up, and revoke actually restoring the block. Verified passing 46/46 on both interpreters, plus a live end-to-end check in this repo (grant → plain commit went through with no marker → force-push still blocked under a commit-only grant → revoke → blocked again).
- Updated `harness`, `status`, both READMEs, and the wiki (`Hooks and Safety`, `Configuration`, `Known Limitations`, `Skills Reference`) to describe the new mechanism.

## 0.10.0 - 2026-08-26

- Tagged as `terse-ops--v0.9.0`.
- Added `plugins/terse-ops/tests/` — an ungated, dependency-free shell/PowerShell test suite (`run-tests.sh`/`run-tests.ps1`) that feeds `block-dangerous.sh`/`.ps1` the same PreToolUse JSON payload shape Claude Code sends and asserts the exit code (0 allow, 2 block) across 37 cases: every hard-blocked command, every known false-positive trap from past bugs (long flags containing a trigger letter, cross-segment word leakage), and the override markers including the two absolute blocks refusing to be overridden. Verified passing 37/37 on both interpreters.
- Added `.github/workflows/hook-tests.yml` — runs both suites on every push/PR, no API key or cost, complementing the gated `claude plugin eval` workflow.
- Cross-linked `tests/` and `evals/` in both READMEs so it's clear which suite checks what (hook exit code vs. agent-reported behavior).

## 0.9.0 - 2026-08-26

- Tagged as `terse-ops--v0.8.0`.
- Fixed the "Updating" instructions in both READMEs: the documented flow said to follow `/plugin marketplace update` with a `/plugin install` reinstall, but marketplace update already bumps the installed plugin on its own. The correct path is `/plugin marketplace update` then `/reload-plugins` (or a restart) if one is needed.
- Fixed `LICENSE`: it had a stray markdown heading and an unclosed code fence wrapped around the actual license text, a copy-paste artifact. Now plain MIT license text.
- Root README: replaced the "not related to X/Y/Z" disclaimer with a direct product description, removed em dashes throughout for plainer prose, and added a custom SVG banner (`docs/banner.svg`, Anthropic-orange accent) plus shields.io badges for license, latest tag, open issues, and Claude Code plugin status.
- Root README: added a contents line and broke the single "Role of terse-ops" paragraph into scannable owns/doesn't-own/on-conflict bullets.

## 0.8.0 - 2026-08-26

- Tagged as `terse-ops--v0.7.0`.
- README: added a "Known limitations" section recording three accepted design trade-offs so they don't get re-litigated: `mode`/`status` are skill-enforced (no hook or SessionStart state behind them, unlike `harness`); no durable state store, so mode/phase tracking can drift after a long session or a context compaction; and the CLAUDE.md workaround for making an opt-in skill act "always on" for a project without editing the plugin itself.

## 0.7.0 - 2026-08-26

- Fixed real casing bug: the GitHub owner is `nihalantiir` (lowercase, confirmed via the GitHub API), but every file referenced `Nihalantiir`. Fixed in both manifests and both READMEs' install commands; left the LICENSE copyright name alone since that's a display-name choice, not a functional identifier.
- Added output compression levels as first-class UX: `clean` (default)/`tight`/`grunt`, set for the session via `/terse-ops:mode`, replacing the earlier one-off "on-request" wording.
- Added `/terse-ops:solo` — turns off delegation to subagents for the rest of the session.
- Generalized the commit-only override marker: `TERSE_OPS_DANGER_OK=1` now works as a scoped, one-shot bypass on every overridable hook block (force-push, `reset --hard`, `rm -rf`, `branch -D`, `clean -f`, `terraform destroy`, `kubectl delete`, `DROP TABLE`, `push --delete`). `--no-verify`/`--no-gpg-sign` stays absolute, no override, ever.
- Thinned the always-on skill set: `output`, `harness`, `fail-fast`, `economy`, `compose` stay auto-triggered; `orchestrate`, `verify`, `auto`, `research`, `budget`, `reasoning` became explicit-invoke-only (`disable-model-invocation: true`) — each now needs `/terse-ops:<name>` to take effect in a session, reducing the ambient skill-listing footprint from 11 entries to 5. **This is a real behavior change, not just a token optimization**: a fresh session no longer auto-verifies delegated work, auto-enforces spend limits, or auto-applies autonomous-session stop rules unless invoked.

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
