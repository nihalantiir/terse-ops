#!/bin/sh
# PreToolUse guard for Bash calls. Backs harness's hard "never" list with an
# actual block instead of relying on the model to remember the prompt.
# POSIX sh only, deliberately -- no bashisms -- because it's invoked as
# `sh block-dangerous.sh`, not executed directly, so this must run on
# whatever `sh` is present, not assume bash. See block-dangerous.ps1 for the
# Windows-without-bash fallback (hooks.json runs both; harmless redundancy
# where both interpreters exist).
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

# Default is never commit on the user's behalf. The one exception: the user
# just explicitly asked, this turn, for the commit itself (not "auto mode",
# not implied) — that's signaled by prefixing the single command with
# TERSE_OPS_COMMIT_OK=1, which only takes effect for that one invocation.
# See harness for the rule on when that prefix is and isn't appropriate.
is_commit_cmd=0
case "$cmd" in
  *git\ *commit*|*git\ *cherry-pick*--continue*) is_commit_cmd=1 ;;
esac
if [ "$is_commit_cmd" = 1 ]; then
  case "$cmd" in
    *TERSE_OPS_COMMIT_OK=1*) : ;;
    *) deny "terse-ops harness: git commit is blocked. Default rule is never commit on the user's behalf — stage the change and ask them to commit it. If they just explicitly asked you to commit it yourself this turn, prefix the command with TERSE_OPS_COMMIT_OK=1 (see harness) — don't reuse that prefix on a later commit without asking again." ;;
  esac
fi

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

case "$cmd" in
  *git\ *push*--delete*)
    deny "terse-ops harness: git push --delete is blocked. Deleting a remote branch/tag is hard to reverse — confirm with the user and have them run it." ;;
esac

case "$cmd" in
  *terraform*destroy*)
    deny "terse-ops harness: terraform destroy is blocked. It tears down provisioned infrastructure — confirm with the user and have them run it." ;;
esac

case "$cmd" in
  *kubectl*delete*)
    deny "terse-ops harness: kubectl delete is blocked. Deleting cluster resources can be destructive and hard to reverse — confirm with the user and have them run it, or scope to a read-only check first." ;;
esac

# Case-insensitive: SQL keywords vary in case, unlike the CLI flags above.
lc_cmd="$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')"
case "$lc_cmd" in
  *drop\ table*)
    deny "terse-ops harness: a raw DROP TABLE is blocked. Dropping a table is destructive and usually irreversible — confirm with the user before running it." ;;
esac

# branch -D is a force-delete that skips the merged check; -d (lowercase) is
# safe and left alone. Flags can combine (-Df, -fD) so check tokens, not a
# fixed string.
branch_segment="$(printf '%s' "$cmd" | grep -oE '(^|[;&|[:space:]])branch([[:space:]][^;&|]*|$)' | head -1)"
if [ -n "$branch_segment" ]; then
  for tok in $branch_segment; do
    case "$tok" in
      -*) case "$tok" in *D*) deny "terse-ops harness: git branch -D is blocked. It force-deletes an unmerged branch — confirm with the user or use -d on a merged branch." ;; esac ;;
    esac
  done
fi

# clean -f/-x can delete untracked (and ignored, with -x) files with no
# undo. Flags combine (-fd, -fdx) so check tokens, same approach as rm -rf.
clean_segment="$(printf '%s' "$cmd" | grep -oE '(^|[;&|[:space:]])clean([[:space:]][^;&|]*|$)' | head -1)"
if [ -n "$clean_segment" ]; then
  for tok in $clean_segment; do
    case "$tok" in
      --force) deny "terse-ops harness: git clean -f is blocked. It permanently deletes untracked files — confirm with the user first." ;;
      -*) case "$tok" in *f*) deny "terse-ops harness: git clean -f is blocked. It permanently deletes untracked files — confirm with the user first." ;; esac ;;
    esac
  done
fi

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
