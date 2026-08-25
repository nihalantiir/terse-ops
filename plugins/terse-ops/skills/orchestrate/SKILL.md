---
description: Use the strongest model as a high-level orchestrator. Plan, split work, and leave implementation detail to lower-cost steps or subagents when available.
---

# Orchestrate

You are the conductor, not the entire orchestra — but only bring in the orchestra when the piece needs one.

Do:
- State the goal in one line
- Break non-trivial work into small tasks with clear done criteria
- Delegate implementation, search, and routine edits to subagents or lower-cost tools when they're available and the task is big enough to justify the handoff
- Keep a short plan and status; update it only when the phase changes (see auto for cadence)
- Verify every delegated result before reporting it done (see verify) — never take a subagent's summary at face value
- Hold delegated work to the same rules as if you did it yourself: harness for blast radius, output for reply shape, fail-fast for how it reports breakage

Routing — match the task to the cheapest tier that can do it correctly, not the tier that's easiest to reach for:
- Read-only search or lookup ("where is X", "which files reference Y", locate/grep/glob work) → scout (cheap, fast, no write access)
- A well-specified, mechanical change with clear done-criteria (apply a described edit, fix a bug with a known repro, routine code from an explicit plan) → builder
- Checking a delegated change actually did what it claimed (diff review, running tests/build, pass/fail verdict) → checker, or do it yourself for something small enough to eyeball
- Ambiguous scope, architecture or design decisions, anything needing judgment calls the task didn't already resolve → keep it yourself; don't delegate a decision, only delegate execution of one already made
- No matching agent available in this environment: skip delegation, do it yourself (see edge cases below)

Do not:
- Expand every task into a long essay or a formal plan when a one-file, one-command fix will do — orchestration overhead should scale with the task, not apply unconditionally
- Re-read the same files without a new reason to
- Implement everything in one unbounded pass when a staged plan is safer
- Simulate delegation (narrating what a subagent "would" do) when no subagent or delegation tool is actually available — just do the work directly instead

Edge cases:
- No subagents/tools available for this task: skip delegation, do it yourself, and don't apologize for the lack of orchestration.
- A task looks big but is actually one mechanical edit repeated in obvious places: do it directly rather than spinning up a plan and handoffs for it.
- Mid-task new evidence contradicts the plan: adjust the plan and say so in one line — don't keep executing a plan you know is wrong.

Hand off concrete steps, not vague intent. Verify results. Adjust the plan only when evidence requires it.
