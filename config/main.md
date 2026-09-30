<h1 align="center">Kotlin App Template</h1></br>

<p align="center">
  <a href="https://opensource.org/licenses/Apache-2.0"><img alt="License" src="https://img.shields.io/badge/License-Apache%202.0-blue.svg"/></a>
  <a href="https://github.com/ashtanko/kotlin-app-template/actions/workflows/ci.yml"><img alt="Build Status" src="https://github.com/ashtanko/kotlin-app-template/actions/workflows/ci.yml/badge.svg"/></a>
  <a href="https://sonarcloud.io/dashboard?id=ashtanko_kotlin-app-template"><img alt="Quality Gate Status" src="https://sonarcloud.io/api/project_badges/measure?project=ashtanko_kotlin-app-template&metric=alert_status"/></a>
  <a href="https://sonarcloud.io/dashboard?id=ashtanko_kotlin-app-template"><img alt="Lines of Code" src="https://sonarcloud.io/api/project_badges/measure?project=ashtanko_kotlin-app-template&metric=ncloc"/></a>
  <a href="https://sonarcloud.io/dashboard?id=ashtanko_kotlin-app-template"><img alt="Coverage" src="https://sonarcloud.io/api/project_badges/measure?project=ashtanko_kotlin-app-template&metric=coverage"/></a>
  <a href="https://codecov.io/gh/ashtanko/kotlin-app-template"><img alt="Codecov" src="https://codecov.io/gh/ashtanko/kotlin-app-template/graph/badge.svg?token=FQFL6U7YL0"/></a>
  <a href="https://www.codefactor.io/repository/github/ashtanko/kotlin-app-template"><img alt="CodeFactor" src="https://www.codefactor.io/repository/github/ashtanko/kotlin-app-template/badge"/></a>
  <a href="https://app.codacy.com/gh/ashtanko/kotlin-app-template/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade"><img alt="Codacy Badge" src="https://app.codacy.com/project/badge/Grade/4935d531e41241faa0ce25eeddb67533"/></a>
  <a href="https://app.codacy.com/gh/ashtanko/kotlin-app-template/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_coverage"><img alt="Codacy Badge" src="https://app.codacy.com/project/badge/Coverage/4935d531e41241faa0ce25eeddb67533"/></a>
</p><br>

## Overview

A GitHub template for bootstrapping **Kotlin** projects with **static analysis**, **testing**, and **continuous integration** preconfigured and ready to go. Use this template to create a new Kotlin/JVM project and be up and running in seconds.

## Features 🦄

- **100% Kotlin-only template**.
- Multi-module layout (`app` + `core`) with shared build logic in a `buildSrc` convention plugin.
- Kotlin 2.4 with K2 Compiler.
- JVM 17+ target.
- 100% Gradle Kotlin DSL setup (Gradle 9.5).
- CI setup with GitHub Actions (builds on JDK 17 and 21).
- Aggressive Kotlin static analysis via `detekt`, `diktat`, and `spotless`.
- Test suite with JUnit 5, AssertJ, MockK, Mockito, and Turbine.
- Code coverage via Jacoco and Kover (≥ 80% enforced).
- Mutation testing via Pitest, with a mutation-score floor on `core`.
- API documentation via Dokka.
- Git hooks: pre-commit quality checks (partial commits stay partial) and Conventional Commits messages.
- Claude Code setup: skills for writing tests, closing coverage gaps and killing surviving mutants, and hooks that protect the quality gates and lint and test agent edits.
- Project rename script for quick customization.
- GitHub Issues templates (bug report + feature request).

## Requirements

| Tool   | Version |
|--------|---------|
| JDK    | 17+     |
| Gradle | 9.5 (included via wrapper) |

No additional installation is required — the Gradle wrapper (`./gradlew`) is included in the repository.

## Getting Started

### 1. Create a new repository from this template

Click **"Use this template"** on GitHub, or clone the repository directly:

```bash
git clone https://github.com/ashtanko/kotlin-app-template.git
cd kotlin-app-template
```

### 2. Rename the project (optional)

A rename script is provided to update the project name, package, and GitHub owner in one step:

```bash
./scripts/rename-project.sh -n "my-project" -p "com.example.myproject"
```

Run with `--help` for all available options, or `--dry-run` to preview changes.

### 3. Build the project

```bash
./gradlew build
```

### 4. Run the application

```bash
./gradlew run
```

> **Note:** The default main class is `dev.shtanko.template.ApplicationKt` (configured in `app/build.gradle.kts`). Update this to your own entry point after scaffolding.

## Scripts & Commands

### Makefile Shortcuts

| Command            | Description                                                             |
|--------------------|-------------------------------------------------------------------------|
| `make check`       | Auto-format, then run all static analysis in every module               |
| `make lint`        | Run all static analysis without auto-formatting (what CI runs)          |
| `make format`      | Auto-format code and apply license headers (`spotlessApply`)            |
| `make test`        | Run the test suite                                                      |
| `make report`      | Generate Jacoco coverage report                                         |
| `make kover`       | Generate Kover HTML coverage report                                     |
| `make spotless`    | Run Spotless check only                                                 |
| `make detekt`      | Run Detekt analysis only                                                |
| `make diktat`      | Run Diktat check only                                                   |
| `make md`          | Regenerate `README.md` from `config/main.md` + detekt report + license  |
| `make all`         | Run checks, build, and regenerate README                                |
| `make lines`       | Count lines of Kotlin code                                              |
| `make bump-gradle` | Upgrade the Gradle wrapper version                                      |

### Gradle Tasks

| Command                        | Description                                    |
|--------------------------------|------------------------------------------------|
| `./gradlew build`              | Compile and run tests                          |
| `./gradlew test`               | Run the test suite                             |
| `./gradlew run`                | Run the application                            |
| `./gradlew detekt`             | Run Detekt static analysis                     |
| `./gradlew diktatCheck`        | Check code style with Diktat                   |
| `./gradlew spotlessCheck`      | Check formatting and license headers           |
| `./gradlew spotlessApply`      | Auto-format code and apply license headers     |
| `./gradlew jacocoTestReport`   | Generate Jacoco coverage report                |
| `./gradlew koverHtmlReport`    | Generate Kover HTML coverage report            |
| `./gradlew koverXmlReport`     | Generate Kover XML coverage report             |
| `./gradlew koverVerify`        | Enforce Kover's per-module floor (`core` ≥ 80%) |
| `./gradlew jacocoTestCoverageVerification` | Enforce the aggregated Jacoco floor (≥ 50%) |
| `./gradlew dokkaGenerateHtml`  | Generate HTML API documentation (per module)   |
| `./gradlew :core:pitest`       | Run mutation tests (fails below the score floor) |

## Environment Variables

| Variable         | Description                          | Default                        |
|------------------|--------------------------------------|--------------------------------|
| `PITEST_THREADS` | Number of threads for mutation tests | Half of available CPU cores    |

<!-- TODO: Add additional environment variables here if needed (e.g., API keys, secrets) -->

## Testing

Tests are located in each module's `src/test/kotlin/` (e.g. `core/src/test/kotlin/`) and use:

- **JUnit 5** — test runner and parameterized tests
- **AssertJ** — fluent assertions
- **MockK** — Kotlin-idiomatic mocking
- **Mockito** — additional mocking support
- **Turbine** — Kotlin Flow testing

Run all tests:

```bash
./gradlew test
# or
make test
```

Generate coverage reports:

```bash
./gradlew jacocoTestReport   # Jacoco (HTML + XML + CSV)
./gradlew koverHtmlReport    # Kover
```

Run mutation testing (on `core`; the build fails below its `mutationThreshold`):

```bash
./gradlew :core:pitest
./gradlew :core:pitest -PpitestTargetClasses='dev.shtanko.template.core.Calculator*'  # only some classes, no threshold
```

Coverage is enforced at ≥ 50% via Jacoco, aggregated across `app` + `core` at the root. Kover enforces ≥ 80% per module with meaningful logic (`core`); `app` is bootstrap/wiring code and isn't gated.

## Project Structure

```
kotlin-app-template/
├── build.gradle.kts                # Root: whole-repo concerns (coverage aggregation, spotless, git hooks)
├── settings.gradle.kts             # Gradle settings (project name, module includes, repositories)
├── gradle.properties               # Gradle and Kotlin build properties
├── gradle/
│   └── libs.versions.toml          # Centralized dependency, plugin, and version catalog
├── buildSrc/
│   ├── build.gradle.kts            # buildSrc classpath (convention plugin's own dependencies)
│   ├── settings.gradle.kts         # Shares the root's version catalog with buildSrc
│   └── src/main/kotlin/
│       └── template.kotlin-library.gradle.kts  # Shared per-module convention plugin
├── app/                             # Application module (entry point)
│   ├── build.gradle.kts
│   └── src/main/kotlin/dev/shtanko/template/
│       └── Application.kt
├── core/                            # Library module (example business logic)
│   ├── build.gradle.kts
│   ├── src/main/kotlin/dev/shtanko/template/core/
│   │   ├── Calculator.kt           # Example calculator class
│   │   ├── DataProcessor.kt        # Example data processor with coroutines/Flow
│   │   └── DivideByZeroException.kt
│   └── src/test/kotlin/dev/shtanko/template/core/
│       ├── ExampleTest.kt          # Example calculator tests
│       └── DataProcessorTest.kt    # Data processor tests
├── Makefile                        # Task automation shortcuts
├── config/
│   ├── main.md                     # Source for the main README section
│   ├── license.md                  # License section appended to README
│   ├── detekt/
│   │   ├── detekt.yml              # Detekt rule configuration (shared by every module)
│   │   └── detekt-baseline.xml     # Detekt baseline for existing issues (shared)
│   └── pitest/
│       └── equivalent-mutants.txt  # Mutants no test can kill, with the reason
├── spotless/
│   └── copyright.kt               # License header template for Spotless
├── scripts/
│   ├── git-hooks/
│   │   ├── pre-commit.sh           # Pre-commit hook (format, then static analysis)
│   │   └── commit-msg.sh           # Conventional Commits check
│   ├── claude/
│   │   ├── gate-guard.sh           # Claude Code PreToolUse hook: protects generated files and quality gates
│   │   └── lint-hook.sh            # Claude Code Stop hook: lint + test what the agent changed
│   └── rename-project.sh           # Project rename utility
├── .github/
│   └── workflows/
│       └── ci.yml                   # GitHub Actions CI pipeline
├── codecov.yml                      # Codecov configuration
├── renovate.json                    # Renovate bot configuration for dependency updates
├── diktat-analysis.yml              # Diktat analysis configuration
├── checksum.sh                      # Checksum verification script
├── AGENTS.md                        # Canonical AI agent entry point
├── .agents/                         # Agent context map, reference docs, and Kotlin skills
│   ├── README.md                    # Context map (what to load for which task)
│   ├── reference/                   # coding-conventions.md, testing.md, commands.md
│   └── skills/                      # Portable SKILL.md procedures (testing, coverage, mutation, coroutines, …)
└── .claude/                         # Claude Code: hooks (settings.json), skill wrappers, path-scoped rules
```

## CI/CD

The project includes a GitHub Actions workflow (`.github/workflows/ci.yml`) that runs on every push to `main`, on pull requests, and on demand. Two jobs run in parallel:

1. **Static analysis** — `make lint` (`spotless`, `detekt`, `diktat`) once; detekt and diktat findings are uploaded to GitHub code scanning, so they show up as annotations on the PR.
2. **Test (JDK 17 and 21)** — builds, runs the tests *on each JDK* (`-PtestJdk`), and enforces the Kover/Jacoco coverage gates.

Codecov and Codacy are optional: add the `CODECOV_TOKEN` / `CODACY_PROJECT_TOKEN` repository secrets to enable per-module Kover coverage uploads and the Codacy Analysis CLI; without them those steps are skipped instead of failing. Reports are attached to failed runs as artifacts, and dependency and action updates come from Renovate (`renovate.json`), with actions pinned to commit SHAs.

## Contributing 🤝

Feel free to open an issue or submit a pull request for any bugs/improvements.

Use [Conventional Commits](https://www.conventionalcommits.org/) for PR titles:

```
<type>(<scope>): <short description>
```

Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`.

