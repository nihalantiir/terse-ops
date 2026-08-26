# Terse Ops

A Claude Code plugin marketplace for concise, disciplined, cost-aware agentic work.

The top model plans, delegates, and verifies. Cheaper models do the mechanical labor beneath it. A hook-enforced damage harness limits blast radius. Failures are reported once, not researched forever.

Not related to TERSE state language, TerseAI workflows, or be-terse hooks — this is an original ops style: concise output, orchestrator role, and safety rules, packaged as a Claude Code plugin.

## Role of terse-ops

This governs *how* Claude works — voice, routing, spend limits, and repo safety. It doesn't own domain work: framework, infra, and language-specific plugins still do the actual React, Terraform, SQL, or whatever the task calls for. terse-ops just applies underneath them — output stays terse, destructive commands still get the hook, delegation still routes by cost — the same way regardless of which specialist plugin is doing the domain-specific part. If a domain plugin's own instructions conflict with a safety rule here (the hook block list, the no-commit default), the safety rule wins; style and routing rules are the part meant to be composed with, not fought. The `compose` skill is this rule made explicit and behavioral, not just documentation.

## Install

```
/plugin marketplace add nihalantiir/terse-ops
/plugin install terse-ops@terse-ops
```

## Updating

Same slash commands in both the CLI and the Claude web app (claude.ai/code):

```
/plugin marketplace update terse-ops
/plugin install terse-ops@terse-ops
```

The first refreshes the marketplace listing from this repo; the second pulls the plugin up to whatever version that listing now points to. If the result says `Run /reload-plugins to activate`, run that too — otherwise no restart is needed.

In the web app, the same actions live under `/plugin` → **Marketplaces** tab (update listings, or enable auto-update) and **Installed** tab (update the plugin) — there's no separate button outside that slash-command UI.

## What's in it

This marketplace currently ships one plugin: [`terse-ops`](plugins/terse-ops/README.md), which adds:

- **Skills** — a thin always-on core (output style incl. `clean`/`tight`/`grunt` compression, damage harness, fail-fast reporting, tool-call economy, composing with domain-specific plugins) plus six on-demand skills (orchestration/routing, delegate verification, auto-mode discipline, verified research, spend/usage-tier limits, reasoning-effort discipline) invoked explicitly when you want them active for a session
- **Commands** — `/terse-ops:route`, `/terse-ops:verify-now`, `/terse-ops:status`, `/terse-ops:mode`, `/terse-ops:solo`, plus one `/terse-ops:<name>` per on-demand skill above
- **Agents** — `scout`, `researcher`, `builder`, `checker`, and `architect`: matched-cost subagents for codebase search, web research, mechanical implementation, verification, and a deep-reasoning planning pass, so the orchestrator isn't doing every step itself at top-model cost
- **Hooks** — a `PreToolUse` guard that blocks the harness skill's hard "never" list (commits on your behalf, force-push, `--no-verify`, `rm -rf`, `reset --hard`, `branch -D`, `clean -f`, `terraform destroy`, `kubectl delete`, `DROP TABLE`) at the tool-call level, not just as a prompt instruction — most of them carry a scoped, explicit one-shot override, `--no-verify`/`--no-gpg-sign` never does
- **Evals** — `claude plugin eval` cases covering the hook blocks and output brevity (early access, not yet runnable — see `plugins/terse-ops/evals/README.md`)

See the [plugin README](plugins/terse-ops/README.md) for the full breakdown of each skill and agent.

## License

MIT — see [LICENSE](LICENSE).
