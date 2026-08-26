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

# Explicit, scoped bypass for the destructive/hard-to-reverse checks below --
# not for --no-verify/--no-gpg-sign, which stays absolute (bypassing
# signing/hooks is a different category from "delete this on purpose", see
# harness). Signals the user explicitly asked, this turn, for exactly this
# action. Scoped to the one command it's prefixed on, not a standing setting.
function Deny-Overridable($msg, $seg) {
    if ($seg -notlike '*TERSE_OPS_DANGER_OK=1*') {
        Deny $msg
    }
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

function Check-Segment($seg) {
    # Default is never commit on the user's behalf. Exception: the user just
    # explicitly asked, this turn, for the commit itself — signaled by
    # prefixing the single command with TERSE_OPS_COMMIT_OK=1 (see harness).
    $isCommit = ($seg -like '*git *commit*') -or ($seg -like '*git *cherry-pick*--continue*')
    if ($isCommit -and ($seg -notlike '*TERSE_OPS_COMMIT_OK=1*') -and ($seg -notlike '*TERSE_OPS_DANGER_OK=1*')) {
        Deny "terse-ops harness: git commit is blocked. Default rule is never commit on the user's behalf -- stage the change and ask them to commit it. If they just explicitly asked you to commit it yourself this turn, prefix the command with TERSE_OPS_COMMIT_OK=1 (see harness) -- don't reuse that prefix on a later commit without asking again."
    }

    if (($seg -like '*git *push*--force*') -or ($seg -like '*git *push* -f *') -or ($seg -like '*git *push* -f')) {
        Deny-Overridable "terse-ops harness: force-push is blocked. Confirm with the user and have them run it, or get explicit sign-off first -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg
    }

    if (($seg -like '*--no-verify*') -or ($seg -like '*--no-gpg-sign*')) {
        Deny "terse-ops harness: --no-verify/--no-gpg-sign is blocked. Do not bypass hooks or signing to force a command through. This one has no override -- it's a different category from a destructive-on-purpose action."
    }

    if ($seg -like '*reset *--hard*') {
        Deny-Overridable "terse-ops harness: git reset --hard is blocked. It discards uncommitted work -- stash first or confirm with the user -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg
    }

    if ($seg -like '*git *push*--delete*') {
        Deny-Overridable "terse-ops harness: git push --delete is blocked. Deleting a remote branch/tag is hard to reverse -- confirm with the user and have them run it -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg
    }

    if ($seg -like '*terraform*destroy*') {
        Deny-Overridable "terse-ops harness: terraform destroy is blocked. It tears down provisioned infrastructure -- confirm with the user and have them run it -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg
    }

    # kubectl delete pod/pods is routine -- a controller reschedules it, so
    # it's closer to a restart than a deletion. Anything else stays blocked.
    # --all-namespaces stays blocked even for pods -- that's cluster-wide.
    if ($seg -match '(?:^|[;&|\s])kubectl(\s[^;&|]*|$)') {
        $sawDelete = $false
        $resource = $null
        $clusterWide = $false
        foreach ($tok in ($Matches[0] -split '\s+')) {
            if (-not $sawDelete) {
                if ($tok -eq 'delete') { $sawDelete = $true }
                continue
            }
            if ($tok -eq '--all-namespaces' -or $tok -eq '-A') { $clusterWide = $true }
            elseif ($tok -like '-*') { }
            elseif (-not $resource) { $resource = ($tok -split '/')[0] }
        }
        if ($sawDelete) {
            if ($resource -in @('pod', 'pods', 'po')) {
                if ($clusterWide) {
                    Deny-Overridable "terse-ops harness: kubectl delete pod --all-namespaces is blocked. That's cluster-wide, not a routine single-pod restart -- confirm with the user first -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg
                }
            } else {
                $shown = if ($resource) { $resource } else { 'unspecified' }
                Deny-Overridable "terse-ops harness: kubectl delete is blocked (resource: $shown). Deleting anything other than a pod isn't self-healing under a controller and can be destructive or hard to reverse -- confirm with the user, or scope to a read-only check first -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg
            }
        }
    }

    # -like is case-insensitive by default in PowerShell, unlike bash's case.
    if ($seg -like '*drop table*') {
        Deny-Overridable "terse-ops harness: a raw DROP TABLE is blocked. Dropping a table is destructive and usually irreversible -- confirm with the user before running it -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg
    }

    # branch -D: flags can combine (-Df, -fD), so check tokens. Restricted to
    # single-dash clusters (-notlike '--*'): a long flag like
    # --set-upstream-to=origin/DEV would otherwise false-positive on the
    # literal "D" in a branch name it carries as free text.
    if ($seg -like '*branch*') {
        foreach ($tok in ($seg -split '\s+')) {
            if ($tok -like '-*' -and $tok -notlike '--*' -and $tok -cmatch 'D') {
                Deny-Overridable "terse-ops harness: git branch -D is blocked. It force-deletes an unmerged branch -- confirm with the user or use -d on a merged branch -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg
            }
        }
    }

    # clean -f/-x: flags combine (-fd, -fdx), so check tokens. Restricted to
    # single-dash clusters, same reason as branch -- --exclude=foo.log would
    # otherwise false-positive on the "f" in its own pattern argument.
    if ($seg -like '*clean*') {
        foreach ($tok in ($seg -split '\s+')) {
            if ($tok -eq '--force' -or ($tok -like '-*' -and $tok -notlike '--*' -and $tok -match 'f')) {
                Deny-Overridable "terse-ops harness: git clean -f is blocked. It permanently deletes untracked files -- confirm with the user first -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg
            }
        }
    }

    # rm -rf: recursive + force can arrive combined, reversed, long-form, or
    # as separate short flags in either order. Long flags are matched by
    # exact name only, not substring: --preserve-root contains "r" and
    # --one-file-system contains "f", and together they'd otherwise
    # false-positive as "recursive + force" despite being neither.
    if ($seg -like '*rm *') {
        $hasR = $false
        $hasF = $false
        foreach ($tok in ($seg -split '\s+')) {
            if ($tok -eq 'rm') { continue }
            elseif ($tok -eq '--recursive') { $hasR = $true }
            elseif ($tok -eq '--force') { $hasF = $true }
            elseif ($tok -like '-*' -and $tok -notlike '--*') {
                if ($tok -match 'r') { $hasR = $true }
                if ($tok -match 'f') { $hasF = $true }
            }
        }
        if ($hasR -and $hasF) {
            Deny-Overridable "terse-ops harness: rm -rf is blocked. Delete narrowly and explicitly, or ask the user before a recursive force-delete -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg
        }
    }
}

# Every check runs per-segment, not against the whole raw command line.
# Without this, a compound command's own control operators (&&, ;, |) don't
# bound the pattern matches: `git log && echo "committed"` would
# false-positive the commit block on the word inside an unrelated echo,
# since "git" and "commit" both appear *somewhere* on the line, just not in
# the same clause. This doesn't understand quoting (a literal ";" inside a
# quoted string still splits), which is a known, accepted gap -- the
# previous behavior was strictly worse (no scoping at all), not this plus
# something else.
foreach ($segment in ($cmd -split '[;&|]')) {
    Check-Segment $segment
}

exit 0
