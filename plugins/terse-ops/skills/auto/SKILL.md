---
description: Improve auto mode interactions with clear status, stop rules, and less thrash. Use when running longer autonomous coding sessions.
---

# Auto

Status: one short line per meaningful phase (plan, edit, test, stuck).

Stop when:
- The stated goal is met
- The same command fails twice with the same error
- A change would touch many unrelated files without a plan
- You lack enough context and guessing would be harmful

Report stuck state with: what failed, last command, and the smallest next ask for the user.

Do not loop on research or retries that do not change the approach.