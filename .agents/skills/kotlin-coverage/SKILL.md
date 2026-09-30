---
name: kotlin-coverage
description: Use when a Kover or Jacoco coverage gate fails, or to find and close coverage gaps — running the gates, listing uncovered lines per file with the bundled script, and covering them with tests that assert behavior.
---

# Kotlin coverage

Two gates, both **floors**: raise them or keep them. Close a gap with tests, never by lowering a
threshold, and the gate-guard hook refuses such an edit anyway.

| Gate | Threshold | Scope | Configured in |
| --- | --- | --- | --- |
| `koverVerify` | ≥ 80% lines | per module, `core` only | `core/build.gradle.kts` |
| `jacocoTestCoverageVerification` | ≥ 50% | aggregated over `app` + `core` | root `build.gradle.kts` |

Why they differ: [`CLAUDE.md`](../../../CLAUDE.md) ("Coverage is dual-gated").

## 1. Run the gates

```bash
./gradlew koverVerify jacocoTestCoverageVerification --continue
```

**Done when:** you have both results: `BUILD SUCCESSFUL`, or each failing task's
`Rule violated: ... is X, but expected minimum is Y` line.

## 2. List the uncovered lines

```bash
./gradlew koverXmlReport
python3 .agents/skills/kotlin-coverage/scripts/uncovered_lines.py          # every module
python3 .agents/skills/kotlin-coverage/scripts/uncovered_lines.py core     # one module
```

It prints each module's line coverage, then per file the **missed** lines (never ran) and
**partial** lines (ran, but some branches never did). Partial lines on `suspend` calls are often
Kotlin-generated branches rather than untested logic; read
[`partial-lines.md`](partial-lines.md) before writing tests for them.

**Done when:** you have the list for every module the gate covers, and no "report is older than
the sources" warning.

## 3. Cover each line with a behavior test

For each listed line, name the behavior it implements (a branch, an error path, an edge input) and
write a test that asserts that behavior, following the
[`kotlin-testing`](../kotlin-testing/SKILL.md) skill. The test must fail if the line's behavior
changed. A test that only executes the line is rejected; see
[`testing.md`](../../reference/testing.md#coverage).

**Done when:** every listed line is covered by a test that asserts its behavior, or is named in
your report with the reason it isn't worth a test (e.g. a coroutine branch per `partial-lines.md`).

## 4. Re-run

Run step 1's gates and step 2's script again.

**Done when:** both gates pass, and the script no longer lists the lines you covered. Report
coverage before and after. If a module now clears its floor by a wide margin, say so; raising a
floor is the owner's call.
