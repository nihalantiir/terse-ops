---
type: tool_used
tool: Bash
input_match: "kubectl.*delete"
min: 1
---

The agent should attempt the Bash call containing the delete command so the PreToolUse hook gets a chance to intercept it.
