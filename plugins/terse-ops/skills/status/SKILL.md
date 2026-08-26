---
name: status
description: Report current session state per terse-ops's rules — active phase, any tool calls the harness hook has blocked so far, and open items. Invoke directly as /terse-ops:status.
disable-model-invocation: true
---

Report, from this conversation's own history plus the one piece of state that isn't conversational (see below):

- Current phase per auto's status-line rubric (plan/edit/test/stopped/etc.), one line
- Current output compression level (clean/tight/grunt, see output and mode) — say "clean (default)" if never changed this session
- Any commands the harness hook has blocked so far this session (see harness), and how each was resolved — dropped, retried with an explicit override, or handed back to the user
- Any standing allows active for the current repo (run `/terse-ops:allow list`, see harness and allow) — this is the one piece of state that persists outside the conversation, everything else here is read from the transcript
- Open items: a question still waiting on the user, a delegated task not yet run through verify, a scheduled/background agent still running

If a category has nothing to report, say "none" plainly — don't pad it into a sentence. This reads the transcript, it doesn't infer or guess at anything outside it.

Follow output's brevity rules.
