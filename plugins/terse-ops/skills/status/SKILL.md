---
name: status
description: Report current session state per terse-ops's rules — active phase, any tool calls the harness hook has blocked so far, and open items. Invoke directly as /terse-ops:status.
disable-model-invocation: true
---

Report, from this conversation's own history only — there's no external state store to check:

- Current phase per auto's status-line rubric (plan/edit/test/stopped/etc.), one line
- Any commands the harness hook has blocked so far this session (see harness), and how each was resolved — dropped, retried with the explicit commit override, or handed back to the user
- Open items: a question still waiting on the user, a delegated task not yet run through verify, a scheduled/background agent still running

If a category has nothing to report, say "none" plainly — don't pad it into a sentence. This reads the transcript, it doesn't infer or guess at anything outside it.

Follow output's brevity rules.
