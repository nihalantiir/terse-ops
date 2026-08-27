# PostToolUse nudge for Edit/Write calls on Windows machines without Git
# Bash/WSL. Mirrors flag-comments.sh rule-for-rule -- keep the two in sync by
# hand, same as block-dangerous.sh/.ps1. Never blocks: the write already
# happened by the time PostToolUse fires, so a non-zero exit here only feeds
# a warning back to the model, not a denial.

$raw = [Console]::In.ReadToEnd()

$filePath = $null
$toolName = $null
try {
    $payload = $raw | ConvertFrom-Json -ErrorAction Stop
    if ($payload.tool_input -and $payload.tool_input.file_path) {
        $filePath = [string]$payload.tool_input.file_path
    }
    if ($payload.tool_name) {
        $toolName = [string]$payload.tool_name
    }
} catch {
    # Parse miss: no nudge, not a fallback scan -- unlike block-dangerous,
    # missing a hit here just means one fewer nudge, not a bypassed block.
    exit 0
}

if (-not $filePath) { exit 0 }

# Only recognized source-code extensions -- markdown, JSON, YAML, plain text
# etc. don't have "comments" in the sense this heuristic cares about and
# would just be noise.
$sourceExtensions = @('.js', '.jsx', '.ts', '.tsx', '.mjs', '.cjs', '.py', '.go', '.rs', '.c', '.h', '.cpp', '.cc', '.hpp', '.hh', '.java', '.kt', '.kts', '.cs', '.rb', '.php', '.swift', '.scala', '.sh', '.bash', '.ps1')
$ext = [System.IO.Path]::GetExtension($filePath)
if ($sourceExtensions -notcontains $ext) { exit 0 }

if ($toolName -ne 'Write' -and $toolName -ne 'Edit') { exit 0 }

# Deliberately scans the whole raw payload rather than isolating just the
# new content field -- an Edit's untouched old_string can also trigger a
# hit, which is fine for a nudge that only ever warns, never blocks; a
# pre-existing narrative comment is still worth a reread.
$lc = $raw.ToLowerInvariant()

$phrases = @('responsible for', 'wrapper around', 'owns the', 'used by the', `
    'added this to fix', 'added to fix', 'this fixes', 'this handles', `
    'this adds support', 'handles the case', 'helper function to', 'helper to')

$flagged = @()
foreach ($phrase in $phrases) {
    if ($lc.Contains($phrase)) { $flagged += $phrase }
}

if ($flagged.Count -eq 0) { exit 0 }

[Console]::Error.WriteLine("terse-ops code-comments nudge: $filePath has a comment matching narrative phrasing ($($flagged -join '; ')). Reread it against code-comments -- if it restates what the code does, narrates a role, or references this task/session rather than a non-obvious why, delete it. Heuristic hint, not a verdict -- ignore it if the comment is genuinely warranted.")
exit 2
