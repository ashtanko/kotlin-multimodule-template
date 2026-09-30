# Testing `suspend` and `Flow` code

For subjects that suspend or return a `Flow`. The rules (inject the dispatcher, `runTest` +
`StandardTestDispatcher`, Turbine, assert the complete sequence) are in
[`reference/testing.md`](../../reference/testing.md#coroutines-and-flow); this file covers the
cases [`DataProcessorTest`](../../../core/src/test/kotlin/dev/shtanko/template/core/DataProcessorTest.kt)
doesn't show.

## Virtual time

`runTest` skips `delay`s: `DataProcessor`'s 100 ms "network" delay costs no real time. When timing
is part of the contract, assert it on the scheduler's clock:

- `currentTime` (in `runTest`) is the virtual time elapsed so far.
- `advanceTimeBy(ms)` / `runCurrent()` / `advanceUntilIdle()` step a coroutine you `launch`ed
  (for a subject that runs in the background, e.g. in `backgroundScope`).

## Slow collectors (backpressure)

Turbine's `test { }` collects in its own coroutine, and `flowOn` puts a channel in front of it
whenever the collector runs on a different dispatcher. The upstream then never waits for the
collector, so a test that goes through Turbine can't see what happens when the collector is slow.
To exercise that, collect in the test body with a collector that suspends:

```kotlin
@Test
fun `slow collector still gets every result in order`() = runTest(testDispatcher) {
    val results = mutableListOf<Result<String>>()

    subject.stream().collect { result ->
        results += result
        delay(10.milliseconds)  // the collector is busy, so upstream `emit` suspends
    }

    assertEquals(expectedSequence, results)
}
```

`runTest(testDispatcher)` runs the body on the same dispatcher the subject's `flowOn` uses, so the
pipeline stays on one coroutine and each upstream `emit` waits for the collector.

## Cancellation and errors

- Turbine: `awaitError()` for a flow that fails, `cancelAndIgnoreRemainingEvents()` to stop a flow
  that doesn't complete.
- A subject that wraps failures (`Result.failure`, a sealed error state) completes normally, so
  assert the wrapped error (`exceptionOrNull()?.message`), then `awaitComplete()`.
- For cancellation, `launch` the call, `cancel()` the job, `advanceUntilIdle()`, then assert that
  cleanup ran and nothing emitted after the cancel.
