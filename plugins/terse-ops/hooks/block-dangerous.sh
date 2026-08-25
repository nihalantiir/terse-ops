#!/usr/bin/env bash
# PreToolUse guard for Bash calls. Backs harness's hard "never" list with an
# actual block instead of relying on the model to remember the prompt.
set -u

input="$(cat)"

# Pull the JSON "command" field's string value out of the tool_input payload.
# Falls back to scanning the whole payload if extraction comes up empty, so a
# parsing miss fails toward blocking rather than silently letting it through.
cmd="$(printf '%s' "$input" | grep -o '"command"[[:space:]]*:[[:space:]]*"\([^"\\]\|\\.\)*"' | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')"
[ -z "$cmd" ] && cmd="$input"

deny() {
  printf '%s\n' "$1" >&2
  exit 2
}

case "$cmd" in
  *git\ *commit*|*git\ *cherry-pick*--continue*)
    deny "terse-ops harness: git commit is blocked. This plugin's rule is never commit on the user's behalf — stage the change and ask them to commit it." ;;
esac

case "$cmd" in
  *git\ *push*--force*|*git\ *push*\ -f\ *|*git\ *push*\ -f)
    deny "terse-ops harness: force-push is blocked. Confirm with the user and have them run it, or get explicit sign-off first." ;;
esac

case "$cmd" in
  *--no-verify*|*--no-gpg-sign*)
    deny "terse-ops harness: --no-verify/--no-gpg-sign is blocked. Do not bypass hooks or signing to force a command through." ;;
esac

case "$cmd" in
  *reset\ *--hard*)
    deny "terse-ops harness: git reset --hard is blocked. It discards uncommitted work — stash first or confirm with the user." ;;
esac

# Recursive + force can arrive combined (-rf), reversed (-fr), long-form
# (--recursive --force), or as separate short flags (-r -f) in either order —
# check the segment from "rm" to the next control operator token by token
# instead of relying on one regex to catch every flag ordering.
rm_segment="$(printf '%s' "$cmd" | grep -oE '(^|[;&|[:space:]])rm([[:space:]][^;&|]*|$)' | head -1)"
if [ -n "$rm_segment" ]; then
  has_r=0
  has_f=0
  for tok in $rm_segment; do
    case "$tok" in
      rm) continue ;;
      --recursive) has_r=1 ;;
      --force) has_f=1 ;;
      -*)
        case "$tok" in *r*) has_r=1 ;; esac
        case "$tok" in *f*) has_f=1 ;; esac
        ;;
    esac
  done
  if [ "$has_r" = 1 ] && [ "$has_f" = 1 ]; then
    deny "terse-ops harness: rm -rf is blocked. Delete narrowly and explicitly, or ask the user before a recursive force-delete."
  fi
fi

exit 0
