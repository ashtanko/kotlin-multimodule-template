# Partial lines: logic or compiler artifact?

Kover counts bytecode branches, and the Kotlin compiler adds branches the source doesn't show. A
partial line needs a test only when the missed branch is a behavior of your code.

| Where the partial line is | Missed branch | Test it? |
| --- | --- | --- |
| A call to a `suspend` function (`delay`, `withContext`, `emit`, your own suspend fun) | The state machine's "call returned without suspending" check (`result == COROUTINE_SUSPENDED`). In `DataProcessor` every such call really suspends, so the other side never runs. | No: it isn't behavior. Name it in the report. |
| `for (x in list)` in a suspend function | The same suspension check around the loop body's suspend call | No, as above |
| `?.`, `?:`, `!!`, `as?` | The `null` (or non-null) path | Yes: pass the input that takes the other path |
| `if`/`when` branch, `require`/`check` | The condition's other outcome | Yes |
| `when` over a sealed type or enum | The compiler-generated `else` that throws | No: unreachable by construction |
| Function with default arguments | The synthetic `$default` bridge for a combination never called | Only if that combination is part of the API |

To tell which branch Kover means, open the module's HTML report (`./gradlew koverHtmlReport`, then
`<module>/build/reports/kover/html/index.html`): a yellow line's tooltip counts the missed
branches.
