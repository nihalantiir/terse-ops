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

function Record-Result {
    param([string]$Expect, [string]$Desc, [string]$Cmd, [int]$Code, [string]$Out)
    $ok = if ($Expect -eq 'BLOCK') { $Code -eq 2 } else { $Code -eq 0 }
    if ($ok) {
        $script:pass++
    } else {
        $script:fail++
        Write-Host "FAIL [expected $Expect, got exit $Code]: $Desc"
        Write-Host "  cmd: $Cmd"
        if ($Expect -eq 'ALLOW') { Write-Host "  output: $Out" }
    }
}

# Runs from a fresh, throwaway directory with no .git anywhere above it, so
# these baseline cases can't pick up a real standing-allow file from
# whatever repo the suite happens to be run from (see Invoke-CaseInRepo
# below for cases that deliberately want a repo/allow-file present).
function Invoke-Case {
    param([string]$Expect, [string]$Desc, [string]$Cmd)
    $payload = (@{ tool_input = @{ command = $Cmd } } | ConvertTo-Json -Compress)
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Push-Location $tmp
    $out = $payload | & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Hook 2>&1
    $code = $LASTEXITCODE
    Pop-Location
    Remove-Item -Recurse -Force $tmp
    Record-Result $Expect $Desc $Cmd $code ($out -join "`n")
}

# Scaffolds a throwaway repo dir (a bare .git marker, no real `git init`
# needed -- the hook only checks .git's existence), optionally writes a
# standing-allow file, invokes the hook with cwd set inside it (optionally a
# nested subdir, to prove the walk-up-to-root logic), then cleans up.
function Invoke-CaseInRepo {
    param(
        [string]$Expect,
        [string]$Desc,
        [string]$Cmd,
        [string]$AllowContents = '',
        [string]$Subdir = '',
        [bool]$NoGit = $false
    )
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    if (-not $NoGit) { New-Item -ItemType Directory -Path (Join-Path $tmp '.git') | Out-Null }
    if ($AllowContents -ne '') {
        $claudeDir = Join-Path $tmp '.claude'
        New-Item -ItemType Directory -Path $claudeDir | Out-Null
        Set-Content -Path (Join-Path $claudeDir 'terse-ops-allow.local.txt') -Value $AllowContents
    }
    $invokeDir = $tmp
    if ($Subdir -ne '') {
        $invokeDir = Join-Path $tmp $Subdir
        New-Item -ItemType Directory -Path $invokeDir -Force | Out-Null
    }

    $payload = (@{ tool_input = @{ command = $Cmd } } | ConvertTo-Json -Compress)
    Push-Location $invokeDir
    $out = $payload | & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Hook 2>&1
    $code = $LASTEXITCODE
    Pop-Location
    Remove-Item -Recurse -Force $tmp

    Record-Result $Expect $Desc $Cmd $code ($out -join "`n")
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
Invoke-Case BLOCK "--no-gpg-sign"                        'git commit -m "x" --no-gpg-sign'

# --- AI-attribution commit trailer: absolute, no override, same class as --no-verify ---
Invoke-Case BLOCK "co-authored-by naming Claude"        'git commit -m "fix bug\n\nCo-Authored-By: Claude <noreply@anthropic.com>"'
Invoke-Case BLOCK "generated-by naming Claude"          'git commit -m "fix bug\n\nGenerated-By: Claude"'
Invoke-Case BLOCK "signed-off-by naming Anthropic"      'git commit -m "fix bug\n\nSigned-off-by: Anthropic Bot <bot@anthropic.com>"'
Invoke-Case BLOCK "bare noreply@anthropic.com address, no trailer-key match" 'git commit -m "fix bug\n\nCo-Author: X <noreply@anthropic.com>"'
Invoke-Case ALLOW "co-authored-by naming a human is fine" 'TERSE_OPS_COMMIT_OK=1 git commit -m "fix bug\n\nCo-Authored-By: Jane Doe <jane@example.com>"'
Invoke-Case ALLOW "signed-off-by human DCO sign-off is fine" 'TERSE_OPS_COMMIT_OK=1 git commit -m "fix bug\n\nSigned-off-by: Jane Doe <jane@example.com>"'
Invoke-Case BLOCK "no override defeats AI-attribution trailer" 'TERSE_OPS_DANGER_OK=1 git commit -m "fix\n\nCo-Authored-By: Claude <noreply@anthropic.com>"'

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

# --- one-shot overrides: the marker works, and the two absolute blocks refuse it ---
Invoke-Case ALLOW "danger-ok overrides force-push"      'TERSE_OPS_DANGER_OK=1 git push --force origin main'
Invoke-Case ALLOW "commit-ok overrides commit"          'TERSE_OPS_COMMIT_OK=1 git commit -m "wip"'
Invoke-Case ALLOW "danger-ok also overrides commit"     'TERSE_OPS_DANGER_OK=1 git commit -m "wip"'
Invoke-Case BLOCK "no override defeats --no-verify"     'TERSE_OPS_DANGER_OK=1 git commit -m "x" --no-verify'

# --- standing per-repo allow (/terse-ops:allow): durable, category-scoped, revocable ---
Invoke-CaseInRepo ALLOW "standing allow: commit granted" 'git commit -m "wip"' -AllowContents 'commit'
Invoke-CaseInRepo ALLOW "standing allow: force-push granted" 'git push --force origin main' -AllowContents 'force-push'
Invoke-CaseInRepo BLOCK "standing allow: category scoping (commit-only doesn't cover force-push)" 'git push --force origin main' -AllowContents 'commit'
Invoke-CaseInRepo BLOCK "standing allow: --no-verify still absolute" 'git commit -m "x" --no-verify' -AllowContents 'commit'
Invoke-CaseInRepo BLOCK "standing allow: empty/comment-only file grants nothing" 'git commit -m "wip"' -AllowContents '# nothing granted yet'
Invoke-CaseInRepo BLOCK "standing allow: file with no .git above it is inert" 'git commit -m "wip"' -AllowContents 'commit' -NoGit $true
Invoke-CaseInRepo ALLOW "standing allow: walk-up finds root from nested subdir" 'git commit -m "wip"' -AllowContents 'commit' -Subdir 'a\b\c'

# Revoke: grant, confirm allowed, then remove the file in the same repo dir
# and confirm the block comes back -- proves revoke actually restores
# default behavior, not just that an unrelated fresh repo blocks by default.
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tmp '.git') | Out-Null
$claudeDir = Join-Path $tmp '.claude'
New-Item -ItemType Directory -Path $claudeDir | Out-Null
$allowFile = Join-Path $claudeDir 'terse-ops-allow.local.txt'
Set-Content -Path $allowFile -Value 'commit'
$payload = (@{ tool_input = @{ command = 'git commit -m "wip"' } } | ConvertTo-Json -Compress)
Push-Location $tmp
$out = $payload | & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Hook 2>&1
Record-Result ALLOW "standing allow: granted before revoke" 'git commit -m "wip"' $LASTEXITCODE ($out -join "`n")
Pop-Location
Remove-Item -Force $allowFile
Push-Location $tmp
$out = $payload | & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Hook 2>&1
Record-Result BLOCK "standing allow: revoke restores the block" 'git commit -m "wip"' $LASTEXITCODE ($out -join "`n")
Pop-Location
Remove-Item -Recurse -Force $tmp

# --- flag-comments.ps1: PostToolUse nudge on Edit/Write, never blocks the
# tool itself (already ran by PostToolUse time) -- FLAG means exit 2
# (nudge surfaced), CLEAN means exit 0 (no nudge). ---
$Hook2 = Join-Path $PSScriptRoot "..\hooks\flag-comments.ps1"

function Invoke-CommentCase {
    param([string]$Expect, [string]$Desc, [string]$ToolName, [string]$FilePath, [string]$Text)
    $field = if ($ToolName -eq 'Edit') { 'new_string' } else { 'content' }
    $toolInput = @{ file_path = $FilePath }
    $toolInput[$field] = $Text
    $payload = (@{ tool_name = $ToolName; tool_input = $toolInput } | ConvertTo-Json -Compress)
    $out = $payload | & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Hook2 2>&1
    $code = $LASTEXITCODE
    $ok = if ($Expect -eq 'FLAG') { $code -eq 2 } else { $code -eq 0 }
    if ($ok) {
        $script:pass++
    } else {
        $script:fail++
        Write-Host "FAIL [expected $Expect, got exit $code]: $Desc"
        if ($Expect -eq 'CLEAN') { Write-Host "  output: $($out -join "``n")" }
    }
}

Invoke-CommentCase FLAG  "Write, narrative role comment"         Write "src/pool.py"        "# This class is responsible for managing the connection pool"
Invoke-CommentCase FLAG  "Edit, session-narration comment"       Edit  "src/foo.go"          "// this fixes the race from the earlier refactor"
Invoke-CommentCase FLAG  "Edit, wrapper-around phrasing"         Edit  "scripts/deploy.ps1"  "# thin wrapper around the deploy API"
Invoke-CommentCase FLAG  "Write, used-by-the-flow phrasing"      Write "src/util.ts"         "// used by the checkout flow"
Invoke-CommentCase FLAG  "Edit, helper-function-to phrasing"     Edit  "lib/helpers.rb"      "# helper function to format currency"
Invoke-CommentCase FLAG  "Write, class-manages narration"        Write "src/pool.py"         "# This class manages the connection pool"
Invoke-CommentCase CLEAN "Write, plain code, no narrative phrase" Write "src/add.go"         "func Add(a, b int) int { return a + b }"
Invoke-CommentCase CLEAN "Edit, genuine non-obvious why"         Edit  "src/retry.py"        "# retry once: upstream API is flaky under load per INC-4021"
Invoke-CommentCase CLEAN "Write, narrative phrase but non-source ext (md)" Write "README.md" "this class is responsible for things"

# Wrong tool (Read) must never be flagged even with narrative phrasing present.
$payload = (@{ tool_name = 'Read'; tool_input = @{ file_path = 'src/pool.py'; content = 'responsible for pooling' } } | ConvertTo-Json -Compress)
$out = $payload | & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Hook2 2>&1
Record-Result ALLOW "flag-comments: Read tool is never flagged" "Read src/pool.py" $LASTEXITCODE ($out -join "`n")

Write-Host ""
Write-Host "$pass passed, $fail failed"
if ($fail -gt 0) { exit 1 } else { exit 0 }
