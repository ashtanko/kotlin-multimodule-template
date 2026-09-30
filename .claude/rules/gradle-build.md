---
paths:
  - "**/*.gradle.kts"
  - "gradle/libs.versions.toml"
---

# Gradle build files

- Versions go only in `gradle/libs.versions.toml`, including tool versions a plugin takes as a
  string (e.g. PIT's `pitestVersion`); build scripts read them through `libs`.
- Config every module shares goes only in the convention plugin,
  `buildSrc/src/main/kotlin/template.kotlin-library.gradle.kts`. A module's `build.gradle.kts`
  keeps what is specific to that module.

The reasoning, and what the root build script owns, is in [`CLAUDE.md`](../../CLAUDE.md) ("Shared
build logic lives in `buildSrc`", "Versions are centralized").
