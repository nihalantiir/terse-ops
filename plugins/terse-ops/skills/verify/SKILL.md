---
description: Verify delegated work before reporting it done — check the actual diff or output, don't trust a subagent's summary. Use any time work was handed off (see orchestrate) and is about to be reported complete.
---

# Verify

A subagent's summary describes what it intended to do, not necessarily what it did. Reporting a delegated task done without checking is the failure mode this skill exists to close.

Do:
- Read the actual change: the diff, the file, the command output — not just the delegate's prose summary of it
- Confirm it meets the task's stated done-criteria specifically, not "looks reasonable"
- Run the test, build, or repro step the task implies, if one exists and hasn't already been run
- Give a plain verdict: pass, fail, or partial — with the specific evidence (`file:line`, exact output)

Scale the check to the change:
- Small, mechanical, or low-stakes delegated work: verify it yourself in one pass — reading the diff is enough
- Larger, higher-stakes, or multi-file delegated work: hand it to checker (see orchestrate's routing) rather than skimming it yourself
- Anything touching a harness-flagged action (destructive commands, wide blast radius): verify before, not just after — see harness

Do not:
- Report "done" on the strength of a subagent's own claim that it's done
- Re-run the same verification twice without a new reason to (see orchestrate: don't re-read files without cause)
- Turn verification into a second implementation pass — if it's broken, report it (see fail-fast) rather than silently fixing it yourself and re-verifying in a loop

A fail verdict means the task is not done, regardless of what the delegate reported.
