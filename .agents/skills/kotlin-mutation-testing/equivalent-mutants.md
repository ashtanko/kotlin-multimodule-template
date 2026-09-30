# Equivalent mutants

A mutant is **equivalent** when no test can tell it from the original: every caller behaves the
same under it. Record one only with a proof. A mutant that is hard to kill is not equivalent.

## The proof a reason needs

The reason names one of these, specifically enough that a reviewer can check it in the code:

- **Discarded value**: every consumer of the mutated value ignores it. Name the consumer, e.g.
  "the `Unit` result of `FlowCollector.emit` is ignored by its caller".
- **Unreachable path**: no input reaches the mutated instruction. Name the fact that blocks it,
  e.g. "`fetchIds()` always returns id 3 and `processId(3)` always throws, so the flow body never
  completes normally".

## Kotlin and coroutine patterns

The Arcmutate Kotlin plugin, which filters these automatically, is commercial and not used here,
so they show up in the report:

| Mutant | Usually | Why |
| --- | --- | --- |
| `NullReturnValsMutator` on the **last** return of a `suspend` lambda or function returning `Unit` (a `flow { }` body, a `catch { }` action, a `FlowCollector.emit`) | Equivalent | That return only ever carries `Unit`, and the caller discards the result of a `Unit` call. |
| `NullReturnValsMutator` on a continuation's `invokeSuspend` that can return `COROUTINE_SUSPENDED` | **Killable** | See [`mutators.md`](mutators.md#coroutine-code). |
| Mutants on a path that only runs when the upstream flow **completes normally**, while every run ends in an exception | Equivalent (unreachable) | Only completion runs that code. |
| Mutants in `kotlinx.coroutines` code inlined into your class (source file `Emitters.kt`, `SafeCollector.common.kt`, …) | Either | Decide as above. The inlined operator's behavior is yours to test, but its `Unit` plumbing is not. |

## Recording one

Append one line to [`config/pitest/equivalent-mutants.txt`](../../../config/pitest/equivalent-mutants.txt):

```text
<key> | <reason: discarded value or unreachable path, as above>
```

Copy `<key>` exactly as the summary script prints it. It includes the line number, so the entry
stops matching when the code moves. The mutant then shows as unresolved again, and the reason
gets re-checked against the new code.
