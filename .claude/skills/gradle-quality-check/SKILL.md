---
name: gradle-quality-check
description: Use when verifying a Kotlin change before finishing, or diagnosing a build, lint, test, coverage or mutation failure — runs formatting, static analysis, unit tests, the coverage gates and mutation tests.
allowed-tools: Bash(make check), Bash(make test), Bash(./gradlew koverVerify:*), Bash(./gradlew :core:pitest:*)
---

Read and follow [`.agents/skills/gradle-quality-check/SKILL.md`](../../../.agents/skills/gradle-quality-check/SKILL.md), the canonical,
vendor-neutral version of this skill. Resolve the paths in it relative to that file; its
supporting files and scripts sit next to it.
