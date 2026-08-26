# Local, ungated test suite for block-dangerous.ps1 -- exercises the same
# PreToolUse payload shape Claude Code sends (JSON on stdin with a
# tool_input.command string) and asserts the hook's exit code: 0 = allowed,
# 2 = blocked. No `claude plugin eval` gate, no API cost -- see
# ../evals/README.md for the separate, gated eval suite this complements.
# Mirrors run-tests.sh case-for-case; keep both in sync by hand, same as the
# two hook scripts themselves.

$Hook = Join-Path $PSScriptRoot "..\hooks\block-dangerous.ps1"
$pass = 0
$fail = 0

function Invoke-Case {
    param([string]$Expect, [string]$Desc, [string]$Cmd)

    $payload = (@{ tool_input = @{ command = $Cmd } } | ConvertTo-Json -Compress)
    $out = $payload | & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Hook 2>&1
    $code = $LASTEXITCODE

    $ok = if ($Expect -eq 'BLOCK') { $code -eq 2 } else { $code -eq 0 }
    if ($ok) {
        $script:pass++
    } else {
        $script:fail++
        Write-Host "FAIL [expected $Expect, got exit $code]: $Desc"
        Write-Host "  cmd: $Cmd"
        if ($Expect -eq 'ALLOW') { Write-Host "  output: $out" }
    }
}

# --- blocked: the hard "never" list ---
Invoke-Case BLOCK "commit with message"                 'git commit -m "wip"'
Invoke-Case BLOCK "commit, no flags"                    'git commit'
Invoke-Case BLOCK "cherry-pick --continue"              'git cherry-pick --continue'
Invoke-Case BLOCK "force-push, long flag"               'git push --force origin main'
Invoke-Case BLOCK "force-push, short flag"              'git push -f origin main'
Invoke-Case BLOCK "force-with-lease"                    'git push --force-with-lease origin main'
Invoke-Case BLOCK "push --delete"                       'git push origin --delete old-branch'
Invoke-Case BLOCK "reset --hard"                        'git reset --hard HEAD~1'
Invoke-Case BLOCK "branch -D"                           'git branch -D feature/old'
Invoke-Case BLOCK "branch -Df combined"                 'git branch -Df feature/old'
Invoke-Case BLOCK "clean -f"                            'git clean -f'
Invoke-Case BLOCK "clean -fd combined"                  'git clean -fd'
Invoke-Case BLOCK "clean --force"                       'git clean --force'
Invoke-Case BLOCK "rm -rf"                              'rm -rf build/'
Invoke-Case BLOCK "rm -fr reversed"                     'rm -fr build/'
Invoke-Case BLOCK "rm -r -f separate flags"             'rm -r -f build/'
Invoke-Case BLOCK "rm --recursive --force long flags"   'rm --recursive --force build/'
Invoke-Case BLOCK "terraform destroy"                   'terraform destroy -auto-approve'
Invoke-Case BLOCK "kubectl delete deployment"           'kubectl delete deployment web'
Invoke-Case BLOCK "kubectl delete pod --all-namespaces" 'kubectl delete pod --all-namespaces'
Invoke-Case BLOCK "DROP TABLE uppercase"                'psql -c "DROP TABLE users"'
Invoke-Case BLOCK "drop table lowercase"                'psql -c "drop table users"'
Invoke-Case BLOCK "--no-verify"                         'git commit -m "x" --no-verify'
Invoke-Case BLOCK "--no-gpg-sign"                       'git commit -m "x" --no-gpg-sign'

# --- allowed: known false-positive traps the harness must not trip on ---
Invoke-Case ALLOW "plain git log"                       'git log'
Invoke-Case ALLOW "commit word in unrelated segment"    'git log && echo "committed"'
Invoke-Case ALLOW "long flag containing D"              'git branch --set-upstream-to=origin/DEV'
Invoke-Case ALLOW "long flag containing f"              'git clean --exclude=foo.log'
Invoke-Case ALLOW "long flags containing r and f"       'rm --preserve-root --one-file-system'
Invoke-Case ALLOW "kubectl delete plain pod"            'kubectl delete pod mypod'
Invoke-Case ALLOW "kubectl delete pods plural"          'kubectl delete pods mypod'
Invoke-Case ALLOW "branch -d lowercase, merged"         'git branch -d merged-feature'
Invoke-Case ALLOW "plain git status"                    'git status'

# --- overrides: the scoped bypass works, and the two absolute blocks refuse it ---
Invoke-Case ALLOW "danger-ok overrides force-push"      'TERSE_OPS_DANGER_OK=1 git push --force origin main'
Invoke-Case ALLOW "commit-ok overrides commit"          'TERSE_OPS_COMMIT_OK=1 git commit -m "wip"'
Invoke-Case ALLOW "danger-ok also overrides commit"     'TERSE_OPS_DANGER_OK=1 git commit -m "wip"'
Invoke-Case BLOCK "no override defeats --no-verify"     'TERSE_OPS_DANGER_OK=1 git commit -m "x" --no-verify'

Write-Host ""
Write-Host "$pass passed, $fail failed"
if ($fail -gt 0) { exit 1 } else { exit 0 }
