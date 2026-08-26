#!/bin/sh
# Local, ungated test suite for block-dangerous.sh -- exercises the same
# PreToolUse payload shape Claude Code sends (JSON on stdin with a
# tool_input.command string) and asserts the hook's exit code: 0 = allowed,
# 2 = blocked. Runs anywhere `sh` runs, no `claude plugin eval` gate, no API
# cost -- see ../evals/README.md for the separate, gated eval suite this
# complements. Mirrors run-tests.ps1 case-for-case; keep both in sync by
# hand, same as the two hook scripts themselves.
set -u

hook_dir="$(dirname "$0")"
HOOK="$hook_dir/../hooks/block-dangerous.sh"
pass=0
fail=0

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

run_case() {
  expect="$1"
  desc="$2"
  cmd="$3"
  esc="$(json_escape "$cmd")"
  payload="{\"tool_input\":{\"command\":\"$esc\"}}"
  out="$(printf '%s' "$payload" | sh "$HOOK" 2>&1)"
  code=$?
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

# --- overrides: the scoped bypass works, and the two absolute blocks refuse it ---
run_case ALLOW "danger-ok overrides force-push"       'TERSE_OPS_DANGER_OK=1 git push --force origin main'
run_case ALLOW "commit-ok overrides commit"           'TERSE_OPS_COMMIT_OK=1 git commit -m "wip"'
run_case ALLOW "danger-ok also overrides commit"      'TERSE_OPS_DANGER_OK=1 git commit -m "wip"'
run_case BLOCK "no override defeats --no-verify"      'TERSE_OPS_DANGER_OK=1 git commit -m "x" --no-verify'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
