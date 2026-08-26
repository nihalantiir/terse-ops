# PreToolUse guard for Bash calls on Windows machines without Git Bash/WSL.
# Mirrors block-dangerous.sh rule-for-rule — keep the two in sync by hand,
# there's no shared source since Claude Code has no OS-conditional hook entry.
# powershell.exe ships with every Windows install, so this is the fallback
# that still runs when bash isn't on PATH (block-dangerous.sh fails to even
# launch in that case, which is a silent no-op, not a block).

function Deny($msg) {
    [Console]::Error.WriteLine($msg)
    exit 2
}

$raw = [Console]::In.ReadToEnd()
$cmd = $raw
try {
    $payload = $raw | ConvertFrom-Json -ErrorAction Stop
    if ($payload.tool_input -and $payload.tool_input.command) {
        $cmd = [string]$payload.tool_input.command
    }
} catch {
    # Parsing miss falls back to scanning the whole raw payload, same as the
    # sh version — fail toward blocking, not toward silently letting it through.
}

# Default is never commit on the user's behalf. Exception: the user just
# explicitly asked, this turn, for the commit itself — signaled by prefixing
# the single command with TERSE_OPS_COMMIT_OK=1 (see harness).
$isCommit = ($cmd -like '*git *commit*') -or ($cmd -like '*git *cherry-pick*--continue*')
if ($isCommit -and ($cmd -notlike '*TERSE_OPS_COMMIT_OK=1*')) {
    Deny "terse-ops harness: git commit is blocked. Default rule is never commit on the user's behalf -- stage the change and ask them to commit it. If they just explicitly asked you to commit it yourself this turn, prefix the command with TERSE_OPS_COMMIT_OK=1 (see harness) -- don't reuse that prefix on a later commit without asking again."
}

if (($cmd -like '*git *push*--force*') -or ($cmd -like '*git *push* -f *') -or ($cmd -like '*git *push* -f')) {
    Deny "terse-ops harness: force-push is blocked. Confirm with the user and have them run it, or get explicit sign-off first."
}

if (($cmd -like '*--no-verify*') -or ($cmd -like '*--no-gpg-sign*')) {
    Deny "terse-ops harness: --no-verify/--no-gpg-sign is blocked. Do not bypass hooks or signing to force a command through."
}

if ($cmd -like '*reset *--hard*') {
    Deny "terse-ops harness: git reset --hard is blocked. It discards uncommitted work -- stash first or confirm with the user."
}

if ($cmd -like '*git *push*--delete*') {
    Deny "terse-ops harness: git push --delete is blocked. Deleting a remote branch/tag is hard to reverse -- confirm with the user and have them run it."
}

if ($cmd -like '*terraform*destroy*') {
    Deny "terse-ops harness: terraform destroy is blocked. It tears down provisioned infrastructure -- confirm with the user and have them run it."
}

if ($cmd -like '*kubectl*delete*') {
    Deny "terse-ops harness: kubectl delete is blocked. Deleting cluster resources can be destructive and hard to reverse -- confirm with the user and have them run it, or scope to a read-only check first."
}

# -like is case-insensitive by default in PowerShell, unlike bash's case.
if ($cmd -like '*drop table*') {
    Deny "terse-ops harness: a raw DROP TABLE is blocked. Dropping a table is destructive and usually irreversible -- confirm with the user before running it."
}

# branch -D: flags can combine (-Df, -fD), so check tokens in the segment
# from "branch" onward, same approach as the sh version.
if ($cmd -match '(?:^|[;&|\s])branch(\s[^;&|]*|$)') {
    foreach ($tok in ($Matches[0] -split '\s+')) {
        if ($tok -like '-*' -and $tok -cmatch 'D') {
            Deny "terse-ops harness: git branch -D is blocked. It force-deletes an unmerged branch -- confirm with the user or use -d on a merged branch."
        }
    }
}

# clean -f/-x: flags combine (-fd, -fdx), so check tokens.
if ($cmd -match '(?:^|[;&|\s])clean(\s[^;&|]*|$)') {
    foreach ($tok in ($Matches[0] -split '\s+')) {
        if ($tok -eq '--force' -or ($tok -like '-*' -and $tok -match 'f')) {
            Deny "terse-ops harness: git clean -f is blocked. It permanently deletes untracked files -- confirm with the user first."
        }
    }
}

# rm -rf: recursive + force can arrive combined, reversed, long-form, or as
# separate short flags in either order -- check tokens, not a fixed string.
if ($cmd -match '(?:^|[;&|\s])rm(\s[^;&|]*|$)') {
    $hasR = $false
    $hasF = $false
    foreach ($tok in ($Matches[0] -split '\s+')) {
        if ($tok -eq 'rm') { continue }
        elseif ($tok -eq '--recursive') { $hasR = $true }
        elseif ($tok -eq '--force') { $hasF = $true }
        elseif ($tok -like '-*') {
            if ($tok -match 'r') { $hasR = $true }
            if ($tok -match 'f') { $hasF = $true }
        }
    }
    if ($hasR -and $hasF) {
        Deny "terse-ops harness: rm -rf is blocked. Delete narrowly and explicitly, or ask the user before a recursive force-delete."
    }
}

exit 0
