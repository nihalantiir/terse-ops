# terse-ops

Concise output, cost-aware orchestration, and safe edits for Claude Code.

The orchestrator (your top-tier model) plans, delegates, and verifies. Cheaper subagents do the search and mechanical implementation. A hook enforces the hard safety rules so they don't depend on the model remembering a prompt.

## Install

```
/plugin marketplace add nihalantiir/terse-ops
/plugin install terse-ops@terse-ops
```

To update later (CLI or the claude.ai/code web app — same commands in both): `/plugin marketplace update terse-ops` then `/plugin install terse-ops@terse-ops`. See the [marketplace README](../../README.md#updating) for the full flow.

## Skills

Core — auto-triggered, based on the skill's description matching the task, and active in every session by default:

| Skill | Purpose |
|---|---|
| `output` | Lead with the result. No preamble, no recap, no padding — the shared brevity rules every other skill defers to. Defines the `clean`/`tight`/`grunt` compression levels (see `mode` below). |
| `harness` | Damage control: scoped edits, no destructive commands, no commits on the user's behalf, no silent scope creep. |
| `fail-fast` | Report broken state in a fixed shape, once. No retry loops, no open-ended research to route around a failure. |
| `economy` | Keep tool-call and delegation overhead proportional to the task — no subagent spawns, plans, or re-reads a task doesn't need. |
| `compose` | How terse-ops behaves alongside domain-specific plugins/skills — it owns voice/routing/safety/spend, never the domain work; safety rules win on any real conflict. |

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

## Known limitations

- **`mode`/`status` are skill-enforced, not hook-backed.** `/terse-ops:mode` and `/terse-ops:status` work by asking the model to track state in the conversation and follow the matching skill's instructions — unlike `harness`, there's no `PreToolUse`/`SessionStart` hook or file behind them. Deliberate: durable state would mean writing and cleaning up session files. The trade-off is that the model's own adherence is the only enforcement.
- **No durable state store.** Because mode and phase live in the conversation rather than a file, a very long session or a context compaction can lose track of the current mode and drift back to the `clean` default, or misreport a phase in `/terse-ops:status`. Accepted for a stateless, install-and-go plugin — re-run `/terse-ops:mode` after a compaction if it matters, rather than assuming it held.
- **Opt-in skills need a standing nudge to act "always on."** The six skills above only take effect once invoked per session. To make one always-on for a project without editing the plugin, add the matching `/terse-ops:<name>` command to that project's `CLAUDE.md` — Claude reads and follows it every session. To make it always-on everywhere instead, drop `disable-model-invocation: true` from that skill's frontmatter (same lever 0.7.0 used to thin the set down).

Commands (all explicit-invoke-only, all six above included):

| Command | Purpose |
|---|---|
| `/terse-ops:route <task>` | Get the routing call for a task per `orchestrate`, without executing it. Runs at `effort: low`. |
| `/terse-ops:verify-now [target]` | Force a `verify` pass on the most recent diff/delegated work right now. |
| `/terse-ops:status` | Report current phase, output mode, anything the harness hook has blocked this session, and open items — read from the conversation itself, no separate state store. |
| `/terse-ops:mode <clean\|tight\|grunt>` | Set the output compression level for the rest of the session (see `output`). Default is `clean`. |
| `/terse-ops:solo` | Turn off delegation for the rest of the session — do everything directly instead of routing to subagents. |

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

- `git commit` — overridable with `TERSE_OPS_COMMIT_OK=1` or `TERSE_OPS_DANGER_OK=1`
- `git push --force` / `--force-with-lease` / `--delete` — overridable
- `git reset --hard` — overridable
- `git branch -D` — overridable
- `git clean -f` (any flag combination including `-f`, e.g. `-fd`) — overridable
- `rm -rf` (any flag ordering/combination) — overridable
- `terraform destroy` — overridable
- `kubectl delete` — overridable; a plain `pod`/`pods`/`po` delete is allowed unconditionally (a controller reschedules it anyway), `--all-namespaces` still blocks even for pods
- a raw `DROP TABLE` — overridable
- `--no-verify` / `--no-gpg-sign` — **not** overridable, ever; bypassing signing/hooks is a different category from "delete this on purpose"

"Overridable" means: prefix the single command with `TERSE_OPS_DANGER_OK=1` when the user explicitly asked, this turn, for exactly that action — not "auto mode," not a standing approval, not inferred from context (see `harness`). Scoped to that one command; a later dangerous command needs its own fresh ask.

Shipped as two hook entries so the block still runs without Git Bash/WSL: `block-dangerous.sh` (POSIX `sh`, no bashisms) and `block-dangerous.ps1` (Windows `powershell.exe`, which ships with every Windows install). Both run on every Bash call; whichever interpreter exists on the machine does the blocking — the other fails to launch and is a silent no-op, which is expected, not a bug.

Every check runs per-segment, scoped to one logical command split on `;`/`&`/`|` — not against the whole raw compound line. A command spanning `&&`/`;`/`|` can't trip a rule meant for a different clause (e.g. `git log && echo "committed"` no longer false-positives the commit block just because both words appear somewhere on the line). Quoting isn't understood, which is a known, accepted gap.

## Evals

`evals/` has `claude plugin eval` cases covering the hook blocks above and the `output` skill's brevity rule. The feature is early access and gated per org — see `evals/README.md` for status and how to run it once available.

## Local development

```bash
claude --plugin-dir ./plugins/terse-ops
claude plugin validate ./plugins/terse-ops
```
