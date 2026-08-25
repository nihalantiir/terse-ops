# terse-ops

Concise output, cost-aware orchestration, and safe edits for Claude Code.

The orchestrator (your top-tier model) plans, delegates, and verifies. Cheaper subagents do the search and mechanical implementation. A hook enforces the hard safety rules so they don't depend on the model remembering a prompt.

## Install

```
/plugin marketplace add Nihalantiir/terse-ops
/plugin install terse-ops@terse-ops
```

## Skills

| Skill | Purpose |
|---|---|
| `output` | Lead with the result. No preamble, no recap, no padding — the shared brevity rules every other skill defers to. |
| `orchestrate` | Plan, split work into tasks with done-criteria, and route each one to the cheapest tier that can do it correctly. |
| `verify` | Check delegated work against the actual diff or output before reporting it done — never trust a subagent's summary alone. |
| `harness` | Damage control: scoped edits, no destructive commands, no commits on the user's behalf, no silent scope creep. |
| `auto` | Status and stop rules for autonomous sessions — one line per phase, stop at the conditions that need a human. |
| `fail-fast` | Report broken state in a fixed shape, once. No retry loops, no open-ended research to route around a failure. |

## Agents

Cheaper-model subagents the orchestrator can delegate to (see `orchestrate`'s routing rule):

| Agent | Model | Tools | Role |
|---|---|---|---|
| `scout` | haiku | Glob, Grep, Read | Read-only search and lookup — "where is X," "which files reference Y." |
| `builder` | sonnet | Read, Edit, Write, Glob, Grep, Bash | Implements a well-specified, mechanical change with clear done-criteria. |
| `checker` | sonnet | Read, Bash, Glob, Grep | Verifies a delegated change: diffs it, runs tests/build, gives a pass/fail verdict. |

None of these make architecture or scope decisions — ambiguity gets handed back to the orchestrator, not guessed at.

## Hooks

A `PreToolUse` hook backs the hard rules in `harness` with an actual block, not just prompt text: `git commit`, `git push --force`, `rm -rf`, `--no-verify`, `--no-gpg-sign`, and `reset --hard` are denied at the tool-call level once this plugin is installed.

## Local development

```bash
claude --plugin-dir ./plugins/terse-ops
```
