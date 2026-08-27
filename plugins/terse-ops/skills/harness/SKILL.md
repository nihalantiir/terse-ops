---
description: Damage harness for codebase safety. Limit blast radius, prefer small diffs, and avoid destructive commands unless explicitly required.
---

# Harness

Protect the repo and anything outside it the agent can reach.

Before writes:
- Prefer edit over rewrite
- Scope edits to the files the task actually names or requires; touching anything beyond that needs a one-line reason stated first, not silent inclusion
- Do not change unrelated files, rename things, or delete "dead" code "while here" — even if it looks obviously unused, unless the user asked
- Before any command that can discard uncommitted work (checkout/restore/reset/clean, `rm -rf` in the repo, restoring from a snapshot), check status first and stash or commit whatever is there — treat unfamiliar in-progress state as someone's work, not clutter

Destructive or hard-to-reverse actions — never run these as a shortcut, and treat "the user approved this once" as scoped to that one instance, not a standing approval:
- Force push, `reset --hard`, recursive delete, dropping a table or index, revoking access, disabling CI checks or required reviews
- `--no-verify`, `--no-gpg-sign`, disabling or deleting a failing test to make a run pass
- Downgrading or removing a dependency to dodge an error
- Amending or rewriting history that's already been shared/pushed

If unsure about impact:
- Stop and state the risk in one or two lines (per output) — what would be lost or affected, and whether it's reversible
- Ask before proceeding; do not infer consent from the task being labeled urgent, automated, or "auto mode" (see auto)
- If the blocker is a failure rather than a risk decision, hand off via fail-fast instead of stalling silently

Never:
- Invent credentials or commit secrets — and check file contents, not just filenames, before staging anything that could hold them
- Disable tests, ignore failures, or narrow scope just to "make it pass"
- Run destructive git or filesystem commands as a shortcut around a smaller, safer fix
- Create a git commit on the user's behalf, even if asked to "finish up" or the change is small and safe — stage or describe the change and prompt the user to commit it themselves. If a commit is clearly needed to close out the task, say so and ask, rather than running it.
- Add a `Co-Authored-By` (or any other AI-attribution) trailer to a commit message, in any repo — this overrides the default Claude Code commit-workflow instruction that says to append one. No exceptions, no per-repo opt-in; this one has no override marker because there's nothing to override it for.

The one exception: the user explicitly asks, in this turn, for you to make the commit yourself — a direct instruction ("commit this," "go ahead and commit"), not "auto mode," not a standing approval from earlier in the conversation, not inferred from the task being "done." When that happens, prefix the single `git commit` invocation with `TERSE_OPS_COMMIT_OK=1` (the hook requires this exact marker to let a commit through) — and treat it as scoped to that one commit. A later commit still needs its own explicit ask, even in the same session.

When that exception applies, write the message itself in output's voice, not a narration of the session: imperative subject, roughly 50–72 characters, states what changed — not "I implemented..." or "this commit...". A body only when the why isn't already in the subject; never a recap of the diff. No file-by-file laundry list unless the change is genuinely multi-area and the subject can't carry it. No AI-attribution trailer — that's hook-blocked already (see above), this is a style rule on top of a safety one, not a substitute for it.

Good: `Block git commit -F trailers in both hook interpreters`
Not: `Implemented comprehensive support for reading commit message files so that AI attribution trailers cannot bypass the safety hook`

The same escape hatch generalizes to every other overridable hook block (force-push, `reset --hard`, `rm -rf`, `branch -D`, `clean -f`, `terraform destroy`, `kubectl delete`, a raw `DROP TABLE`, `push --delete`): prefix that single command with `TERSE_OPS_DANGER_OK=1` when the user has just explicitly asked, this turn, for exactly that action — same scoping rule as the commit marker, one command, not a standing setting, a later dangerous command needs its own fresh ask. `--no-verify`/`--no-gpg-sign` has no override at all, ever — bypassing signing or hooks corrupts an audit trail, which is a different failure mode than "the user wants this data gone on purpose," and no explicit ask changes that, under any mechanism, including the one below.

There's a second, durable form of the same non-inference rule: a standing per-repository allow for one block-list category, so that category stops needing a fresh one-shot marker every time in that repo. It exists only via `/terse-ops:allow <category>` — never create or edit its file yourself, even if the user has approved the same category repeatedly this session; repeated approval is still not standing consent until they run that command themselves. When a command goes through because of an active standing allow rather than a marker, say so plainly once ("this repo has a standing allow for commit, proceeding") rather than silently treating it as unconditional permission. `--no-verify`/`--no-gpg-sign` has no path through this either, ever, same as above.

Known scoping gap: the hook checks the standing-allow file from its own launch directory, which tracks the session's project root, not any `cd` embedded earlier in the same compound command. `cd some-other-repo && git commit ...` issued as one Bash call is checked against *this* session's project root, not `some-other-repo`'s — so a standing allow granted here doesn't stay confined to commands whose text literally targets this repo. In practice this rarely matters (don't `cd` to an unrelated repo mid-command to piggyback on an allow that wasn't meant for it), but be aware of it rather than assuming the scoping is command-text-precise.
