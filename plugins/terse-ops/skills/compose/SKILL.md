---
description: How terse-ops behaves alongside other, domain-specific plugins or skills active in the same session. terse-ops owns voice, routing, safety, and spend — never the domain work itself. Use whenever another plugin's or skill's instructions are also in play for the current task.
---

# Compose

terse-ops is a base layer, not a specialist. When a domain-specific skill or plugin — a framework, an infra tool, a language convention, a review workflow — is also active for this task, let it own the actual domain work. terse-ops's job is what governs underneath it, not instead of it.

Do:
- Follow the domain skill's guidance for the actual how-to of the task (the React pattern, the Terraform layout, the SQL shape, the review checklist) — terse-ops has no opinion there and shouldn't invent one
- Keep applying terse-ops's own rules no matter which domain skill is active: terse output (output), cost-aware routing and delegation (orchestrate, economy), spend limits (budget), reasoning-effort discipline (reasoning), and the safety hook (harness) — these don't switch off because another skill is in play
- When a domain skill requires a specific artifact shape (a commit message convention, a generated file's template, a required verbosity for a legal/compliance document), let that shape stand — it's the content, not the surrounding conversation, and output's brevity rules apply to your reply about it, not to it

Do not:
- Let output's or economy's brevity push you to skip a domain skill's required step (a checklist item, a required file, a template section) to save tokens — that's not what those skills are for
- Let a domain skill's instructions override harness's hard block list or budget's spend limits — safety and spend rules win on any actual conflict, always, without exception
- Reimplement what an active specialist plugin already does — if one covers this task, use it rather than improvising an equivalent from scratch
- Treat terse-ops as "the main plugin" that other plugins report to — it has no authority over domain decisions, only over the style/safety/spend layer everything runs inside

Edge cases:
- No domain-specific skill or plugin is active for this task: nothing to compose with — just apply terse-ops's own rules normally.
- Two active domain skills give conflicting how-to guidance for the same piece of work: that's a domain-level conflict outside terse-ops's scope — flag it and ask, don't silently pick a side.
- A domain skill's own output is inherently long (a generated report, a legal document, a data export): that's the artifact's required shape, not something to compress — this skill's compression rules govern the conversation around it, not content another skill deliberately specified.
