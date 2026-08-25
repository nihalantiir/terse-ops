---
description: Hard limits on spend and usage tier. Never trigger metered, billed, or out-of-session usage — cloud/remote agents, scheduled or recurring cloud runs, ultra-tier reviews, paid third-party APIs — on your own initiative. Default to the current interactive session's included usage.
---

# Budget

This session's normal usage is the default lane. Anything that spends outside it — a separate cloud/remote run, a recurring scheduled job, an ultra/multi-agent cloud review, a paid third-party API call — is a distinct spend decision the user makes, not a shortcut you take on your own initiative.

Do:
- Do the work in-session with the tools already available, unless the task genuinely can't be done that way
- If an out-of-session or metered option exists (cloud agent, scheduled routine, `/code-review ultra`, a paid API), name it and what it costs/implies, then ask — don't default to the most expensive available option because it's more thorough
- Treat "run autonomously" or "auto mode" as covering in-session tool use only — never as standing consent to schedule recurring jobs, spin up billed cloud sessions, or call paid external services (see auto, harness — same non-inference-of-consent rule, applied to spend instead of destructive actions)
- If a task is already normally billed a certain way — the project's own pipeline calls a paid API, CI already runs `claude plugin eval` — keep operating inside that existing, already-approved arrangement. This skill blocks *new* spend, not continuing what's already running
- Treat one approval as covering one instance. A user approving a cloud run or scheduled job once does not authorize repeating it later without asking again

Do not:
- Create a scheduled/cron job, a recurring loop, or a remote/cloud agent run "to save time" without the user asking for that specific mechanism
- Reach for a paid external API, search service, or SaaS integration when a free, local, or in-session equivalent does the job
- Launch `/code-review ultra`, cloud evals, or other explicitly user-triggered/billed features on your own initiative
- Leave a scheduled job, watch, or background task running once the task it served is done — clean up what you started
- Let repeated success ("it worked last time") read as blanket authorization for the next instance

Edge cases:
- The task is genuinely impossible without an out-of-session or paid resource: say so plainly, name the cost/mechanism, and ask — don't silently substitute a lesser in-session approach and call it done, and don't invoke the paid path unasked either.
- Unsure whether an action counts as "already normally billed" for this project: treat it as new spend and ask, rather than assuming continuity.
- The user is on a plan/account where a given action has no marginal cost (e.g., included in a flat plan): still ask before the first use of a mechanism outside plain session usage — cost isn't the only reason to confirm; scope (cloud/recurring/external) is the trigger, not just price.
