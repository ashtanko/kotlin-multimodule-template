---
name: lint
description: Use to run the full static-analysis suite (spotless, detekt, diktat) across every module and report what fails.
allowed-tools: Bash(make check), Bash(./gradlew spotlessApply:*), Bash(./gradlew detekt diktatCheck spotlessCheck:*)
---

Run the project's static-analysis suite with Gradle and report the result.

Every diktat and detekt rule is enabled, over main and test sources, in every module. This is the
same suite the Stop hook runs automatically after code changes (`scripts/claude/lint-hook.sh`) and
that CI enforces. Use `/lint` for an on-demand check.

## 1. Run

- Run `make check` (= `./gradlew spotlessApply spotlessCheck detekt diktatCheck --continue`). It
  auto-formats first, then verifies spotless, detekt and diktat.
- To only auto-fix formatting and license headers without the verification, run
  `./gradlew spotlessApply` instead.

**Done when:** Gradle finished and you have its result (`BUILD SUCCESSFUL`, or the failing
tasks).

## 2. Report

- **Success**: state that all checks passed in one line. Don't dump the log.
- **Failure**: show only the failing rule(s) and the file(s) they point at, not the whole log.
  detekt uses a baseline (`config/detekt/detekt-baseline.xml`), so only new issues are reported.
  Then open the relevant file and explain the likely fix.
- **Compilation error**: surface the compiler error itself rather than reporting it as a lint
  failure.

**Done when:** every failing rule is listed with its file and a likely fix.

Do not modify any source files unless the user asks you to fix the reported issues.
