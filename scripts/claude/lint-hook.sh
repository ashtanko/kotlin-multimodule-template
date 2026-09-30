#!/usr/bin/env bash
# Claude Code Stop hook: auto-format and lint the Kotlin the agent changed this turn.
# Registered in .claude/settings.json. See CLAUDE.md ("A Claude Code agent hook lints AI edits").
#
# Every task below fans out to all modules (each applies the `template.kotlin-library` convention
# plugin), so the whole build is held to the same diktat/detekt/spotless rules.
set -euo pipefail

# Consecutive blocked stops allowed before letting the agent stop anyway (loop guard).
MAX_ATTEMPTS=3

input="$(cat)"

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# Fast path: do nothing unless Kotlin sources, Gradle scripts or lint config changed in the working
# tree, so other turns stay instant (no Gradle spin-up). --untracked-files=all lists new files
# individually; without it a new package directory shows up as `dir/` and would be missed.
if ! git status --porcelain --untracked-files=all 2>/dev/null |
  grep -qE '\.kts?$|diktat-analysis\.yml$|config/detekt/|spotless/|\.editorconfig$'; then
  exit 0
fi

# Attempt counter, keyed by session. stop_hook_active=false means this stop was not caused by a
# previous block from this hook, so the counter starts over.
session_id="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
counter_file="${TMPDIR:-/tmp}/claude-lint-hook-${session_id:-default}"
if ! printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  rm -f "$counter_file"
fi

# 1) Auto-fix formatting, trailing whitespace and license headers (never blocks).
./gradlew --quiet spotlessApply >/dev/null 2>&1 || true

# 2) Enforce the static-analysis suite. --continue reports every failing module/tool in one pass
#    instead of stopping at the first one.
if out="$(./gradlew --quiet --continue detekt diktatCheck spotlessCheck 2>&1)"; then
  rm -f "$counter_file"
  exit 0
fi

attempts=$(($(cat "$counter_file" 2>/dev/null || echo 0) + 1))
echo "$attempts" >"$counter_file"

if ((attempts > MAX_ATTEMPTS)); then
  rm -f "$counter_file"
  printf '{"systemMessage": "Static analysis still failing after %d fix attempts; run /lint to see the remaining issues."}\n' "$MAX_ATTEMPTS"
  exit 0
fi

{
  echo "Static analysis (diktat/detekt/spotless) found issues — fix them (attempt $attempts/$MAX_ATTEMPTS):"
  printf '%s\n' "$out" |
    grep -vE '^\* (Try|What went wrong|Get more help)|^> (Run with|Get more help)|^BUILD FAILED|^[[:space:]]*$' |
    head -n 150 || true # under pipefail, grep hitting head's closed pipe must not abort before exit 2
} >&2
exit 2 # exit 2 feeds stderr back to the agent so it fixes the issues and retries.
