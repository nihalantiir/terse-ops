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

# Every check below runs per-segment, not against the whole raw command
# line. Without this, a compound command's own control operators (&&, ;, |)
# don't bound the pattern matches: `git log && echo "committed"` would
# false-positive the commit block on the word inside an unrelated echo,
# since "git" and "commit" both appear *somewhere* in the line, just not in
# the same clause. Splitting on control-operator characters first, then
# matching within each piece, keeps every rule scoped to one logical
# command. This doesn't understand quoting (a literal ";" inside a quoted
# string still splits), which is a known, accepted gap -- the previous
# behavior was strictly worse (no scoping at all), not this plus something
# else.
segments="$(printf '%s' "$cmd" | tr ';&|' '\n\n\n')"

check_segment() {
  seg="$1"

  # Default is never commit on the user's behalf. Exception: the user just
  # explicitly asked, this turn, for the commit itself -- signaled by
  # prefixing the single command with TERSE_OPS_COMMIT_OK=1 (see harness).
  is_commit_cmd=0
  case "$seg" in
    *git\ *commit*|*git\ *cherry-pick*--continue*) is_commit_cmd=1 ;;
  esac
  if [ "$is_commit_cmd" = 1 ]; then
    case "$seg" in
      *TERSE_OPS_COMMIT_OK=1*) : ;;
      *) deny "terse-ops harness: git commit is blocked. Default rule is never commit on the user's behalf — stage the change and ask them to commit it. If they just explicitly asked you to commit it yourself this turn, prefix the command with TERSE_OPS_COMMIT_OK=1 (see harness) — don't reuse that prefix on a later commit without asking again." ;;
    esac
  fi

  case "$seg" in
    *git\ *push*--force*|*git\ *push*\ -f\ *|*git\ *push*\ -f)
      deny "terse-ops harness: force-push is blocked. Confirm with the user and have them run it, or get explicit sign-off first." ;;
  esac

  case "$seg" in
    *--no-verify*|*--no-gpg-sign*)
      deny "terse-ops harness: --no-verify/--no-gpg-sign is blocked. Do not bypass hooks or signing to force a command through." ;;
  esac

  case "$seg" in
    *reset\ *--hard*)
      deny "terse-ops harness: git reset --hard is blocked. It discards uncommitted work — stash first or confirm with the user." ;;
  esac

  case "$seg" in
    *git\ *push*--delete*)
      deny "terse-ops harness: git push --delete is blocked. Deleting a remote branch/tag is hard to reverse — confirm with the user and have them run it." ;;
  esac

  case "$seg" in
    *terraform*destroy*)
      deny "terse-ops harness: terraform destroy is blocked. It tears down provisioned infrastructure — confirm with the user and have them run it." ;;
  esac

  # kubectl delete pod/pods is routine -- a controller reschedules it, so
  # it's closer to a restart than a deletion. Anything else (deployment,
  # namespace, pvc, secret, a -f manifest that could define any kind...)
  # isn't self-healing and stays blocked. --all-namespaces stays blocked
  # even for pods -- that's cluster-wide, not a single restart.
  case "$seg" in
    *kubectl*delete*)
      saw_delete=0
      resource=""
      cluster_wide=0
      for tok in $seg; do
        if [ "$saw_delete" = 0 ]; then
          case "$tok" in delete) saw_delete=1 ;; esac
          continue
        fi
        case "$tok" in
          --all-namespaces|-A) cluster_wide=1 ;;
          -*) : ;;
          *) [ -z "$resource" ] && resource="${tok%%/*}" ;;
        esac
      done
      if [ "$saw_delete" = 1 ]; then
        case "$resource" in
          pod|pods|po)
            if [ "$cluster_wide" = 1 ]; then
              deny "terse-ops harness: kubectl delete pod --all-namespaces is blocked. That's cluster-wide, not a routine single-pod restart — confirm with the user first."
            fi ;;
          *)
            deny "terse-ops harness: kubectl delete is blocked (resource: ${resource:-unspecified}). Deleting anything other than a pod isn't self-healing under a controller and can be destructive or hard to reverse — confirm with the user, or scope to a read-only check first." ;;
        esac
      fi
      ;;
  esac

  # Case-insensitive: SQL keywords vary in case, unlike the CLI flags above.
  lc_seg="$(printf '%s' "$seg" | tr '[:upper:]' '[:lower:]')"
  case "$lc_seg" in
    *drop\ table*)
      deny "terse-ops harness: a raw DROP TABLE is blocked. Dropping a table is destructive and usually irreversible — confirm with the user before running it." ;;
  esac

  # branch -D is a force-delete that skips the merged check; -d (lowercase)
  # is safe and left alone. Flags can combine (-Df, -fD) so check tokens,
  # not a fixed string. Restricted to single-dash clusters (-[!-]*): a long
  # flag like --set-upstream-to=origin/DEV starts with "--" and would
  # otherwise false-positive on the literal "D" in a branch name it carries
  # as free text.
  case "$seg" in
    *branch*)
      for tok in $seg; do
        case "$tok" in
          -[!-]*) case "$tok" in *D*) deny "terse-ops harness: git branch -D is blocked. It force-deletes an unmerged branch — confirm with the user or use -d on a merged branch." ;; esac ;;
        esac
      done
      ;;
  esac

  # clean -f/-x can delete untracked (and ignored, with -x) files with no
  # undo. Flags combine (-fd, -fdx) so check tokens, same approach as
  # rm -rf. Restricted to single-dash clusters, same reason as branch above
  # -- a long flag like --exclude=foo.log would otherwise false-positive on
  # its own pattern argument containing an "f".
  case "$seg" in
    *clean*)
      for tok in $seg; do
        case "$tok" in
          --force) deny "terse-ops harness: git clean -f is blocked. It permanently deletes untracked files — confirm with the user first." ;;
          -[!-]*) case "$tok" in *f*) deny "terse-ops harness: git clean -f is blocked. It permanently deletes untracked files — confirm with the user first." ;; esac ;;
        esac
      done
      ;;
  esac

  # Recursive + force can arrive combined (-rf), reversed (-fr), long-form
  # (--recursive --force), or as separate short flags (-r -f) in either
  # order. Long flags are matched by exact name only, not substring:
  # --preserve-root contains "r" and --one-file-system contains "f", and
  # together they'd otherwise false-positive as "recursive + force" despite
  # being neither.
  case "$seg" in
    *rm\ *)
      has_r=0
      has_f=0
      for tok in $seg; do
        case "$tok" in
          rm) continue ;;
          --recursive) has_r=1 ;;
          --force) has_f=1 ;;
          -[!-]*)
            case "$tok" in *r*) has_r=1 ;; esac
            case "$tok" in *f*) has_f=1 ;; esac
            ;;
        esac
      done
      if [ "$has_r" = 1 ] && [ "$has_f" = 1 ]; then
        deny "terse-ops harness: rm -rf is blocked. Delete narrowly and explicitly, or ask the user before a recursive force-delete."
      fi
      ;;
  esac
}

# Split into segments using a temporary IFS, then restore it immediately --
# check_segment's own `for tok in $seg` loops need normal space-splitting,
# not the newline-only IFS used just to break $segments into lines.
old_ifs=$IFS
IFS='
'
set -- $segments
IFS=$old_ifs

for segment in "$@"; do
  check_segment "$segment"
done

exit 0
