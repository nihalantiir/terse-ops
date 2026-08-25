---
name: verify-now
description: Manually trigger a verification pass against the most recent delegated or hand-made change, per verify's rules, instead of waiting for it to fire automatically before a "done" report. Invoke directly as /terse-ops:verify-now.
disable-model-invocation: true
argument-hint: "[optional: file, path, or PR to check — defaults to the most recent diff]"
arguments: [target]
---

Run verify's checklist against: $target

If $target is empty, verify the most recent uncommitted diff or the most recently reported "done" work in this conversation instead.

Do:
- Read the actual diff or output, not a prior summary of it
- Run the test/build/repro step it implies, if one exists and hasn't already run
- Give a plain verdict — pass, fail, or partial — with specific evidence (`file:line`, exact output)

Follow verify's and output's rules for the report. A fail verdict stands even if something was previously reported done.
