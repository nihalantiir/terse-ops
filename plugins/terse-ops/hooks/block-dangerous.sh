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

# Nearest ancestor directory containing a .git entry, starting from this
# process's own working directory. No `git` subprocess here -- this runs on
# every Bash call, and an existence check is enough to answer "is there a
# repo root to look for a standing allow in." Prints the root and returns 0,
# or returns 1 if none was found (e.g. not inside a repo at all).
find_repo_root() {
  dir="$(pwd)"
  while :; do
    [ -e "$dir/.git" ] && { printf '%s' "$dir"; return 0; }
    [ "$dir" = "/" ] && return 1
    parent="$(dirname "$dir")"
    [ "$parent" = "$dir" ] && return 1
    dir="$parent"
  done
}

# Standing, per-repo allow for one category of the block list below. Set up
# only via `/terse-ops:allow <category>`, never inferred by the model -- same
# non-inference rule as the one-shot marker, just durable instead of
# one-command-scoped (see harness). File is one category slug per line,
# blank lines and #-comments ignored. Never consulted for the
# --no-verify/--no-gpg-sign check further down -- that stays a bare deny(),
# on purpose, see the comment on that check.
category_allowed() {
  category="$1"
  root="$(find_repo_root)" || return 1
  allow_file="$root/.claude/terse-ops-allow.local.txt"
  [ -f "$allow_file" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|'#'*) continue ;;
    esac
    [ "$line" = "$category" ] && return 0
  done < "$allow_file"
  return 1
}

# Explicit, scoped bypass for the destructive/hard-to-reverse checks below --
# not for --no-verify/--no-gpg-sign, which stays absolute (bypassing
# signing/hooks is a different category from "delete this on purpose", see
# harness). Two ways through: the one-shot marker (signals the user
# explicitly asked, this turn, for exactly this action -- scoped to the one
# command it's prefixed on, not a standing setting) or a standing per-repo
# allow for this category (see category_allowed above). Checked in that
# order so the common, marker-only path pays no extra file I/O.
overridable_deny() {
  msg="$1"
  category="$2"
  case "$seg" in
    *TERSE_OPS_DANGER_OK=1*) return 0 ;;
  esac
  category_allowed "$category" && return 0
  deny "$msg Or run \`/terse-ops:allow $category\` so this repo stops asking every time (see harness)."
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
  lc_seg="$(printf '%s' "$seg" | tr '[:upper:]' '[:lower:]')"

  # AI-attribution commit trailer (Co-Authored-By/Generated-By/Signed-off-by
  # naming Claude or Anthropic, or the literal noreply@anthropic.com
  # address) has NO override, ever -- same class as --no-verify below.
  # Unconditional, not gated on "git commit" appearing in this same
  # segment: a multi-line message built via `$(cat <<'EOF' ... EOF)` puts
  # each body line in its own segment (real newlines split the same as
  # `;`/`&`/`|` here, see the segment-splitting note further down), so the
  # trailer line is often not in the same segment as the invocation itself.
  case "$lc_seg" in
    *co-authored-by*claude*|*co-authored-by*anthropic*|*generated-by*claude*|*generated-by*anthropic*|*signed-off-by*claude*|*signed-off-by*anthropic*|*noreply@anthropic.com*)
      deny "terse-ops harness: an AI-attribution commit trailer (Co-Authored-By/Generated-By/Signed-off-by naming Claude or Anthropic, or noreply@anthropic.com) is blocked. Never attribute a commit to Claude/Anthropic, in any repo. This has no override, ever." ;;
  esac

  # Default is never commit on the user's behalf. Two ways through: the
  # one-shot marker (the user just explicitly asked, this turn, for the
  # commit itself) or a standing per-repo allow for "commit" (see
  # category_allowed above, set up only via /terse-ops:allow commit).
  is_commit_cmd=0
  case "$seg" in
    *git\ *commit*|*git\ *cherry-pick*--continue*) is_commit_cmd=1 ;;
  esac
  if [ "$is_commit_cmd" = 1 ]; then
    case "$seg" in
      *TERSE_OPS_COMMIT_OK=1*|*TERSE_OPS_DANGER_OK=1*) : ;;
      *)
        category_allowed commit || deny "terse-ops harness: git commit is blocked. Default rule is never commit on the user's behalf — stage the change and ask them to commit it. If they just explicitly asked you to commit it yourself this turn, prefix the command with TERSE_OPS_COMMIT_OK=1 (see harness) — don't reuse that prefix on a later commit without asking again. Or run \`/terse-ops:allow commit\` so this repo stops asking every time."
        ;;
    esac
  fi

  case "$seg" in
    *git\ *push*--force*|*git\ *push*\ -f\ *|*git\ *push*\ -f)
      overridable_deny "terse-ops harness: force-push is blocked. Confirm with the user and have them run it, or get explicit sign-off first — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." force-push ;;
  esac

  # --no-verify/--no-gpg-sign has NO override, ever -- not the one-shot
  # marker, not a standing allow, no exceptions. Bypassing signing or hooks
  # corrupts an audit trail, a different failure mode than "the user wants
  # this data gone on purpose." DO NOT wire a category_allowed check into
  # this branch, on a future hand-sync edit or otherwise -- see harness.
  case "$seg" in
    *--no-verify*|*--no-gpg-sign*)
      deny "terse-ops harness: --no-verify/--no-gpg-sign is blocked. Do not bypass hooks or signing to force a command through. This one has no override — it's a different category from a destructive-on-purpose action." ;;
  esac

  case "$seg" in
    *reset\ *--hard*)
      overridable_deny "terse-ops harness: git reset --hard is blocked. It discards uncommitted work — stash first or confirm with the user — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." reset-hard ;;
  esac

  case "$seg" in
    *git\ *push*--delete*)
      overridable_deny "terse-ops harness: git push --delete is blocked. Deleting a remote branch/tag is hard to reverse — confirm with the user and have them run it — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." push-delete ;;
  esac

  case "$seg" in
    *terraform*destroy*)
      overridable_deny "terse-ops harness: terraform destroy is blocked. It tears down provisioned infrastructure — confirm with the user and have them run it — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." terraform-destroy ;;
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
              overridable_deny "terse-ops harness: kubectl delete pod --all-namespaces is blocked. That's cluster-wide, not a routine single-pod restart — confirm with the user first — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." kubectl-delete
            fi ;;
          *)
            overridable_deny "terse-ops harness: kubectl delete is blocked (resource: ${resource:-unspecified}). Deleting anything other than a pod isn't self-healing under a controller and can be destructive or hard to reverse — confirm with the user, or scope to a read-only check first — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." kubectl-delete ;;
        esac
      fi
      ;;
  esac

  # Case-insensitive: SQL keywords vary in case, unlike the CLI flags above.
  # (lc_seg already computed at the top of this function.)
  case "$lc_seg" in
    *drop\ table*)
      overridable_deny "terse-ops harness: a raw DROP TABLE is blocked. Dropping a table is destructive and usually irreversible — confirm with the user before running it — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." drop-table ;;
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
          -[!-]*) case "$tok" in *D*) overridable_deny "terse-ops harness: git branch -D is blocked. It force-deletes an unmerged branch — confirm with the user or use -d on a merged branch — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." branch-delete ;; esac ;;
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
          --force) overridable_deny "terse-ops harness: git clean -f is blocked. It permanently deletes untracked files — confirm with the user first — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." clean-force ;;
          -[!-]*) case "$tok" in *f*) overridable_deny "terse-ops harness: git clean -f is blocked. It permanently deletes untracked files — confirm with the user first — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." clean-force ;; esac ;;
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
        overridable_deny "terse-ops harness: rm -rf is blocked. Delete narrowly and explicitly, or ask the user before a recursive force-delete — or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." rm-rf
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
