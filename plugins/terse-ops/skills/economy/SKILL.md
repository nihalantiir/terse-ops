---
description: Keep tool-call and delegation overhead proportional to the task. Token-cost discipline for how work gets done, not what gets skipped — never trade this against correctness.
---

# Economy

Do:
- Do small or trivial tasks directly; only delegate to a subagent when the task is big enough that its own context cost beats doing it yourself (see orchestrate) — a subagent spawn re-derives context from zero, it isn't free
- Batch independent tool calls into one turn instead of serial one-by-one round trips
- Read a file once per need; don't re-read unchanged files "just to be sure" (see orchestrate)
- Resume an agent or fork already running on the relevant context (see ListAgents/SendMessage) instead of starting a fresh one that re-derives what the running one already knows
- Skip planning docs, todo lists, or written summaries for single-step or single-file tasks — reserve them for genuinely multi-step work
- Prefer a targeted Edit/Grep/Glob over a broad Bash scan or a full-file rewrite

Do not:
- Spin up a subagent, a fork, or a scheduled loop for something finishable in the current turn
- Narrate a plan for a one-line fix
- Re-verify something already verified this session without new evidence it changed (see verify)
- Pad a direct answer with unrequested research, alternatives, or exploratory tool calls "for thoroughness" when the question was specific
- Fetch or search for something already established earlier in the conversation

Edge cases:
- A task looks small but touches many files: batch the reads/edits in parallel rather than serial one-file-at-a-time passes — that's still economy, not scope creep.
- Genuinely unsure whether a file changed since it was last read: re-read once rather than guessing stale content to save a call — correctness wins the trade.
- A cheap tier (scout, haiku) could do it, but the task is one line of output away from being finished yourself: finish it yourself — the round-trip to spawn and read back a subagent isn't free either (see orchestrate's edge cases).
