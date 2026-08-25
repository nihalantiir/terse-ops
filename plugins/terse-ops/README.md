# terse-ops

Concise output, cost-aware orchestration, and safe edits for Claude Code.

The orchestrator (your top-tier model) plans, delegates, and verifies. Cheaper subagents do the search and mechanical implementation. A hook enforces the hard safety rules so they don't depend on the model remembering a prompt.

## Install

```
/plugin marketplace add Nihalantiir/terse-ops
/plugin install terse-ops@terse-ops
```

## Skills

Auto-triggered, based on the skill's description matching the task:

| Skill | Purpose |
|---|---|
| `output` | Lead with the result. No preamble, no recap, no padding — the shared brevity rules every other skill defers to. |
| `orchestrate` | Plan, split work into tasks with done-criteria, and route each one to the cheapest tier that can do it correctly. |
| `verify` | Check delegated work against the actual diff or output before reporting it done — never trust a subagent's summary alone. |
| `harness` | Damage control: scoped edits, no destructive commands, no commits on the user's behalf, no silent scope creep. |
| `auto` | Status and stop rules for autonomous sessions — one line per phase, stop at the conditions that need a human. |
| `fail-fast` | Report broken state in a fixed shape, once. No retry loops, no open-ended research to route around a failure. |
| `research` | Verify time-sensitive external facts (versions, pricing, docs) instead of asserting from stale training data. |

Explicit-only (never auto-triggered — invoke by name when you want the behavior on demand):

| Command | Purpose |
|---|---|
| `/terse-ops:route <task>` | Get the routing call for a task per `orchestrate`, without executing it. |
| `/terse-ops:verify-now [target]` | Force a `verify` pass on the most recent diff/delegated work right now, rather than waiting for it to fire before a "done" report. |

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

- `git commit`
- `git push --force` / `--force-with-lease` / `--delete`
- `git reset --hard`
- `git branch -D`
- `git clean -f` (any flag combination including `-f`, e.g. `-fd`)
- `rm -rf` (any flag ordering/combination)
- `--no-verify` / `--no-gpg-sign`

## Evals

`evals/` has `claude plugin eval` cases covering the hook blocks above and the `output` skill's brevity rule. The feature is early access and gated per org — see `evals/README.md` for status and how to run it once available.

## Local development

```bash
claude --plugin-dir ./plugins/terse-ops
claude plugin validate ./plugins/terse-ops
```
