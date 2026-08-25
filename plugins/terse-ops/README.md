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

### Skill files

**`plugins\terse-ops\skills\output\SKILL.md`**

```markdown
---
description: Keep Claude CLI and chat replies short, readable, and result-first. Use when the user wants less verbosity or terse ops style.
---

# Output

Lead with the answer or outcome in the first sentence.

Rules:
- No preamble ("I'll start by...", "Let me look at...")
- No closing recap of work already shown
- Prefer bullets over paragraphs when listing facts
- Keep technical detail; cut filler and hedging
- Errors, test failures, and security notes stay full and clear

Do not sacrifice correctness for brevity.