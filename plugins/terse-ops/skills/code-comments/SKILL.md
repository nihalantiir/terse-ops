---
description: Keep comments limited to non-obvious why; never restate what code does, narrate a class/function's role, or reference this session's changes. Applies to any Edit or Write on source files.
---

# Code comments

Well-named code already says what it does. A comment earns its place only when it captures something the code cannot: a hidden constraint, a subtle invariant, a workaround for a specific bug, or a reason a reader would otherwise get wrong.

Do:
- Write a comment only for the why that isn't visible in the code — a non-obvious invariant, a spec/protocol requirement, a workaround for a specific external bug, an ordering constraint that looks arbitrary but isn't
- Keep it to one line where the why fits in one; needing a paragraph is usually a sign it's explaining what, not why
- Let identifiers carry the "what" — if a comment restates the function/class name in plain English, delete the comment or rename instead

Do not:
- Restate what the code does ("increments the counter", "loops over users") — the code already says that
- Write class/function-doc blurbs narrating a component's role or relationships ("Owns the X... every other Y is built on top of this...") — that's an architecture-doc concern, not inline narration
- Reference the current task, session, or a fix ("added this to fix X", "handles the case from issue #123", "used by the Y flow") — that belongs in the commit message, not the source, and rots as the code moves on
- Add a comment just because a block looks complex — simplify or rename first; comment only if the why still isn't captured after that
- Leave a comment that would confuse nobody if removed — if removing it loses nothing, don't write it

Before reporting an edit done, reread any comment you just wrote or left standing: if it restates an identifier, narrates a role, or references this task/session, delete it.

Edge cases:
- A docstring shape required by language/team convention (JSDoc, type-hint docstrings, generated docs) is the artifact's required form, not narration — keep it, but still cut restatement inside it (see compose on domain-required shapes).
- A genuinely non-obvious why can run long (citing a spec section, explaining a race condition) — length is fine when every line is load-bearing; the rule is against restating, not against every multi-line comment.
- Pre-existing narrative comments outside the current task's scope: not obligated to hunt them down, but don't add more, and clean up what's there if you're already touching that code for another reason.
