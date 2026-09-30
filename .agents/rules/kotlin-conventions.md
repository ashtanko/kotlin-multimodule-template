# Kotlin conventions

For tools that read `.agents/rules/`. Every rule is written once, in the file linked here.

- **How to write the code**: [`AGENTS.md`](../../AGENTS.md), then the context map in
  [`.agents/README.md`](../README.md) for the reference or skill a task needs:
  - naming, null-safety, data modeling, SOLID: [`reference/coding-conventions.md`](../reference/coding-conventions.md)
  - tests: [`reference/testing.md`](../reference/testing.md) and the
    [`kotlin-testing`](../skills/kotlin-testing/SKILL.md) skill
  - which check to run: [`reference/commands.md`](../reference/commands.md)
- **How the repo operates** (build, tooling, quality gates, CI, hooks): [`CLAUDE.md`](../../CLAUDE.md)
