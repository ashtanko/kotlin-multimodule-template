#!/usr/bin/env bash
# Claude Code PreToolUse hook (Edit/MultiEdit/Write): refuse edits to generated files and edits that
# weaken a quality gate. Registered in .claude/settings.json. See CLAUDE.md ("A Claude Code agent
# hook guards the gates").
#
# It runs before every edit, so it is plain shell + jq with no Gradle, and the checks are simple
# pattern matches on the file before vs. after the edit, not a parser. It fails open: if it can't
# read its input (jq missing, malformed JSON, any internal error) it allows the edit and says so. A
# broken guard must never block every edit, which is also why it never exits 2.
set -euo pipefail

notice() {
  printf '{"systemMessage": "gate-guard: %s The edit was allowed without checking generated files or quality gates."}\n' "$1"
}
allow_with_notice() {
  notice "$1"
  exit 0
}
# Fail open on anything unexpected (set -e exits included): allow with a notice, never block.
trap 'status=$?; if ((status != 0)); then notice "internal error (exit $status)."; exit 0; fi' EXIT

deny() {
  jq -n --arg reason "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

command -v jq >/dev/null 2>&1 || allow_with_notice "jq is not installed."

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)" ||
  allow_with_notice "could not parse the hook input."
[ -n "$file_path" ] || exit 0

project_dir="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$input" | jq -r '.cwd // empty')}"
case "$file_path" in
  "$project_dir"/*) rel="${file_path#"$project_dir"/}" ;;
  /*) exit 0 ;; # outside the project
  *) rel="$file_path" ;;
esac

# 1) Generated files: say where the real source is.
case "$rel" in
  README.md)
    deny "README.md is generated. Edit config/main.md (the prose) and run \`make md\`, which rebuilds README.md from config/main.md + the detekt report + config/license.md." ;;
  build/* | */build/*)
    deny "$rel is Gradle build output and is regenerated on the next build. Edit the source it comes from (src/, a build script or config) and rebuild." ;;
  config/detekt/detekt-baseline.xml)
    deny "config/detekt/detekt-baseline.xml is generated (./gradlew detektBaseline) and must not grow to hide findings. Fix the code, or add a narrow @Suppress(\"RuleName\") with a reason at the finding." ;;
esac

# 2) Gate configuration: only these files are compared before vs. after.
case "$rel" in
  diktat-analysis.yml | config/detekt/*.yml | *.kts) ;;
  *) exit 0 ;;
esac

# The file as it would be after the edit: Write's content, or each old_string -> new_string
# replacement applied to the current file (Edit; MultiEdit's `edits` list).
before_file="$file_path"
[ -f "$before_file" ] || before_file=/dev/null
before="$(cat "$before_file")"
after="$(printf '%s' "$input" | jq -r --rawfile before "$before_file" '
  if .tool_input.content != null then .tool_input.content
  else reduce (.tool_input.edits // [.tool_input] | .[]) as $e ($before;
    if ($e.old_string // "") == "" then ($e.new_string // "") + . else split($e.old_string) | join($e.new_string // "") end)
  end')" || allow_with_notice "could not apply the edit to $rel."

count() { grep -ciE "$1" <<<"$2" || true; }

more_than_before() { (($(count "$1" "$after") > $(count "$1" "$before"))); }

case "$rel" in
  diktat-analysis.yml)
    if more_than_before 'enabled:[[:space:]]*false'; then
      deny "Every diktat rule stays enabled (CLAUDE.md), so this edit can't add \`enabled: false\`. Fix the code instead, or put a narrow @Suppress(\"RULE_ID\") with a reason on the offending declaration."
    fi ;;
  config/detekt/*.yml)
    if more_than_before 'active:[[:space:]]*false'; then
      deny "Every detekt rule stays active (CLAUDE.md), so this edit can't add \`active: false\`. Fix the code instead, or put a narrow @Suppress(\"RuleName\") with a reason on the offending declaration."
    fi ;;
  *.kts)
    if more_than_before 'ignoreFailures[^a-z0-9]*true'; then
      deny "This edit makes a check non-failing (ignoreFailures). Quality gates must fail the build: fix the reported issues instead, or add a narrow @Suppress(\"RULE_ID\") with a reason."
    fi
    # Coverage/mutation floors: "<keyword> <number>" pairs, e.g. minBound(80), minimum = "0.5".
    floors() {
      grep -oE '(minBound|minValue|minimum|mutationThreshold|coverageThreshold)[^0-9]*[0-9]+(\.[0-9]+)?' <<<"$1" |
        sed -E 's/^([A-Za-z]+)[^0-9]*/\1 /' || true
    }
    weakened="$(
      { floors "$before" | sed 's/^/old /'; floors "$after" | sed 's/^/new /'; } | awk '
        $1 == "old" { oc[$2]++; if (!($2 in om) || $3 + 0 < om[$2]) om[$2] = $3 + 0 }
        $1 == "new" { nc[$2]++; if (!($2 in nm) || $3 + 0 < nm[$2]) nm[$2] = $3 + 0 }
        END { for (k in oc) if (nc[k] < oc[k] || nm[k] < om[k]) { print k; exit } }'
    )"
    if [ -n "$weakened" ]; then
      deny "This edit lowers or removes a \`$weakened\` threshold in $rel. Coverage and mutation thresholds are floors: raise them or keep them. Close the gap with tests that assert behavior (the kotlin-coverage and kotlin-mutation-testing skills)."
    fi ;;
esac

exit 0
