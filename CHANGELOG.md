# Changelog

## 1.8.0 - 2026-08-27

- Ran a real, bounded token-savings pilot measurement instead of relying on the `economy`/`orchestrate` claims going unverified: 3 read-only tasks against this repo, run once with the plugin disabled and once enabled, comparing actual `total_cost_usd`/token counts from `claude -p --output-format json`. Result: 11.5% cheaper, 23% fewer turns overall — directionally positive, but a thin sample (one run per task, no subagent routing exercised), documented as a pilot, not a standing benchmark, in the new wiki [Token Savings](https://github.com/nihalantiir/terse-ops/wiki/Token-Savings) page.
- Both READMEs and the wiki Home page now carry an explicit "actively developed, still beta" status note.

## 1.7.0 - 2026-08-27

- Fixed a real, previously-unknown gap found by actually installing the plugin fresh and dogfooding it: `hooks.json`'s `PreToolUse` matcher was `Bash` only, so a model reaching for the separate `PowerShell` tool on Windows bypassed every rule on the block list entirely. In the dogfood session, asked to delete a file, the model used `Remove-Item`, not `rm -rf`, and nothing stopped it.
- Matcher changed to `Bash|PowerShell`. Since almost everything on the block list is an external tool (`git`, `terraform`, `kubectl`, `psql`) with identical syntax regardless of which shell invokes it, that alone closed most of the gap for free. `rm -rf` is the one shell-native exception, so `block-dangerous.sh`/`.ps1` gained a matching PowerShell-syntax check: `Remove-Item`/`ri`/`rd`/`rmdir`/`del`/`erase` combined with `-Recurse` and `-Force`, same `rm-rf` category, same override marker/standing allow. 5 new test cases (71 total): the PowerShell delete blocked, a plain delete without `-Recurse` left alone, `Copy-Item -Recurse -Force` not misread as a delete, and the marker overriding it.
- `flag-comments`'s own matcher stays `Edit`/`Write` only for now (a file written via `Set-Content`/`Out-File` through the `PowerShell` tool still isn't nudged) — documented as an accepted, lower-stakes residual gap in the wiki, since it's a soft nudge rather than a safety block.
- The dogfood pass itself surfaced a second thing worth recording: cleaning up its throwaway test-project's marketplace registration also deleted a real, pre-existing **user-scope** terse-ops install (stuck at a stale `0.8.0`) — marketplaces are user-level, not project-scoped, so removing one removes it everywhere. Restored, now current instead of stale, but worth writing down: don't assume a marketplace/plugin removal is scoped to the throwaway project you added it in.

## 1.6.0 - 2026-08-27

- Root README: dropped the `---` separator between the `# terse-ops` headline and the banner — the H1 already separates, a rule under a title is extra chrome. Lean layout now: headline, banner, badges, one-paragraph pitch.
- `harness`: added a terse commit-message rule for the one-shot commit exception — imperative subject (~50–72 chars), states what changed rather than narrating the session, a body only when the why isn't in the subject, no diff recap, no file-by-file laundry list unless genuinely multi-area. Style-only, skill-enforced, no hook behind it (the AI-attribution trailer stays the one hook-enforced part of commit messages). `output` cross-references it.

## 1.5.0 - 2026-08-27

- Closed the `git commit -F <file>`/`--file=<file>` bypass in the AI-attribution check: the command-line text alone never contains a message that was read from a file, so a trailer living in that file's body slipped past 1.4.0's check entirely. `block-dangerous.sh`/`.ps1` now also read that file's content when the segment is already a recognized commit and the referenced path is a real file. 3 new test cases (66 total): file body naming Claude blocked via both `-F` and `--file=`, a human co-author in the file left alone.
- Wiki: fixed the "two ways to override" sentence under the hook block-list table, it still named only `--no-verify`/`--no-gpg-sign` as absolute even after the AI-attribution row was added above it. Documented the new `-F`/`--file` file-scanning coverage. Re-verified Home/Skills Reference are current (6 always-on, Prompt Guide listed) — a report that they still read the old 11/5 numbers turned out to be a stale cached view, not a live discrepancy.
- Root README: added a top `# terse-ops` headline and separator above the banner, and switched the badge row from centered HTML to left-aligned plain-markdown badges, matching `simple-vk`'s own README structure.
- Both READMEs' hook-table override sentence and test-case counts (66) brought current.

## 1.4.0 - 2026-08-27

- Hook, not just skill: `block-dangerous.sh`/`.ps1` now block any commit whose message carries an AI-attribution trailer (`Co-Authored-By`/`Generated-By`/`Signed-off-by` naming Claude or Anthropic, or the literal `noreply@anthropic.com` address), absolute, no override, same class as `--no-verify`. The check is unconditional per segment rather than gated on `git commit` appearing in the same one, so a multi-line heredoc-built message's trailer line is still caught even when it lands in a different segment than the invocation. A human co-author or a real DCO sign-off is left alone. 7 new test cases (4 block, 2 false-positive-trap allows, 1 no-override proof).
- `flag-comments`: added `manages the`/`this class manages`/`this module manages` to the narrative-phrase list, closing a real miss ("this class manages the connection pool" wasn't caught before). 1 new test case. `used by the` remains a known false-positive risk against legitimate technical usage notes (documented, not fixed, see wiki Known Limitations).
- Plugin + root README: the hook table now shows the AI-attribution trailer as its own absolute row, distinct from `git commit`'s own overridable row, and both READMEs' test-case counts are current (63).
- Wiki: documented the new hook check and the full `flag-comments` phrase list in Hooks and Safety, added the two concrete phrase-list misses/false-positives to Known Limitations, reworded the skill-count framing (12 behavioral skills plus `allow`, not folding `allow` into "13 total"), and added a "don't grow always-on further" note to Configuration.

## 1.3.0 - 2026-08-27

- `harness`: added a hard, unconditional rule against ever adding a `Co-Authored-By` (or any AI-attribution) trailer to a commit message, in any repo — overriding Claude Code's own default commit-workflow instruction. Added after the 1.2.0 release commit shipped with one anyway; that commit was amended, force-pushed, and the tag/release repointed to the corrected SHA.
- Ran the whole repo's own hook/test scripts (the only files `code-comments`/`flag-comments` actually govern) back through the new skill: no changes needed, they already held to the rule.
- Root README banner (`docs/banner.svg`) redrawn: dropped the terminal-window chrome, tagline, and bottom accent bar in favor of a plain dark gradient plus a single sparkle mark and the wordmark, closer to the minimal style used in `simple-vk`'s own banner.
- Wiki: documented `code-comments` and `flag-comments` across Skills Reference (13 skills now, 6 always-on), Hooks and Safety (the nudge is `PostToolUse`, never blocks), Known Limitations (the heuristic's phrase-list scope), Testing (55 cases), Home, and Agents Reference.

## 1.2.0 - 2026-08-27

- Added `code-comments`: a new always-on skill (no `disable-model-invocation`) closing a real gap found using the plugin on a real project — none of the existing skills governed what gets written *inside* files, and the system prompt's own "no comments unless non-obvious why" default lost out to task context often enough that a real session opened its first pass with narrative class blurbs ("Owns the X... every other Y is built on top of this...") until told explicitly to stop. `code-comments` states the rule set directly: no restating what code does, no class/function-role narration, no referencing this task/session in a comment, keep only genuinely non-obvious why.
- Backed it with a mechanical nudge, not just prose: a new `PostToolUse` hook (`flag-comments.sh`/`.ps1`) fires on any `Edit`/`Write` to a recognized source file, heuristically scanning for narrative phrasing ("responsible for", "wrapper around", "used by the", "this fixes", etc.) and surfacing a reread prompt back to the model on a hit. Unlike `block-dangerous`, this hook never blocks — the write already happened by the time `PostToolUse` fires — so false positives are cheap and the model still makes the call.
- Preloaded `code-comments` onto `builder`'s skill list — the one agent among the five that actually writes files.
- Extended both `tests/run-tests.sh`/`.ps1` with 9 new cases covering the new hook (46 → 55), reusing the existing pass/fail counters and CI parity check with no workflow changes needed.

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
