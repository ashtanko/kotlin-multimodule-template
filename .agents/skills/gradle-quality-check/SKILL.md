---
name: gradle-quality-check
description: Use when verifying a Kotlin change before finishing, or diagnosing a build, lint, test, coverage or mutation failure — runs formatting, static analysis, unit tests, the coverage gates and mutation tests.
---

# Gradle quality check

Run the steps in order; each must be green before the next. What each command covers is in
[`reference/commands.md`](../../reference/commands.md).

1. **Auto-format and static analysis**

   ```bash
   make check
   ```

   Runs `spotlessApply` (formatting, license headers), then `spotlessCheck`, `detekt` and
   `diktatCheck` in every module. **Done when:** `BUILD SUCCESSFUL`. For a detekt finding, fix the
   code or add a narrow `@Suppress("RuleName")` with a reason; the baseline doesn't grow.

2. **Unit tests**

   ```bash
   make test                                                           # every module
   ./gradlew :core:test --tests "dev.shtanko.template.core.ExampleTest"  # one class
   ```

   **Done when:** every test passes. Writing or fixing tests: the
   [`kotlin-testing`](../kotlin-testing/SKILL.md) skill.

3. **Coverage gates**

   ```bash
   ./gradlew koverVerify jacocoTestCoverageVerification
   ```

   Kover ≥ 80% per module (`core`) and Jacoco ≥ 50% aggregated over `app` + `core`
   (`jacocoTestReport`/`koverHtmlReport` only generate reports). **Done when:** both pass. Closing
   a gap: the [`kotlin-coverage`](../kotlin-coverage/SKILL.md) skill.

4. **Mutation tests**

   ```bash
   ./gradlew :core:pitest
   ```

   **Done when:** the build passes `core`'s `mutationThreshold`. Handling survivors: the
   [`kotlin-mutation-testing`](../kotlin-mutation-testing/SKILL.md) skill.

5. **Regenerate the README** (only when `config/main.md` changed)

   ```bash
   make md
   ```

   **Done when:** `README.md` is rebuilt, from `config/main.md` + the detekt report +
   `config/license.md`.

Every threshold above is a floor: fix the code or add tests, and keep every gate enabled.
