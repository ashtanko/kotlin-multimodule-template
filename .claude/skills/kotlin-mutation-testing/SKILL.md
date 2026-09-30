---
name: kotlin-mutation-testing
description: Use when running PIT mutation tests (pitest) or handling surviving mutants — summarizing every SURVIVED/NO_COVERAGE mutant with the bundled script, killing each with a test or recording it as equivalent, and re-running until none is unresolved.
allowed-tools: Bash(./gradlew :core:pitest:*), Bash(python3 .agents/skills/kotlin-mutation-testing/scripts/surviving_mutants.py:*)
---

Read and follow [`.agents/skills/kotlin-mutation-testing/SKILL.md`](../../../.agents/skills/kotlin-mutation-testing/SKILL.md), the canonical,
vendor-neutral version of this skill. Resolve the paths in it relative to that file; its
supporting files and scripts sit next to it.
