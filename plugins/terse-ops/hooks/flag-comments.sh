#!/bin/sh
# PostToolUse nudge for Edit/Write calls. Backs the code-comments skill with
# a mechanical heuristic instead of relying on prose alone -- same "hook
# backs the skill" pattern as block-dangerous.sh, except this one never
# blocks: the write already happened by the time PostToolUse fires, so a
# non-zero exit here only feeds a warning back to the model, not a denial.
set -u

input="$(cat)"

# Pulls a plain (non-escaped-body) JSON string field's value -- used only
# for file_path and tool_name, which never contain embedded quotes or
# newlines. A parse miss returns empty (no nudge), not a fallback scan:
# unlike block-dangerous, missing a hit here just means one fewer nudge,
# not a bypassed safety block, so there's no need to fail toward flagging.
extract_plain_field() {
  field="$1"
  printf '%s' "$input" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed -E "s/^\"$field\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//"
}

file_path="$(extract_plain_field file_path)"
[ -z "$file_path" ] && exit 0

# Only recognized source-code extensions -- markdown, JSON, YAML, plain text
# etc. don't have "comments" in the sense this heuristic cares about and
# would just be noise.
case "$file_path" in
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.py|*.go|*.rs|*.c|*.h|*.cpp|*.cc|*.hpp|*.hh|*.java|*.kt|*.kts|*.cs|*.rb|*.php|*.swift|*.scala|*.sh|*.bash|*.ps1)
    : ;;
  *)
    exit 0 ;;
esac

tool_name="$(extract_plain_field tool_name)"

case "$tool_name" in
  Write|Edit) : ;;
  *) exit 0 ;;
esac

# Deliberately does not isolate just the new content field: the escaped-body
# JSON strings here (multi-line file content, `\n`-escaped) aren't reliably
# extractable with POSIX-sh/grep alone. Scanning the whole raw payload for
# narrative phrasing means an Edit's untouched `old_string` can also trigger
# a hit -- acceptable for a nudge that only ever warns, never blocks, and a
# pre-existing narrative comment is still worth a reread.
lc="$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')"

# Heuristic only -- narrative phrases that show up in restated-what or
# session-narration comments, not in ordinary code identifiers or strings.
# A hit is a prompt to reread the comment against code-comments, not proof
# the comment is bad -- false positives are cheap here since this hook can
# only warn, never block (see header).
flagged=""
for phrase in "responsible for" "wrapper around" "owns the" "used by the" \
  "added this to fix" "added to fix" "this fixes" "this handles" \
  "this adds support" "handles the case" "helper function to" "helper to" \
  "manages the" "this class manages" "this module manages"; do
  case "$lc" in
    *"$phrase"*) flagged="$flagged$phrase; " ;;
  esac
done

[ -z "$flagged" ] && exit 0

printf '%s\n' "terse-ops code-comments nudge: $file_path has a comment matching narrative phrasing ($flagged). Reread it against code-comments -- if it restates what the code does, narrates a role, or references this task/session rather than a non-obvious why, delete it. Heuristic hint, not a verdict -- ignore it if the comment is genuinely warranted." >&2
exit 2
