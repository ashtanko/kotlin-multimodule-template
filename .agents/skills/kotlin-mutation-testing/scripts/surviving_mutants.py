#!/usr/bin/env python3
"""Summarize a PIT report: the score, then every SURVIVED and NO_COVERAGE mutant.

Usage (from anywhere in the repo, after `./gradlew :core:pitest`):
    python3 .agents/skills/kotlin-mutation-testing/scripts/surviving_mutants.py [--module core]

Prints each mutant as `file:line mutator description`, plus the `key` used to record it as
equivalent in config/pitest/equivalent-mutants.txt. Mutants whose key is recorded there are listed
as resolved. Exit code: 0 when every SURVIVED/NO_COVERAGE mutant is recorded as equivalent,
1 while any is unresolved, 2 when there is no report.
Part of the kotlin-mutation-testing skill (.agents/skills/kotlin-mutation-testing/SKILL.md).
"""
import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
EQUIVALENTS = ROOT / "config" / "pitest" / "equivalent-mutants.txt"
UNRESOLVED = ("SURVIVED", "NO_COVERAGE")


def load_equivalents():
    """key -> reason, from `<key> | <reason>` lines."""
    recorded = {}
    if EQUIVALENTS.exists():
        for raw in EQUIVALENTS.read_text().splitlines():
            line = raw.strip()
            if line and not line.startswith("#"):
                key, _, reason = line.partition(" | ")
                recorded[key.strip()] = reason.strip()
    return recorded


def location(module_dir, mutated_class, source_file, line):
    """Repo path for project sources; otherwise say what generated the code."""
    package, simple_name = mutated_class.rsplit(".", 1)
    candidate = module_dir / "src" / "main" / "kotlin" / package.replace(".", "/") / source_file
    if candidate.exists():
        return f"{candidate.relative_to(ROOT)}:{line}"
    if source_file == "unknown_source":
        return f"(no line: Kotlin-generated {simple_name})"
    return f"{source_file}:{line} (library code inlined into {simple_name})"


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--module", default="core", help="Gradle module that ran pitest (default: core)")
    args = parser.parse_args()

    module_dir = ROOT / args.module
    report = module_dir / "build" / "reports" / "pitest" / "mutations.xml"
    if not report.exists():
        print(f"No PIT report at {report.relative_to(ROOT)}. Run ./gradlew :{args.module}:pitest first.", file=sys.stderr)
        return 2

    mutants = list(ET.parse(report).getroot())
    total = len(mutants)
    detected = sum(m.get("detected") == "true" for m in mutants)
    no_coverage = sum(m.get("status") == "NO_COVERAGE" for m in mutants)
    covered = total - no_coverage
    # Rounded like PIT's own report, which is also what `mutationThreshold` is compared against.
    score = f"{round(100 * detected / total)}%" if total else "n/a"
    strength = f"{round(100 * detected / covered)}%" if covered else "n/a"
    print(f"PIT :{args.module}: {total} mutants, {detected} detected — mutation score {score}, "
          f"test strength {strength} ({detected}/{covered} covered) — {report.relative_to(ROOT)}")

    recorded = load_equivalents()
    unresolved, equivalent, seen = [], [], set()
    for m in mutants:
        if m.get("status") not in UNRESOLVED:
            continue
        cls, method = m.findtext("mutatedClass"), m.findtext("mutatedMethod")
        mutator = m.findtext("mutator").rsplit(".", 1)[-1]
        source_file, line = m.findtext("sourceFile"), m.findtext("lineNumber")
        key = f"{cls}#{method} {mutator} {source_file}:{line}"
        text = f"{location(module_dir, cls, source_file, line)} {mutator} {m.findtext('description')} [{m.get('status')}]"
        if key in recorded:
            seen.add(key)
            equivalent.append((text, recorded[key]))
        else:
            unresolved.append((text, key))

    print(f"\nUnresolved ({len(unresolved)}): kill each with a test, or record it as equivalent")
    for text, key in unresolved:
        print(f"  {text}\n      key: {key}")
    print(f"\nRecorded as equivalent ({len(equivalent)}) in {EQUIVALENTS.relative_to(ROOT)}")
    for text, reason in equivalent:
        print(f"  {text}\n      why: {reason}")
    stale = sorted(set(recorded) - seen)
    if stale:
        print(f"\nRecorded but not in this report ({len(stale)}): stale (remove them) unless this was a narrowed run")
        for key in stale:
            print(f"  {key}")
    return 1 if unresolved else 0


if __name__ == "__main__":
    sys.exit(main())
