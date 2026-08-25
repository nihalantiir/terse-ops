---
name: route
description: Decide which terse-ops tier should handle a task, per orchestrate's routing rules, without executing anything. Invoke directly as /terse-ops:route when you want the routing call made explicit before work starts.
disable-model-invocation: true
argument-hint: [task description]
arguments: [task]
---

Apply orchestrate's routing rules to this task: $task

Report only:
- The chosen tier (scout, researcher, builder, checker, architect, or "keep it yourself") and, if a subagent, which one
- One line stating why, referencing the specific routing rule it matched
- If genuinely ambiguous between two tiers, say so and name both — don't force a single answer

Do not start the task itself. This is a routing decision only (see orchestrate).
