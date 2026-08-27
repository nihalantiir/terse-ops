# PreToolUse guard for Bash calls on Windows machines without Git Bash/WSL.
# Mirrors block-dangerous.sh rule-for-rule -- keep the two in sync by hand,
# there's no shared source since Claude Code has no OS-conditional hook entry.
# powershell.exe ships with every Windows install, so this is the fallback
# that still runs when bash isn't on PATH (block-dangerous.sh fails to even
# launch in that case, which is a silent no-op, not a block).

function Deny($msg) {
    [Console]::Error.WriteLine($msg)
    exit 2
}

# Nearest ancestor directory containing a .git entry, starting from this
# process's own working directory. No `git` subprocess here -- this runs on
# every Bash call, and an existence check is enough to answer "is there a
# repo root to look for a standing allow in." Returns $null if none found.
function Find-RepoRoot {
    $dir = (Get-Location).Path
    while ($true) {
        if (Test-Path (Join-Path $dir '.git')) { return $dir }
        $parent = Split-Path $dir -Parent
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $dir) { return $null }
        $dir = $parent
    }
}

# Standing, per-repo allow for one category of the block list below. Set up
# only via `/terse-ops:allow <category>`, never inferred by the model -- same
# non-inference rule as the one-shot marker, just durable instead of
# one-command-scoped (see harness). File is one category slug per line,
# blank lines and #-comments ignored. Never consulted for the
# --no-verify/--no-gpg-sign check further down -- that stays a bare Deny(),
# on purpose, see the comment on that check.
function Test-CategoryAllowed($category) {
    $root = Find-RepoRoot
    if (-not $root) { return $false }
    $allowFile = Join-Path $root '.claude\terse-ops-allow.local.txt'
    if (-not (Test-Path $allowFile)) { return $false }
    foreach ($line in Get-Content $allowFile) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
        if ($trimmed -eq $category) { return $true }
    }
    return $false
}

# Explicit, scoped bypass for the destructive/hard-to-reverse checks below --
# not for --no-verify/--no-gpg-sign, which stays absolute (bypassing
# signing/hooks is a different category from "delete this on purpose", see
# harness). Two ways through: the one-shot marker (signals the user
# explicitly asked, this turn, for exactly this action -- scoped to the one
# command it's prefixed on, not a standing setting) or a standing per-repo
# allow for this category (see Test-CategoryAllowed above). Checked in that
# order so the common, marker-only path pays no extra file I/O.
function Deny-Overridable($msg, $seg, $category) {
    if ($seg -like '*TERSE_OPS_DANGER_OK=1*') { return }
    if (Test-CategoryAllowed $category) { return }
    Deny "$msg Or run ``/terse-ops:allow $category`` so this repo stops asking every time (see harness)."
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
    # AI-attribution commit trailer (Co-Authored-By/Generated-By/Signed-off-by
    # naming Claude or Anthropic, or the literal noreply@anthropic.com
    # address) has NO override, ever -- same class as --no-verify below.
    # Unconditional, not gated on "git commit" appearing in this same
    # segment: a multi-line message built via `$(cat <<'EOF' ... EOF)` puts
    # each body line in its own segment (real newlines split the same as
    # `;`/`&`/`|` here), so the trailer line is often not in the same
    # segment as the invocation itself. -like is case-insensitive already.
    if (($seg -like '*co-authored-by*claude*') -or ($seg -like '*co-authored-by*anthropic*') -or `
        ($seg -like '*generated-by*claude*') -or ($seg -like '*generated-by*anthropic*') -or `
        ($seg -like '*signed-off-by*claude*') -or ($seg -like '*signed-off-by*anthropic*') -or `
        ($seg -like '*noreply@anthropic.com*')) {
        Deny "terse-ops harness: an AI-attribution commit trailer (Co-Authored-By/Generated-By/Signed-off-by naming Claude or Anthropic, or noreply@anthropic.com) is blocked. Never attribute a commit to Claude/Anthropic, in any repo. This has no override, ever."
    }

    # Default is never commit on the user's behalf. Two ways through: the
    # one-shot marker (the user just explicitly asked, this turn, for the
    # commit itself) or a standing per-repo allow for "commit" (see
    # Test-CategoryAllowed above, set up only via /terse-ops:allow commit).
    $isCommit = ($seg -like '*git *commit*') -or ($seg -like '*git *cherry-pick*--continue*')
    if ($isCommit -and ($seg -notlike '*TERSE_OPS_COMMIT_OK=1*') -and ($seg -notlike '*TERSE_OPS_DANGER_OK=1*') -and -not (Test-CategoryAllowed 'commit')) {
        Deny "terse-ops harness: git commit is blocked. Default rule is never commit on the user's behalf -- stage the change and ask them to commit it. If they just explicitly asked you to commit it yourself this turn, prefix the command with TERSE_OPS_COMMIT_OK=1 (see harness) -- don't reuse that prefix on a later commit without asking again. Or run ``/terse-ops:allow commit`` so this repo stops asking every time."
    }

    if (($seg -like '*git *push*--force*') -or ($seg -like '*git *push* -f *') -or ($seg -like '*git *push* -f')) {
        Deny-Overridable "terse-ops harness: force-push is blocked. Confirm with the user and have them run it, or get explicit sign-off first -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg 'force-push'
    }

    # --no-verify/--no-gpg-sign has NO override, ever -- not the one-shot
    # marker, not a standing allow, no exceptions. Bypassing signing or hooks
    # corrupts an audit trail, a different failure mode than "the user wants
    # this data gone on purpose." DO NOT wire a Test-CategoryAllowed check
    # into this branch, on a future hand-sync edit or otherwise -- see harness.
    if (($seg -like '*--no-verify*') -or ($seg -like '*--no-gpg-sign*')) {
        Deny "terse-ops harness: --no-verify/--no-gpg-sign is blocked. Do not bypass hooks or signing to force a command through. This one has no override -- it's a different category from a destructive-on-purpose action."
    }

    if ($seg -like '*reset *--hard*') {
        Deny-Overridable "terse-ops harness: git reset --hard is blocked. It discards uncommitted work -- stash first or confirm with the user -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg 'reset-hard'
    }

    if ($seg -like '*git *push*--delete*') {
        Deny-Overridable "terse-ops harness: git push --delete is blocked. Deleting a remote branch/tag is hard to reverse -- confirm with the user and have them run it -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg 'push-delete'
    }

    if ($seg -like '*terraform*destroy*') {
        Deny-Overridable "terse-ops harness: terraform destroy is blocked. It tears down provisioned infrastructure -- confirm with the user and have them run it -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg 'terraform-destroy'
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
                    Deny-Overridable "terse-ops harness: kubectl delete pod --all-namespaces is blocked. That's cluster-wide, not a routine single-pod restart -- confirm with the user first -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg 'kubectl-delete'
                }
            } else {
                $shown = if ($resource) { $resource } else { 'unspecified' }
                Deny-Overridable "terse-ops harness: kubectl delete is blocked (resource: $shown). Deleting anything other than a pod isn't self-healing under a controller and can be destructive or hard to reverse -- confirm with the user, or scope to a read-only check first -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg 'kubectl-delete'
            }
        }
    }

    # -like is case-insensitive by default in PowerShell, unlike bash's case.
    if ($seg -like '*drop table*') {
        Deny-Overridable "terse-ops harness: a raw DROP TABLE is blocked. Dropping a table is destructive and usually irreversible -- confirm with the user before running it -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg 'drop-table'
    }

    # branch -D: flags can combine (-Df, -fD), so check tokens. Restricted to
    # single-dash clusters (-notlike '--*'): a long flag like
    # --set-upstream-to=origin/DEV would otherwise false-positive on the
    # literal "D" in a branch name it carries as free text.
    if ($seg -like '*branch*') {
        foreach ($tok in ($seg -split '\s+')) {
            if ($tok -like '-*' -and $tok -notlike '--*' -and $tok -cmatch 'D') {
                Deny-Overridable "terse-ops harness: git branch -D is blocked. It force-deletes an unmerged branch -- confirm with the user or use -d on a merged branch -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg 'branch-delete'
            }
        }
    }

    # clean -f/-x: flags combine (-fd, -fdx), so check tokens. Restricted to
    # single-dash clusters, same reason as branch -- --exclude=foo.log would
    # otherwise false-positive on the "f" in its own pattern argument.
    if ($seg -like '*clean*') {
        foreach ($tok in ($seg -split '\s+')) {
            if ($tok -eq '--force' -or ($tok -like '-*' -and $tok -notlike '--*' -and $tok -match 'f')) {
                Deny-Overridable "terse-ops harness: git clean -f is blocked. It permanently deletes untracked files -- confirm with the user first -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg 'clean-force'
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
            Deny-Overridable "terse-ops harness: rm -rf is blocked. Delete narrowly and explicitly, or ask the user before a recursive force-delete -- or, if just explicitly asked this turn, prefix with TERSE_OPS_DANGER_OK=1 (see harness)." $seg 'rm-rf'
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
