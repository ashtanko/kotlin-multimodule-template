---
name: kotlin-mutation-testing
description: Use when running PIT mutation tests (pitest) or handling surviving mutants — summarizing every SURVIVED/NO_COVERAGE mutant with the bundled script, killing each with a test or recording it as equivalent, and re-running until none is unresolved.
---

# Kotlin mutation testing

PIT mutates `core`'s bytecode and re-runs the tests; a mutant no test fails on is a **survivor**.
It runs on `core` only (`core/build.gradle.kts`). Its `mutationThreshold` is a **floor**: raise it
or keep it.

## 1. Run PIT

```bash
./gradlew :core:pitest                                                              # whole module
./gradlew :core:pitest -PpitestTargetClasses='dev.shtanko.template.core.Calculator*'   # while iterating
```

`-PpitestTargetClasses` takes comma-separated globs. End each one with `*` to keep the lambda and
coroutine classes Kotlin generates for the class. A narrowed run skips the threshold, since a
subset's score isn't comparable to it. The report, `core/build/reports/pitest/mutations.xml`, is
overwritten on every run, and it's written even when the threshold fails the build.

**Done when:** the run finished, with the threshold result if it was a whole-module run, and
`mutations.xml` is from this run.

## 2. Summarize the survivors

```bash
python3 .agents/skills/kotlin-mutation-testing/scripts/surviving_mutants.py
```

It prints the score, then each SURVIVED and NO_COVERAGE mutant as
`file:line mutator description [status]` with its `key`. Mutants already recorded in
[`config/pitest/equivalent-mutants.txt`](../../../config/pitest/equivalent-mutants.txt) are listed
as resolved.

**Done when:** you have the **Unresolved** list. The script exits 1 while it is non-empty and 0
when it is empty.

## 3. Resolve each unresolved mutant

Decide per mutant, in this order:

1. **Killable**: some input makes the mutated code observably different. Write a test that fails
   under the mutant, following the [`kotlin-testing`](../kotlin-testing/SKILL.md) skill: assert
   the exact value, exception or emission sequence the mutation changes.
   [`mutators.md`](mutators.md) maps each PIT mutator to the assertion that kills it. NO_COVERAGE
   means no test even reaches the line, so the new test must.
2. **Equivalent**: no test can tell the mutant from the original, because the changed value is
   discarded or the path can't be reached. Append `<key> | <reason>` to `equivalent-mutants.txt`.
   [`equivalent-mutants.md`](equivalent-mutants.md) lists the Kotlin and coroutine patterns and the
   proof a reason needs.

**Done when:** every unresolved mutant from step 2 has a new test or an equivalents entry with a
reason. "Couldn't kill it" is not a reason.

## 4. Re-run until resolved

Repeat steps 1–2 with a whole-module run.

**Done when:** the script exits 0 (every SURVIVED/NO_COVERAGE mutant is killed or recorded) and
the build passes the threshold. Report the score before and after, and which mutants you recorded
as equivalent. If the exact score (the script prints it) now clears the next multiple of 5 above
`mutationThreshold`, raise the threshold to it.
