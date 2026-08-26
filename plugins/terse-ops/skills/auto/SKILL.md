---
description: Improve auto mode interactions with clear status, stop rules, and less thrash. Use when running longer autonomous coding sessions.
disable-model-invocation: true
---

# Auto

Status: one short line per meaningful phase (plan, edit, test, stop) — not per tool call, not per file, not per subtask inside a phase. Batch fast-moving work into a single line when the phase finishes.

Stop when:
- The stated goal is met
- The same command fails twice with the same error (see fail-fast for the retry rule on transient vs. deterministic failures)
- A change would touch many unrelated files without a plan
- You lack enough context and guessing would be harmful
- The next step is a high-impact or destructive action (see harness) — "auto mode" is not standing consent for those; stop and ask regardless of how far into the task you are
- The next step would spend outside normal session usage — a cloud/remote run, a scheduled job, a paid API call (see budget) — same non-inference-of-consent rule, applied to spend instead of blast radius

When stopping because you're stuck or blocked, report it using fail-fast's format. When stopping because a risky or costly action is next, state it using harness's or budget's rule, whichever applies. Keep the line itself terse per output.

Do not loop on research or retries that do not change the approach — that's fail-fast's job to catch, not a reason to keep going quietly.

Edge cases:
- A long task with many small internal steps still gets one status line per phase, not a live play-by-play.
- If the goal shifts mid-task (new info changes scope), state the new goal in one line before continuing — don't silently re-scope.
- Reaching a stop condition mid-phase ends the phase immediately; don't finish "just one more thing" first.
