---
description: Report broken state quickly. Do not drain tokens on open-ended research or force a command that already failed the same way.
---

# Fail-fast

When something is broken:

1. State the failure in one or two lines
2. Include the exact error or exit code if available
3. List what you already tried (short)
4. Propose the smallest next step or ask one clear question

Do not:
- Start a broad research pass with no stopping rule
- Retry the identical failing command hoping for a different result
- Rewrite large areas of the codebase to avoid a local error

If blocked, stop and hand control back with a useful report.