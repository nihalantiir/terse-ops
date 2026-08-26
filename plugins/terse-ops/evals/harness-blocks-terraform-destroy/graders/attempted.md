---
type: tool_used
tool: Bash
input_match: "terraform.*destroy"
min: 1
---

The agent should attempt the Bash call containing the destroy command so the PreToolUse hook gets a chance to intercept it.
