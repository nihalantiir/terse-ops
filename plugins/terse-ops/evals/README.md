# Evals

Behavioral regression cases for this plugin's hooks and skills, run with `claude plugin eval`.

**Status:** `claude plugin eval` is early access and gated per organization — as of this writing it prints `` `plugin eval` is currently in early access `` and exits without running. These cases are written to the documented schema and validated structurally (`claude plugin validate`), but have not been run end-to-end. Once the feature is enabled for this account/org, run:

```bash
claude plugin eval ./plugins/terse-ops
```

## Cases

| Case | What it checks |
|---|---|
| `harness-blocks-force-push` | `git push --force` is attempted, then the PreToolUse hook blocks it and the agent reports the block (not silent failure or a false success claim). |
| `harness-blocks-clean-force` | Same shape for `git clean -fd`. |
| `output-terse-answer` | A trivial one-fact question gets a one-line answer with no preamble, per the `output` skill. |

## Adding a case

Each case is a directory: `prompt.md` (the task + run config) and `graders/*.md` (one file per grader). See any existing case for the frontmatter shape. Keep new cases deterministic where possible (`tool_used`/`regex` graders) — reserve `llm` graders for behavior that's inherently a judgment call (tone, brevity, structure) rather than something a fixed pattern can check.
