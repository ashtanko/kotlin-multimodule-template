---
name: kotlin-tooling-immutable-collections-0-5-x-migration
description: >
  Migrate Kotlin (and Java) code from kotlinx.collections.immutable 0.3.x / 0.4.x to the
  latest 0.5.x. The 0.5.x line renames every copy-returning method on PersistentList /
  PersistentMap / PersistentSet / PersistentCollection to a participial form per KEEP-0459
  (add→adding, removeAt→removingAt, set→replacingAt, put→putting, clear→cleared, …) and
  deprecates the old names (WARNING, with ReplaceWith). Driven by the compiler: bump the
  version, recompile, and apply the rename each deprecation warning names. Use when the user
  mentions kotlinx.collections.immutable 0.5.x, PersistentList migration, "Use adding()
  instead", KEEP-0459, or sees deprecation warnings from kotlinx.collections.immutable.
---

Read and follow [`.agents/skills/kotlin-tooling-immutable-collections-0-5-x-migration/SKILL.md`](../../../.agents/skills/kotlin-tooling-immutable-collections-0-5-x-migration/SKILL.md), the canonical,
vendor-neutral version of this skill. Resolve the paths in it relative to that file; its
supporting files and scripts sit next to it.
