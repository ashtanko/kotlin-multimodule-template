# Commands and validation

The full command list, and what each tool does, lives in [`CLAUDE.md`](../../CLAUDE.md) (`Common
commands` section) so it isn't duplicated here. This file is only a selection guide: which check to
run for which kind of change.

## Selecting a check

| Change | Run |
| --- | --- |
| Iterating on one test class/method | `./gradlew :core:test --tests "dev.shtanko.template.core.ExampleTest"` (or `.method`; use the module the class lives in) |
| Any `.kt` source change | `./gradlew spotlessApply` (auto-fixes formatting/license headers), then `make check` |
| Behavior change | `make test` (= `./gradlew test`) |
| Before committing / finishing a task | `make check && make test` — this is what CI and the pre-commit hook both run |
| Coverage gate failing / finding uncovered lines | `./gradlew koverVerify jacocoTestCoverageVerification`, then the [`kotlin-coverage`](../skills/kotlin-coverage/SKILL.md) skill |
| Test quality (not just coverage) | `./gradlew :core:pitest` (narrow with `-PpitestTargetClasses=...`), run deliberately, not part of `make check`/`make test`/CI; survivors: the [`kotlin-mutation-testing`](../skills/kotlin-mutation-testing/SKILL.md) skill |
| Docs-only change (`config/main.md`, this `.agents/` tree) | Nothing to build; if `config/main.md` changed, run `make md` to regenerate `README.md` (needs a prior `./gradlew detekt` run — see [`CLAUDE.md`](../../CLAUDE.md)) |

## Notes

- `make check` = `spotlessApply spotlessCheck detekt diktatCheck --continue`. It
  auto-formats first, then verifies every module, reporting all failing tools in one pass — running
  it twice in a row should be a no-op on the second run. `make lint` is the same verification
  without the auto-format (what CI runs); `make spotless`/`make detekt`/`make diktat` run one tool.
- `test --tests` accepts a bare class name, `Class.method`, or a fully-qualified pattern; see
  [`CLAUDE.md`](../../CLAUDE.md) for exact examples. If Gradle reports the `test` task as
  `UP-TO-DATE` and a genuine re-run is needed, use `./gradlew cleanTest test`.
- Never claim a check passed without having run it in this session.
- Git hooks self-install via Gradle (`installGitHooks`, wired to `clean`): pre-commit runs
  `spotlessApply` (re-staging only what you had staged), then `detekt diktatCheck spotlessCheck`;
  commit-msg enforces Conventional Commits. `make check` locally before committing avoids
  surprises there.
