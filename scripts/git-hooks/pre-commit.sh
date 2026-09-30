#!/usr/bin/env bash
# Git pre-commit hook: auto-format the staged files, then run the static-analysis suite.
# Installed into .git/hooks by `./gradlew installGitHooks` (a dependency of `clean`).
# See CLAUDE.md ("Git hooks self-install via Gradle").
#
# Only what was staged before the hook ran is re-staged after `spotlessApply`, so partial commits
# stay partial. A file with both staged and unstaged changes is never re-staged (that would sweep
# its unstaged hunks into the commit): if spotless needs to reformat one, the hook restores it and
# refuses the commit instead. Written for bash 3.2 (macOS's /bin/bash): no mapfile, and empty arrays
# are expanded with ${a[@]+"${a[@]}"} so `set -u` doesn't trip on them.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# 1) Record what is staged (added/copied/modified/renamed; deletions have nothing to format).
staged=()
while IFS= read -r -d '' file; do
    staged+=("$file")
done < <(git diff --cached --name-only --diff-filter=ACMR -z)

# Fast path: nothing that spotless/detekt/diktat look at, so don't start Gradle.
relevant='\.(kts?|ya?ml|toml|properties|sh)$|(^|/)\.(gitignore|editorconfig)$|^config/detekt/|^spotless/'
if ! printf '%s\n' ${staged[@]+"${staged[@]}"} | grep -qE "$relevant"; then
    exit 0
fi

# 2) Split into fully staged files (index == working tree) and partly staged ones.
unstaged="$(git diff --name-only -z | tr '\0' '\n')"
full=()
partial=()
for file in ${staged[@]+"${staged[@]}"}; do
    if printf '%s\n' "$unstaged" | grep -qxF -- "$file"; then
        partial+=("$file")
    else
        full+=("$file")
    fi
done

# Snapshot partly staged files so spotlessApply can't leave them modified.
snapshot="$(mktemp -d)"
trap 'rm -rf "$snapshot"' EXIT
i=0
for file in ${partial[@]+"${partial[@]}"}; do
    cp -p -- "$file" "$snapshot/$i"
    i=$((i + 1))
done

echo "Running static analysis..."

# 3) Auto-fix formatting, trailing whitespace and license headers.
./gradlew spotlessApply --daemon

# 4) Re-stage only the files that were fully staged: their only new changes are spotless's.
for file in ${full[@]+"${full[@]}"}; do
    git add -- "$file"
done

# 5) A partly staged file that spotless rewrote can't be re-staged safely: restore it and refuse.
needs_format=()
i=0
for file in ${partial[@]+"${partial[@]}"}; do
    if ! cmp -s -- "$file" "$snapshot/$i"; then
        cp -p -- "$snapshot/$i" "$file"
        needs_format+=("$file")
    fi
    i=$((i + 1))
done
if ((${#needs_format[@]} > 0)); then
    echo "*********************************************"
    echo "  Commit refused: partly staged files need formatting"
    echo "*********************************************"
    printf '  %s\n' "${needs_format[@]}"
    echo "These files have both staged and unstaged changes, so the hook can't re-stage"
    echo "spotless's fixes without committing your unstaged hunks too (the files are unchanged)."
    echo "Run ./gradlew spotlessApply, review and stage the result, then commit again."
    exit 1
fi

# 6) Run the full verification suite.
if ./gradlew detekt diktatCheck spotlessCheck --daemon; then
    echo "*********************************************"
    echo "      Static analysis no problems found      "
    echo "*********************************************"
    exit 0
else
    echo "*********************************************"
    echo "            Static Analysis Failed           "
    echo "Please fix the above issues before committing"
    echo "*********************************************"
    exit 1
fi
