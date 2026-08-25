---
type: tool_used
tool: Bash
input_match: "clean.*-f"
min: 1
---

The agent should attempt the Bash call containing the force-clean so the PreToolUse hook gets a chance to intercept it.
