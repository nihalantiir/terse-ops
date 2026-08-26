#!/bin/sh
# Local, ungated test suite for block-dangerous.sh -- exercises the same
# PreToolUse payload shape Claude Code sends (JSON on stdin with a
# tool_input.command string) and asserts the hook's exit code: 0 = allowed,
# 2 = blocked. Runs anywhere `sh` runs, no `claude plugin eval` gate, no API
# cost -- see ../evals/README.md for the separate, gated eval suite this
# complements. Mirrors run-tests.ps1 case-for-case; keep both in sync by
# hand, same as the two hook scripts themselves.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/hooks/block-dangerous.sh"
pass=0
fail=0

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

record_result() {
  expect="$1"
  desc="$2"
  cmd="$3"
  code="$4"
  out="$5"
  if [ "$expect" = "BLOCK" ]; then
    if [ "$code" -eq 2 ]; then
      pass=$((pass + 1))
    else
      fail=$((fail + 1))
      printf 'FAIL [expected BLOCK, got exit %s]: %s\n  cmd: %s\n' "$code" "$desc" "$cmd"
    fi
  else
    if [ "$code" -eq 0 ]; then
      pass=$((pass + 1))
    else
      fail=$((fail + 1))
      printf 'FAIL [expected ALLOW, got exit %s]: %s\n  cmd: %s\n  output: %s\n' "$code" "$desc" "$cmd" "$out"
    fi
  fi
}

run_case() {
  expect="$1"
  desc="$2"
  cmd="$3"
  esc="$(json_escape "$cmd")"
  payload="{\"tool_input\":{\"command\":\"$esc\"}}"
  out="$(printf '%s' "$payload" | sh "$HOOK" 2>&1)"
  code=$?
  record_result "$expect" "$desc" "$cmd" "$code" "$out"
}

# Scaffolds a throwaway repo dir (a bare .git marker, no real `git init`
# needed -- the hook only checks .git's existence), optionally writes a
# standing-allow file, invokes the hook with cwd set inside it (optionally a
# nested subdir, to prove the walk-up-to-root logic), then cleans up.
#   $4 allow_contents -- allow file body, or empty for no file at all
#   $5 subdir         -- relative subdir to invoke from, or empty for repo root
#   $6 no_git         -- "1" to skip creating .git (proves "no repo found" behavior)
run_case_repo() {
  expect="$1"
  desc="$2"
  cmd="$3"
  allow_contents="$4"
  subdir="$5"
  no_git="${6:-0}"

  tmp="$(mktemp -d)"
  [ "$no_git" = "1" ] || mkdir "$tmp/.git"
  if [ -n "$allow_contents" ]; then
    mkdir -p "$tmp/.claude"
    printf '%s\n' "$allow_contents" >"$tmp/.claude/terse-ops-allow.local.txt"
  fi
  invoke_dir="$tmp"
  if [ -n "$subdir" ]; then
    invoke_dir="$tmp/$subdir"
    mkdir -p "$invoke_dir"
  fi

  esc="$(json_escape "$cmd")"
  payload="{\"tool_input\":{\"command\":\"$esc\"}}"
  out="$(cd "$invoke_dir" && printf '%s' "$payload" | sh "$HOOK" 2>&1)"
  code=$?
  rm -rf "$tmp"

  record_result "$expect" "$desc" "$cmd" "$code" "$out"
}

# --- blocked: the hard "never" list ---
run_case BLOCK "commit with message"                  'git commit -m "wip"'
run_case BLOCK "commit, no flags"                     'git commit'
run_case BLOCK "cherry-pick --continue"               'git cherry-pick --continue'
run_case BLOCK "force-push, long flag"                'git push --force origin main'
run_case BLOCK "force-push, short flag"               'git push -f origin main'
run_case BLOCK "force-with-lease"                     'git push --force-with-lease origin main'
run_case BLOCK "push --delete"                        'git push origin --delete old-branch'
run_case BLOCK "reset --hard"                         'git reset --hard HEAD~1'
run_case BLOCK "branch -D"                            'git branch -D feature/old'
run_case BLOCK "branch -Df combined"                  'git branch -Df feature/old'
run_case BLOCK "clean -f"                             'git clean -f'
run_case BLOCK "clean -fd combined"                   'git clean -fd'
run_case BLOCK "clean --force"                        'git clean --force'
run_case BLOCK "rm -rf"                               'rm -rf build/'
run_case BLOCK "rm -fr reversed"                      'rm -fr build/'
run_case BLOCK "rm -r -f separate flags"              'rm -r -f build/'
run_case BLOCK "rm --recursive --force long flags"    'rm --recursive --force build/'
run_case BLOCK "terraform destroy"                    'terraform destroy -auto-approve'
run_case BLOCK "kubectl delete deployment"            'kubectl delete deployment web'
run_case BLOCK "kubectl delete pod --all-namespaces"  'kubectl delete pod --all-namespaces'
run_case BLOCK "DROP TABLE uppercase"                 'psql -c "DROP TABLE users"'
run_case BLOCK "drop table lowercase"                 'psql -c "drop table users"'
run_case BLOCK "--no-verify"                          'git commit -m "x" --no-verify'
run_case BLOCK "--no-gpg-sign"                        'git commit -m "x" --no-gpg-sign'

# --- allowed: known false-positive traps the harness must not trip on ---
run_case ALLOW "plain git log"                        'git log'
run_case ALLOW "commit word in unrelated segment"     'git log && echo "committed"'
run_case ALLOW "long flag containing D"               'git branch --set-upstream-to=origin/DEV'
run_case ALLOW "long flag containing f"               'git clean --exclude=foo.log'
run_case ALLOW "long flags containing r and f"        'rm --preserve-root --one-file-system'
run_case ALLOW "kubectl delete plain pod"             'kubectl delete pod mypod'
run_case ALLOW "kubectl delete pods plural"           'kubectl delete pods mypod'
run_case ALLOW "branch -d lowercase, merged"          'git branch -d merged-feature'
run_case ALLOW "plain git status"                     'git status'

# --- one-shot overrides: the marker works, and the two absolute blocks refuse it ---
run_case ALLOW "danger-ok overrides force-push"       'TERSE_OPS_DANGER_OK=1 git push --force origin main'
run_case ALLOW "commit-ok overrides commit"           'TERSE_OPS_COMMIT_OK=1 git commit -m "wip"'
run_case ALLOW "danger-ok also overrides commit"      'TERSE_OPS_DANGER_OK=1 git commit -m "wip"'
run_case BLOCK "no override defeats --no-verify"      'TERSE_OPS_DANGER_OK=1 git commit -m "x" --no-verify'

# --- standing per-repo allow (/terse-ops:allow): durable, category-scoped, revocable ---
run_case_repo ALLOW "standing allow: commit granted"                 'git commit -m "wip"'              'commit'         ''    0
run_case_repo ALLOW "standing allow: force-push granted"             'git push --force origin main'      'force-push'     ''    0
run_case_repo BLOCK "standing allow: category scoping (commit-only doesn't cover force-push)" \
                                                                      'git push --force origin main'      'commit'         ''    0
run_case_repo BLOCK "standing allow: --no-verify still absolute"     'git commit -m "x" --no-verify'      'commit'         ''    0
run_case_repo BLOCK "standing allow: empty/comment-only file grants nothing" \
                                                                      'git commit -m "wip"'  '# nothing granted yet'         ''    0
run_case_repo BLOCK "standing allow: file with no .git above it is inert" \
                                                                      'git commit -m "wip"'              'commit'         ''    1
run_case_repo ALLOW "standing allow: walk-up finds root from nested subdir" \
                                                                      'git commit -m "wip"'              'commit'  'a/b/c'      0

# Revoke: grant, confirm allowed, then remove the file in the same repo dir
# and confirm the block comes back -- proves revoke actually restores
# default behavior, not just that an unrelated fresh repo blocks by default.
tmp="$(mktemp -d)"
mkdir "$tmp/.git" "$tmp/.claude"
printf '%s\n' "commit" >"$tmp/.claude/terse-ops-allow.local.txt"
payload='{"tool_input":{"command":"git commit -m \"wip\""}}'
out="$(cd "$tmp" && printf '%s' "$payload" | sh "$HOOK" 2>&1)"
record_result ALLOW "standing allow: granted before revoke" 'git commit -m "wip"' "$?" "$out"
rm -f "$tmp/.claude/terse-ops-allow.local.txt"
out="$(cd "$tmp" && printf '%s' "$payload" | sh "$HOOK" 2>&1)"
record_result BLOCK "standing allow: revoke restores the block" 'git commit -m "wip"' "$?" "$out"
rm -rf "$tmp"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
