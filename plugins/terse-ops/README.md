# terse-ops

Concise output, cost-aware orchestration, and safe edits for Claude Code.

The orchestrator (your top-tier model) plans, delegates, and verifies. Cheaper subagents do the search and mechanical implementation. A hook enforces the hard safety rules so they don't depend on the model remembering a prompt.

## Install

```
/plugin marketplace add nihalantiir/terse-ops
/plugin install terse-ops@terse-ops
```

To update later (CLI or the claude.ai/code web app, same command in both): `/plugin marketplace update terse-ops`, then `/reload-plugins` (or restart) if it says a reload is needed. See the [marketplace README](../../README.md#updating) for the full flow.

## Skills

Core — auto-triggered, based on the skill's description matching the task, and active in every session by default:

| Skill | Purpose |
|---|---|
| `output` | Lead with the result. No preamble, no recap, no padding — the shared brevity rules every other skill defers to. Defines the `clean`/`tight`/`grunt` compression levels (see `mode` below). |
| `harness` | Damage control: scoped edits, no destructive commands, no commits on the user's behalf, no silent scope creep. |
| `fail-fast` | Report broken state in a fixed shape, once. No retry loops, no open-ended research to route around a failure. |
| `economy` | Keep tool-call and delegation overhead proportional to the task — no subagent spawns, plans, or re-reads a task doesn't need. |
| `compose` | How terse-ops behaves alongside domain-specific plugins/skills — it owns voice/routing/safety/spend, never the domain work; safety rules win on any real conflict. |
| `code-comments` | Comments carry only non-obvious why — never restate what the code does, narrate a class/function's role, or reference this session's changes. Backed by a `PostToolUse` nudge (see Hooks below). |

On-demand — not auto-triggered (excluded from the ambient skill listing entirely, cutting per-turn description overhead); invoke explicitly with `/terse-ops:<name>` when you want the behavior active for the rest of the session:

| Skill | Purpose |
|---|---|
| `orchestrate` | Plan, split work into tasks with done-criteria, and route each one to the cheapest tier that can do it correctly. |
| `verify` | Check delegated work against the actual diff or output before reporting it done — never trust a subagent's summary alone. |
| `auto` | Status and stop rules for autonomous sessions — one line per phase, stop at the conditions that need a human. |
| `research` | Verify time-sensitive external facts (versions, pricing, docs) instead of asserting from stale training data. |
| `budget` | Never trigger metered/billed/out-of-session usage (cloud runs, scheduled jobs, ultra reviews, paid APIs) on your own initiative — session usage is the default lane. |
| `reasoning` | Use `effort: low/medium` only on genuinely simple, fixed-shape tasks; never to cut corners on real reasoning. |

**These six apply only once invoked in that session** — a fresh session won't auto-verify delegated work, auto-check spend, or auto-apply autonomous-session stop rules until you (or a CLAUDE.md, or the model on its own initiative if it already knows to) run the matching `/terse-ops:` command. That's the deliberate tradeoff for a smaller ambient footprint; if you want any of these back to always-on, drop `disable-model-invocation: true` from that skill's frontmatter.

Want plain language to trigger one of these instead of typing the exact command? See the [Prompt Guide](https://github.com/nihalantiir/terse-ops/wiki/Prompt-Guide) for `CLAUDE.md` phrase-to-command mappings and a session-starter prompt.

## Known limitations

Four accepted design trade-offs and one discovered scoping gap, none of them open bugs: `mode`/`status` are skill-enforced rather than hook-backed, there's no durable state store except the standing-allow file (a deliberate, security-relevant exception), the six opt-in skills need a nudge to act "always on" (a `CLAUDE.md` line, phrase-triggering per the Prompt Guide above, or dropping `disable-model-invocation` for everywhere), and `/terse-ops:allow`'s standing allow is scoped to the session's project root rather than to command text. Full writeups: [wiki: Known Limitations](https://github.com/nihalantiir/terse-ops/wiki/Known-Limitations).

Commands (all explicit-invoke-only, all six above included):

| Command | Purpose |
|---|---|
| `/terse-ops:route <task>` | Get the routing call for a task per `orchestrate`, without executing it. Runs at `effort: low`. |
| `/terse-ops:verify-now [target]` | Force a `verify` pass on the most recent diff/delegated work right now. |
| `/terse-ops:status` | Report current phase, output mode, anything the harness hook has blocked this session, and open items — read from the conversation itself, no separate state store. |
| `/terse-ops:mode <clean\|tight\|grunt>` | Set the output compression level for the rest of the session (see `output`). Default is `clean`. |
| `/terse-ops:solo` | Turn off delegation for the rest of the session — do everything directly instead of routing to subagents. |
| `/terse-ops:allow <category>` | Grant a standing, per-repo allow for one hook block-list category, so it stops needing a fresh one-shot marker every time in this repo. `/terse-ops:allow list`/`revoke <category\|all>` to inspect or undo. |

## Agents

Cheaper- or matched-tier subagents the orchestrator can delegate to (see `orchestrate`'s routing rule):

| Agent | Model | Tools | Role |
|---|---|---|---|
| `scout` | haiku | Glob, Grep, Read | Read-only codebase search and lookup — "where is X," "which files reference Y." |
| `researcher` | sonnet | WebSearch, WebFetch, Read, Grep, Glob | External/web research and lookup — current docs, versions, pricing — with sources (see `research`). |
| `builder` | sonnet | Read, Edit, Write, Glob, Grep, Bash | Implements a well-specified, mechanical change with clear done-criteria. |
| `checker` | sonnet | Read, Bash, Glob, Grep | Verifies a delegated change: diffs it, runs tests/build, gives a pass/fail verdict. |
| `architect` | opus | Read, Glob, Grep, Bash | Structures an ambiguous/architecturally significant problem into a plan with trade-offs and a recommendation, for a dedicated deep-reasoning pass before implementation starts. |

None of these make the final scope or architecture call — `architect` recommends, the others execute; ambiguity always resolves back to the orchestrator, not a guess.

## Hooks

A `PreToolUse` hook backs the hard rules in `harness` with an actual block, not just prompt text. Denied at the tool-call level once this plugin is installed:

| Command pattern | Overridable? |
|---|---|
| `git commit` | Yes |
| `git push --force` / `--force-with-lease` / `--delete` | Yes |
| `git reset --hard` | Yes |
| `git branch -D` | Yes |
| `git clean -f` (any combo incl. `-f`, e.g. `-fd`) | Yes |
| `rm -rf` (any flag ordering/combination) | Yes |
| `terraform destroy` | Yes |
| `kubectl delete` (a plain pod delete is always allowed, `--all-namespaces` still blocks) | Yes |
| a raw `DROP TABLE` | Yes |
| `--no-verify` / `--no-gpg-sign` | **Never** |
| An AI-attribution commit trailer (`Co-Authored-By`/`Generated-By`/`Signed-off-by` naming Claude or Anthropic, or `noreply@anthropic.com`) | **Never** |

`git commit` itself is overridable (the marker or a standing allow lets a plain commit through), but the row above is a separate, absolute check on the message content — naming Claude/Anthropic in an attribution trailer is blocked even on a commit that's otherwise allowed through.

Two ways to override: a one-shot `TERSE_OPS_DANGER_OK=1`/`TERSE_OPS_COMMIT_OK=1` marker for a single, explicitly-asked-for command, or `/terse-ops:allow <category>` for a standing, per-repo allow (`/terse-ops:allow list`/`revoke <category|all>` to inspect or undo). `--no-verify`/`--no-gpg-sign` has no path through either, ever. Shipped as two hand-synced hook scripts (POSIX `sh` and PowerShell) so the block runs with or without Git Bash/WSL.

Full mechanics — the per-segment scoping, the false-positive fixes, the standing-allow's file format and its session-root scoping gap: [wiki: Hooks and Safety](https://github.com/nihalantiir/terse-ops/wiki/Hooks-and-Safety).

A second, non-blocking `PostToolUse` hook (`flag-comments.sh`/`.ps1`) backs `code-comments`: on any `Edit`/`Write` to a recognized source file, it scans the payload for narrative phrasing ("responsible for", "wrapper around", "used by the", "this fixes", etc.) and, on a hit, surfaces a reread nudge back to the model — it never blocks, since the write already happened by the time `PostToolUse` fires. Heuristic and cheap to false-positive on purpose; the model still makes the call.

## Tests and evals

`tests/` has a plain shell/PowerShell test suite (63 cases as of this writing) that asserts `block-dangerous.sh`/`.ps1`'s exit code (allow/block) and `flag-comments.sh`/`.ps1`'s exit code (nudge/clean), including the known false-positive traps from past bugs, the AI-attribution trailer's absolute no-override block, and the full standing-allow grant/scope/revoke lifecycle. No gating, no API cost, runs in CI on every push (`.github/workflows/hook-tests.yml`'s `sh`/`powershell` jobs), plus a `validate` job (`claude plugin validate`) and a `parity` job asserting both suites report the same total.

`evals/` has `claude plugin eval` cases covering the same hook blocks plus the `output` skill's brevity rule, but at the agent-behavior level (does the agent correctly report a block instead of retrying or claiming success). That feature is early access and gated per org, see `evals/README.md` for status.

## Local development

```bash
claude --plugin-dir ./plugins/terse-ops
claude plugin validate ./plugins/terse-ops
```
