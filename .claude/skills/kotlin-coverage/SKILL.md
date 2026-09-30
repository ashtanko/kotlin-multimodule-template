---
name: kotlin-coverage
description: Use when a Kover or Jacoco coverage gate fails, or to find and close coverage gaps — running the gates, listing uncovered lines per file with the bundled script, and covering them with tests that assert behavior.
allowed-tools: Bash(./gradlew koverVerify:*), Bash(./gradlew koverXmlReport:*), Bash(python3 .agents/skills/kotlin-coverage/scripts/uncovered_lines.py:*)
---

Read and follow [`.agents/skills/kotlin-coverage/SKILL.md`](../../../.agents/skills/kotlin-coverage/SKILL.md), the canonical,
vendor-neutral version of this skill. Resolve the paths in it relative to that file; its
supporting files and scripts sit next to it.
