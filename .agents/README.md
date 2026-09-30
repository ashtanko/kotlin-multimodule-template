# Agent workspace

This directory contains shared, vendor-neutral context for coding agents.
[`../AGENTS.md`](../AGENTS.md) is the canonical contract; vendor files such as
[`../CLAUDE.md`](../CLAUDE.md) adapt or point to it rather than duplicating it.

## Layout

```text
.agents/
├── reference/                        # Project facts loaded only when relevant
│   ├── coding-conventions.md         # Naming, null-safety, data modeling, SOLID, quick reference
│   ├── testing.md                    # Test framework, style, coroutine/Flow testing, definition of done
│   └── commands.md                   # Which check to run for which kind of change
├── rules/
│   └── kotlin-conventions.md         # Pointers into AGENTS.md/.agents/CLAUDE.md, for tools reading .agents/rules
└── skills/                           # Reusable, portable Kotlin task workflows (SKILL.md format)
    ├── kotlin-control-flow/
    ├── kotlin-functions/
    ├── kotlin-types-value-class/
    ├── kotlin-coroutines-structured-concurrency/
    ├── kotlin-flow-state-event-modeling/
    ├── kotlin-testing/               # + coroutine-tests.md
    ├── kotlin-coverage/              # + partial-lines.md, scripts/uncovered_lines.py
    ├── kotlin-mutation-testing/      # + mutators.md, equivalent-mutants.md, scripts/surviving_mutants.py
    └── gradle-quality-check/
```

## Context map

| Task | Load first | Add when relevant |
| --- | --- | --- |
| General coding conventions (naming, null-safety, scope functions, SOLID) | [`reference/coding-conventions.md`](reference/coding-conventions.md) | The focused skill below for a deep procedure |
| Branching / `when` expressions / exhaustiveness / smart casts | [`skills/kotlin-control-flow/SKILL.md`](skills/kotlin-control-flow/SKILL.md) | `reference/coding-conventions.md` |
| Coroutine scope ownership, cancellation, `runBlocking` | [`skills/kotlin-coroutines-structured-concurrency/SKILL.md`](skills/kotlin-coroutines-structured-concurrency/SKILL.md) | `reference/testing.md` for the test-side rules |
| `StateFlow` / `SharedFlow` / `Channel` / event modeling | [`skills/kotlin-flow-state-event-modeling/SKILL.md`](skills/kotlin-flow-state-event-modeling/SKILL.md) | The coroutines skill above |
| Choosing where a function belongs (member/top-level/extension) | [`skills/kotlin-functions/SKILL.md`](skills/kotlin-functions/SKILL.md) | — |
| `@JvmInline value class` vs `data class` | [`skills/kotlin-types-value-class/SKILL.md`](skills/kotlin-types-value-class/SKILL.md) | `kotlin-functions` for construction/parsing placement |
| Selecting or reviewing tests | [`reference/testing.md`](reference/testing.md) | `reference/commands.md` |
| Writing or changing tests for a behavior change or bug fix | [`skills/kotlin-testing/SKILL.md`](skills/kotlin-testing/SKILL.md) | `reference/testing.md` (the rules it applies) |
| Coverage gate failing, finding uncovered lines | [`skills/kotlin-coverage/SKILL.md`](skills/kotlin-coverage/SKILL.md) | `kotlin-testing` for the tests it asks for |
| Mutation testing (PIT), surviving mutants | [`skills/kotlin-mutation-testing/SKILL.md`](skills/kotlin-mutation-testing/SKILL.md) | `kotlin-testing` for the tests it asks for |
| Choosing which command to run | [`reference/commands.md`](reference/commands.md) | — |
| Running formatting/static-analysis/tests/coverage/mutation checks | [`skills/gradle-quality-check/SKILL.md`](skills/gradle-quality-check/SKILL.md) | `reference/commands.md` |
| Build, CI, tooling versions, generated README, git hooks | [`../CLAUDE.md`](../CLAUDE.md) | — |

The skills use the portable `SKILL.md` format: front matter with `name`/`description`, then a
procedure. Any agent can follow the linked file directly when the task matches. For Claude Code,
each one also has a thin wrapper at `../.claude/skills/<name>/SKILL.md` (same `description`, a
body pointing back here), so Claude Code discovers it, can trigger it, and exposes it as
`/<name>`. The wrappers are plain files, not symlinks, which break on Windows checkouts without
`core.symlinks`. The canonical content stays here.

## Where these came from

The skills under `skills/` were ported from a companion Android/Compose template's `.agents/`
workspace, filtered to the Kotlin-language material that applies to a plain JVM project (dropped:
Android component/lifecycle, Compose, Hilt/DI-framework, and Kotlin Multiplatform content — none of
it applies here, since this repo has no Android target, no UI framework, and no multiplatform
source sets). `reference/coding-conventions.md` and `reference/testing.md` are this repository's own
long-standing conventions, restructured to match that layout.

## Maintenance

- Keep [`../AGENTS.md`](../AGENTS.md) short and stable; put detailed or task-specific material here.
- Adding or renaming a skill: add or update its `../.claude/skills/<name>/SKILL.md` wrapper, and
  keep the wrapper's `description` identical to the canonical one (it is what triggers the skill
  in Claude Code). Add it to the layout and context map above and to `../AGENTS.md`'s task list.
- Keep fast-changing dependency versions in [`../gradle/libs.versions.toml`](../gradle/libs.versions.toml)
  and link to it instead of copying values into agent docs.
- If `core/src/main/kotlin/dev/shtanko/template/core/` stops being example/placeholder code (see
  [`../CLAUDE.md`](../CLAUDE.md) — "What this repo is"), update the file references in
  `reference/coding-conventions.md`, `reference/testing.md`, and the skills under `skills/` to point
  at the new canonical examples.
- A change to `config/detekt/detekt.yml`, `.editorconfig`, or the Kotlin language-level pin in
  `buildSrc/src/main/kotlin/template.kotlin-library.gradle.kts` should be reflected in
  `reference/coding-conventions.md`'s "Enforced by tooling" and "Project context" sections in the
  same change.
