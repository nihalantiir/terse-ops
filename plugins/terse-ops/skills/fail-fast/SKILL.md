---
description: Report broken state quickly. Do not drain tokens on open-ended research or force a command that already failed the same way.
---

# Fail-fast

When something is broken, report it in this exact shape (this is the canonical format other terse-ops skills point to):

1. State the failure in one or two lines
2. Include the exact error text or exit code, unabridged — never paraphrase a stack trace (see output's exceptions list)
3. List what you already tried, as short bullets
4. Propose the smallest next step, or ask one clear question — pick one, not both

Retry rule:
- Deterministic failure (bad syntax, missing file, failed assertion, wrong flag): do not retry the identical command. Stop after the first failure and report.
- Transient/environment failure (network timeout, flaky test, rate limit, lock contention): one retry is allowed. If it fails again, treat it as deterministic and report.
- If you can't tell which kind it is, treat it as deterministic — report rather than guess-retry.

Do not:
- Start a broad research pass with no stopping rule
- Retry the identical failing command hoping for a different result
- Rewrite large areas of the codebase to avoid a local error
- Narrow or reframe the task to something that happens to work, instead of reporting the real failure
- Suppress the error to force success (disabling checks, ignoring exit codes, `--no-verify`) — that's a harness violation, not a fix

If blocked, stop and hand control back with a useful report. Everything except the required error/exit-code text follows output's brevity rules.
