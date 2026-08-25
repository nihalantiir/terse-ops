# Terse Ops

A Claude Code plugin marketplace for concise, disciplined, cost-aware agentic work.

The top model plans, delegates, and verifies. Cheaper models do the mechanical labor beneath it. A hook-enforced damage harness limits blast radius. Failures are reported once, not researched forever.

Not related to TERSE state language, TerseAI workflows, or be-terse hooks — this is an original ops style: concise output, orchestrator role, and safety rules, packaged as a Claude Code plugin.

## Install

```
/plugin marketplace add Nihalantiir/terse-ops
/plugin install terse-ops@terse-ops
```

## What's in it

This marketplace currently ships one plugin: [`terse-ops`](plugins/terse-ops/README.md), which adds:

- **Skills** — behavioral rules for output style, orchestration/routing, delegate verification, a damage harness, auto-mode discipline, and fail-fast reporting
- **Agents** — `scout`, `builder`, and `checker`: cheaper-model subagents for search, mechanical implementation, and verification, so the orchestrator isn't doing every step itself at top-model cost
- **Hooks** — a `PreToolUse` guard that blocks the harness skill's hard "never" list (commits on your behalf, force-push, `--no-verify`, `rm -rf`, `reset --hard`) at the tool-call level, not just as a prompt instruction

See the [plugin README](plugins/terse-ops/README.md) for the full breakdown of each skill and agent.

## License

MIT — see [LICENSE](LICENSE).
