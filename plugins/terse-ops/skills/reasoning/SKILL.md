---
description: Control reasoning-token cost via effort level and scope, without cutting correctness on tasks that need real thinking. Covers what the effort field actually does and what it doesn't (it isn't a reply-length knob).
---

# Reasoning

`effort` is a real cost lever, but it's a behavioral signal, not a strict budget, and on some models it doesn't touch reply length at all — treat it accordingly, not as a magic brevity switch.

Do:
- Set `effort: low` or `effort: medium` on a skill/command only when the task is genuinely simple and fixed-shape (a single classification, a lookup, a bounded decision like `route`) — effort trades some capability for speed/cost, so spend that trade only where getting it wrong costs nothing real
- Leave effort at its default (unset) for anything needing multi-step reasoning, correctness-critical judgment, or open-ended investigation — don't lower it just because a task "sounds" small if a wrong answer is expensive
- If a low-effort task turns out to need real reasoning partway through, say so and escalate rather than forcing a shallow answer to stay fast
- Cut what has to be reasoned about in the first place — don't re-derive context, re-read unchanged files, or re-plan a decision already made (see economy); the cheapest reasoning is the reasoning that's skipped because the answer was already known
- For the final reply's length specifically, prompt for brevity directly (see output) — don't rely on effort to do that job; effort governs how much thinking happens, not how long the visible answer runs

Do not:
- Set low effort on a task with real correctness stakes just to save tokens — that's the "dumbing down" this skill exists to prevent, not the saving it's for
- Assume a lower effort level shortens the final reply on its own — verify against output's rules instead of hoping the setting does that
- Add "think step by step" scaffolding to a task that doesn't need it — extra scaffolding spends reasoning tokens without adding value; match it to genuine complexity, not habit

Edge cases:
- A command should stay fast for typical simple inputs but occasionally hits a hard one: default to correctness on the hard instance — flag it and escalate rather than answering shallow to keep the class of task uniformly cheap.
- Subagent definitions (`agents/*.md`) don't support an `effort` field at all — that lever exists on skills/commands only. Cost control for a subagent is the `model` choice, not effort.
