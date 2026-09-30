---
name: kotlin-testing
description: Use when adding or changing Kotlin tests for a behavior change or bug fix — picking the module, modelling on the example tests, writing a regression test red-first, then running the narrow --tests filter and make test.
---

# Kotlin testing

The rules live in [`reference/testing.md`](../../reference/testing.md) (framework, naming, imports,
coroutines/Flow, definition of done). This skill is the order to apply them in. Finish each step's
**Done when** before starting the next.

## 1. Pick the module

The test belongs to the module that owns the code under test, in the same package:
`core/src/main/kotlin/<pkg>/Foo.kt` → `core/src/test/kotlin/<pkg>/FooTest.kt` (same for `app`). Add
to the existing test class for that production class when there is one; `ExampleTest` is
`Calculator`'s.

**Done when:** you can name the test file path, and its package matches the class under test.

## 2. Model on an example

- Plain code → [`ExampleTest.kt`](../../../core/src/test/kotlin/dev/shtanko/template/core/ExampleTest.kt):
  `@Test` with a backticked sentence name, `@ParameterizedTest` + `@CsvSource`, `@TestFactory`.
- `suspend`/`Flow` code → [`DataProcessorTest.kt`](../../../core/src/test/kotlin/dev/shtanko/template/core/DataProcessorTest.kt):
  the subject is built with the test's `StandardTestDispatcher`. Also read
  [`coroutine-tests.md`](coroutine-tests.md) for what the example doesn't show: virtual time, slow
  collectors, cancellation.

**Done when:** the new test copies its example's shape: class layout, subject construction,
Arrange-Act-Assert.

## 3. Regression: red first

When the change fixes a bug, write the test against the unfixed code and run it (step 5's narrow
command). It must go **red** on the assertion that describes the bug; a compile error or an
unrelated exception doesn't count. Then fix the code and watch the same test go green.

**Done when:** you have seen the red run's failing assertion message, then the green run. For new
behavior without a bug, this step is done when the test exists.

## 4. Apply the testing.md rules

Apply every section of [`testing.md`](../../reference/testing.md) that the test touches: the
*Framework and style* rules (backticked names only on `@Test`, lowerCamelCase for
`@ParameterizedTest`/`@TestFactory`, diktat's import order), and *Coroutines and Flow* (`runTest` +
`StandardTestDispatcher` + Turbine, the complete emission sequence). Add the license header with
spotless rather than by hand.

**Done when:** `./gradlew spotlessApply :<module>:detekt :<module>:diktatCheck` is green. diktat and
detekt check test sources too.

## 5. Run narrow, then everything

```bash
./gradlew :core:test --tests "dev.shtanko.template.core.ExampleTest"          # the class
./gradlew :core:test --tests "dev.shtanko.template.core.ExampleTest.Divide test"  # one method
make test                                                                     # every module
```

If Gradle reports `test` as `UP-TO-DATE` and you need a real re-run, use `cleanTest test`.

**Done when:** the narrow filter ran your new tests (non-zero count, all passing) and `make test`
passed. Report both commands and their results.
