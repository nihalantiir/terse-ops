# terse-ops plugin

Skills for short replies, orchestration, and safe edits in Claude Code.

## Skills

- **output** — lead with the result; no preamble or recap
- **orchestrate** — plan and delegate; avoid doing all low-level work in one heavy model pass
- **harness** — limit destructive edits; prefer small diffs
- **auto** — clear status lines; stop conditions for auto mode
- **fail-fast** — report breakage; do not burn tokens on open-ended research or retry loops

## Local load

```bash
claude --plugin-dir ./plugins/terse-ops
```