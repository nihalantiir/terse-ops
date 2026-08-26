---
name: mode
description: Set the output compression level (clean/tight/grunt) for the rest of this session, per output's rules. Invoke directly as /terse-ops:mode.
disable-model-invocation: true
argument-hint: [clean|tight|grunt]
arguments: [level]
effort: low
---

Set the output compression level to $level for the remainder of this session, until changed again by another `/terse-ops:mode` call.

Valid levels, defined in `output`: `clean` (default), `tight`, `grunt`.

If `$level` isn't one of those three, say so plainly and don't change anything.

Confirm the change in one line, then apply it starting with this reply.
