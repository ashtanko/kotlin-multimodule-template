# Killing a mutant, by mutator

The mutator is the third field of each line the summary script prints. The test that kills it
asserts the value or effect the mutation changes, with an input where the original and the mutant
differ.

| Mutator | What PIT changed | Test that kills it |
| --- | --- | --- |
| `MathMutator` | `+`↔`-`, `*`↔`/`, `%`→`*`, `&`↔`\|`, … | An input where the two operators give different results. `add(0, 0)` can't tell `+` from `-`; `add(1, 3)` can. |
| `ConditionalsBoundaryMutator` | `<`↔`<=`, `>`↔`>=` | The boundary itself: the input equal to the limit. |
| `NegateConditionalsMutator` | `==`↔`!=`, `<`↔`>=`, … | Both outcomes of the condition, each with its own assertion. |
| `PrimitiveReturnsMutator` | A primitive return replaced by `0` / `0.0` | Assert the returned value for an input whose result isn't 0. |
| `NullReturnValsMutator` | An object return replaced by `null` | Assert the returned object, or a property of it. See below for coroutine code. |
| `EmptyObjectReturnValsMutator` | A return replaced by `""`, an empty list, `0` | Assert the content, not just the type or non-nullness. |
| `BooleanTrueReturnValsMutator` / `BooleanFalseReturnValsMutator` | A `Boolean` return replaced by a constant | Cases where it returns `true` and where it returns `false`. |
| `VoidMethodCallMutator` | A call to a `Unit` function removed | Assert the call's side effect (state change, emission, callback). |
| `IncrementsMutator` | `i++` → `i--` and similar | Assert a count or index that depends on the increment. |
| `InvertNegsMutator` | `-x` → `x` | A non-zero input. |

## Coroutine code

A `suspend` function or lambda compiles to a state machine. Its `invokeSuspend`/`emit` returns
either the result or the `COROUTINE_SUSPENDED` marker, which tells the caller to wait. A
`NullReturnValsMutator` on a return that can carry the marker is killable: the caller resumes
early, before the suspended work finishes. The mutant shows only when that call really suspends
at that point:

- For a `Flow` operator (`map`, `onEach`, …) between an upstream and a collector, make the
  **collector** suspend: collect in the test body with a slow collector, not through Turbine. See
  [`kotlin-testing/coroutine-tests.md`](../kotlin-testing/coroutine-tests.md#slow-collectors-backpressure).
  Then assert the complete, ordered result list.
- For a `suspend fun`, make its callee suspend (a `delay` or `withContext` on the test dispatcher)
  and assert everything that happens after the call.

A return that can only carry `Unit` is usually equivalent instead; see
[`equivalent-mutants.md`](equivalent-mutants.md).
