# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is a **GitHub template** for bootstrapping Kotlin/JVM projects, not a product. It's a two-module Gradle build: `app` (the entry point, `Application.kt`) and `core` (`Calculator`, `DataProcessor`, `DivideByZeroException` under `core/src/main/kotlin/dev/shtanko/template/core/`) — both placeholder/example code that demonstrates the toolchain, expect it to be replaced. The value of the repo is the preconfigured build, static-analysis, testing, and CI setup. When customizing for a real project, `scripts/rename-project.sh -n <name> -p <package>` rewrites the project name, Kotlin package, and `application.mainClass` throughout the repo, across every module (`--dry-run` to preview).

**Shared build logic lives in `buildSrc`.** Every module applies the `template.kotlin-library` convention plugin (`buildSrc/src/main/kotlin/template.kotlin-library.gradle.kts`), which bundles the Kotlin/JVM toolchain, detekt/diktat/spotless/Kover/jacoco, and the JUnit 5 test stack in one place instead of repeating it per module. Module-specific things (dependencies, `application.mainClass`, Pitest config) stay in that module's own `build.gradle.kts`.

**`AGENTS.md` is the canonical entry point for coding conventions** and delegates to
[`.agents/`](.agents/README.md) — `.agents/reference/coding-conventions.md` and
`.agents/reference/testing.md` hold the naming/null-safety/SOLID/testing rules, and
`.agents/skills/` holds deep, portable procedures (coroutine scope ownership, `Flow` primitive
choice, branching, function ownership, value classes). Consult those rather than re-deriving style
rules, and don't duplicate that content here — this file owns *how the repo operates* (build,
tooling, CI), `AGENTS.md`/`.agents/` own *how to write the code*.

## Common commands

```bash
./gradlew build                 # compile + run tests
./gradlew run                   # run the app (main: dev.shtanko.template.ApplicationKt)
make test                       # run the test suite (= ./gradlew test)
make check                      # spotlessApply, then spotlessCheck + detekt + diktatCheck (--continue)
make lint                       # same checks without auto-formatting (= CI's static-analysis step)
make format                     # auto-format only (= ./gradlew spotlessApply)
./gradlew spotlessApply         # auto-format and apply license headers (run before committing)
./gradlew :core:pitest          # mutation testing; fails below core's mutationThreshold
```

Run a single test class or method (standard Gradle test filtering; scope to a module with `:core:test`/`:app:test`, or let `./gradlew test` fan out across both):

```bash
./gradlew :core:test --tests "dev.shtanko.template.core.ExampleTest"
./gradlew :core:test --tests "dev.shtanko.template.core.ExampleTest.should return true when input is valid"
```

Coverage and mutation helpers (the `kotlin-coverage` and `kotlin-mutation-testing` skills run these):

```bash
./gradlew koverVerify jacocoTestCoverageVerification                                 # both coverage gates
./gradlew koverXmlReport && python3 .agents/skills/kotlin-coverage/scripts/uncovered_lines.py  # uncovered lines per file
./gradlew :core:pitest -PpitestTargetClasses='dev.shtanko.template.core.Calculator*'  # narrowed PIT run, no threshold
python3 .agents/skills/kotlin-mutation-testing/scripts/surviving_mutants.py          # score + unresolved mutants
```

Claude Code slash commands are the skills in `.claude/skills/`: `/lint`, `/test [filter]`, `/kotlin-testing`, `/kotlin-coverage`, `/kotlin-mutation-testing`, `/gradle-quality-check`, and the Kotlin-style skills (`/kotlin-control-flow`, …).

## Architecture and conventions that span multiple files

**The README is generated — never edit `README.md` by hand.** `make md` rebuilds it by concatenating `config/main.md` + `build/reports/detekt/detekt.md` + `config/license.md`. Edit `config/main.md` for prose changes, then run `make md` (or `make all`). Because the detekt markdown report is part of the README, you must have run detekt for that section to exist.

**Versions are centralized.** All dependency and plugin versions live in `gradle/libs.versions.toml` (the `libs.*` version catalog). Change versions there, not inline in `build.gradle.kts`.

**Three overlapping static-analysis tools** are enforced: `detekt`, `diktat`, and `spotless`. `make check` runs all of them; CI runs them independently. All three are applied per module by the `template.kotlin-library` convention plugin, so `./gradlew detekt` (no module prefix) fans out to `:app:detekt` + `:core:detekt` automatically — same for `diktatCheck`/`spotlessCheck`. The root `build.gradle.kts` adds Spotless only for files outside modules (root/`buildSrc` Gradle scripts, and yml/toml/properties/sh config files). There is no ktlint: its rules were switched off and it ran with `ignoreFailures`, so it was removed; diktat (built on ktlint's engine) and detekt cover that ground.

- **Every diktat and detekt rule is enabled**, over `src/main` *and* `src/test`. `diktat-analysis.yml` has no `enabled: false` entries and `config/detekt/detekt.yml` no inactive rules; keep it that way — fix the code, or use a narrow `@Suppress("RULE_ID")` with a reason (see `main` in `Application.kt`) rather than switching a rule off. The only scoping is detekt's usual test-dir `excludes` (e.g. `FunctionMaxLength`, because tests use backticked sentence names). Note plain `detekt` runs without type resolution, so rules like `ForbiddenMethodCall` only fire under `detektMain`/`detektTest`.
- **The Apache license header is checked three times**, all against the same text: Spotless writes it from `spotless/copyright.kt` (`./gradlew spotlessApply` adds it to new files), diktat's `HEADER_MISSING_OR_WRONG_COPYRIGHT` matches it via `copyrightText` in `diktat-analysis.yml`, and detekt's `AbsentOrWrongFileLicense` via the regex `config/detekt/license.template`. Change all three together. Files without exactly one class also need a file-level KDoc between the header and `package` (diktat's `HEADER_MISSING_IN_NON_SINGLE_CLASS_FILE`); the Spotless header delimiter stops at `/**` so it survives.
- Detekt uses `config/detekt/detekt.yml` with a baseline at `config/detekt/detekt-baseline.xml`, shared by every module, for pre-existing issues.

**Kotlin language level is pinned below the compiler version.** The `template.kotlin-library` convention plugin sets `apiVersion`/`languageVersion` to `KOTLIN_2_2` for every module even though the Kotlin plugin/compiler is `2.4.0`. Don't use language features newer than 2.2 in source even though a 2.4 compiler is running.

**Coverage is dual-gated, at different granularities.** Jacoco enforces ≥ 50% (`jacocoTestCoverageVerification`) *aggregated* across `app` + `core` — hand-rolled at the root (`build.gradle.kts`) since Jacoco has no built-in multi-module merge. Kover enforces ≥ 80% (`kover.reports.verify.rule.minBound(80)`) *per module*, but only on `core`/`build.gradle.kts` — `app` is bootstrap/wiring code with nothing worth gating. (Kover does have built-in cross-project aggregation via `dependencies { kover(project(...)) }`, but as of Kover 0.9.9 it fails to resolve `kotlin-stdlib:2.4.10`, now published as a Kotlin Multiplatform module — a known limitation, not something fixable from this repo.) Reports: `./gradlew jacocoTestReport` (HTML/XML/CSV, aggregated) and `./gradlew koverHtmlReport` (per module).

**Mutation testing is gated locally, not in CI.** PIT runs on `core` only (`./gradlew :core:pitest`, not part of `check`) and fails below `mutationThreshold` (80: the 28/33 = 84.8% score rounded down to a multiple of 5). `-PpitestTargetClasses=<glob>[,...]` narrows a run to some classes and skips the threshold. Mutants no test can kill are recorded with their reason in `config/pitest/equivalent-mutants.txt`, which the `kotlin-mutation-testing` skill's summary script reads. The Gradle plugin (`pitestPlugin`), PIT core (`pitest`) and its JUnit 5 plugin (`pitestJunit5`) are separate catalog versions, so Renovate bumps each on its own.

**Every threshold is a floor.** Kover's `minBound`, Jacoco's `minimum` and PIT's `mutationThreshold` get raised or kept, never lowered; close a gap with tests.

**Git hooks self-install via Gradle.** The `clean` task depends on `installGitHooks`, which copies `scripts/git-hooks/*.sh` into `.git/hooks/` (Linux/macOS only, via `isLinuxOrMacOs()` in the root build script: the hooks are bash). Commits that touch no Kotlin, Gradle or lint/config file skip Gradle.

- **`pre-commit`** records the staged files, runs `spotlessApply`, re-stages only the files that were fully staged, then runs `detekt diktatCheck spotlessCheck` and blocks the commit on failure. A partly staged file is never re-staged (that would commit its unstaged hunks): if spotless would reformat one, the hook restores it and refuses the commit.
- **`commit-msg`** enforces the Conventional Commits format from "PRs" below; git's merge and revert messages and `fixup!`/`squash!`/`amend!` commits pass.

**Claude Code hooks guard the gates and lint and test AI edits.** Separately from the git hooks above (which fire at commit time), `.claude/settings.json` registers two hooks:

- **`PreToolUse` on Edit/MultiEdit/Write → `scripts/claude/gate-guard.sh`.** It denies edits to generated files (`README.md`, `build/**`, `config/detekt/detekt-baseline.xml`), naming the real source, and edits that weaken a gate: `enabled: false` in `diktat-analysis.yml`, `active: false` in `config/detekt/*.yml`, a lowered or removed `minBound`/`minimum`/`mutationThreshold` in a `.kts` file, or a new `ignoreFailures = true`. It compares the file before and after the edit with plain shell + jq pattern matches (~10 ms, no Gradle), and fails open: if jq is missing or anything goes wrong it allows the edit with a notice. It doesn't see Bash edits (`sed -i`), so it's a guard rail, not a sandbox.
- **`Stop` → `scripts/claude/lint-hook.sh`** fires when the agent finishes a turn. If any `.kt`/`.kts` file, the version catalog or lint config changed (new untracked files included), it runs `spotlessApply` (the only auto-fix), then one Gradle run of `detekt diktatCheck spotlessCheck --continue` across every module plus `test koverVerify` for the modules whose files changed (every module when `buildSrc`, a root build script or the catalog changed). All remaining failures go back to the agent, failing tests with their assertion message (the convention plugin logs them even under `--quiet`). It re-checks after each fix and gives up with a notice to the user after 3 blocked stops in a row. A turn that changed none of those files exits without starting Gradle. Run the same checks on demand with `/lint` and `/test`.

**Claude Code skills and rules are pointers.** Each `.claude/skills/<name>/SKILL.md` wraps the canonical `.agents/skills/<name>/SKILL.md`: same `description` (the trigger), and a body pointing back. Edit the canonical file, and keep the two descriptions identical. Only `/lint` and `/test` are Claude-only skills. `.claude/rules/*.md` are path-scoped (`paths:` frontmatter) and load when Claude reads a matching file: `tests.md` for `**/src/test/**/*.kt`, `gradle-build.md` for `**/*.gradle.kts` and the version catalog.

## CI

`.github/workflows/ci.yml` runs on pushes to `main`, PRs and `workflow_dispatch`, as two parallel jobs. Match it locally with `make check && make test` before pushing.

- **`lint`** runs `make lint` once and uploads the merged detekt/diktat SARIF (`build/reports/detekt/merge.sarif`, `build/reports/diktat/diktat-merged.sarif`, produced by root `detektReportMerge`/`mergeDiktatReports`) to GitHub code scanning.
- **`test`** is a JDK 17/21 matrix running `build` minus the lint tasks. `jvmToolchain(17)` would otherwise run the tests on 17 in both legs, so CI passes `-PtestJdk=<matrix JDK>` (read by the convention plugin to pick the `Test` launcher); `./gradlew test -PtestJdk=21` does the same locally. The JDK 17 leg uploads each module's Kover XML to Codecov/Codacy.
- **Secrets are optional.** Codecov/Codacy steps run only when `CODECOV_TOKEN`/`CODACY_PROJECT_TOKEN` exist, so fork/Dependabot PRs and repos created from the template stay green without them.
- **PIT doesn't run in CI**; its threshold is a local gate (see above).
- **Actions are pinned to commit SHAs** with a `# vX.Y.Z` comment; Renovate (`helpers:pinGitHubActionDigests`) keeps both current. There is no Dependabot config — Renovate owns all updates.

## PRs

Use [Conventional Commits](https://www.conventionalcommits.org/) for titles: `<type>(<scope>): <description>`, types `feat`/`fix`/`chore`/`docs`/`test`/`refactor`. The `commit-msg` git hook enforces the same format on commits.
