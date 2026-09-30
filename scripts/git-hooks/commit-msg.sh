#!/usr/bin/env bash
# Git commit-msg hook: enforce Conventional Commits, with the types listed in CLAUDE.md ("PRs").
# Installed into .git/hooks by `./gradlew installGitHooks` (a dependency of `clean`).
# See CLAUDE.md ("Git hooks self-install via Gradle").
#
# Git's own merge and revert messages ("Merge ...", "Revert \"...\"") and autosquash markers
# (fixup!/squash!/amend!, rewritten by `git rebase --autosquash`) pass through unchanged.
set -euo pipefail

types='feat|fix|chore|docs|test|refactor'

# The subject is the first line that isn't blank or a comment (git strips `#` lines afterwards).
subject="$(grep -vE '^[[:space:]]*(#|$)' "$1" | head -n 1 || true)"

if printf '%s\n' "$subject" | grep -qE '^(Merge |Revert "|(fixup|squash|amend)! )'; then
    exit 0
fi

if printf '%s\n' "$subject" | grep -qE "^($types)(\([^()[:space:]]+\))?!?: [^[:space:]].*"; then
    exit 0
fi

{
    echo "Commit message doesn't follow Conventional Commits:"
    echo "  $subject"
    echo
    echo "Use: <type>(<scope>): <description>   e.g. feat(core): add parser"
    echo "Types: ${types//|/, }. The (<scope>) is optional; add ! before the colon for a breaking change."
} >&2
exit 1
