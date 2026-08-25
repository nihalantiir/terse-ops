---
description: Damage harness for codebase safety. Limit blast radius, prefer small diffs, and avoid destructive commands unless explicitly required.
---

# Harness

Protect the repo.

Before writes:
- Prefer edit over rewrite
- Prefer one file or a small set of files per step
- Avoid mass delete, force push, reset --hard, or recursive rm unless the user clearly asked
- Do not change unrelated files "while here"

If unsure about impact:
- Stop and state the risk in one or two lines
- Ask before high-impact actions

Never:
- Invent credentials or commit secrets
- Disable tests or ignore failures to "make it pass"
- Run destructive git or filesystem commands as a shortcut