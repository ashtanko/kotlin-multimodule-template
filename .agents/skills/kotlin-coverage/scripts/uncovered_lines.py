#!/usr/bin/env python3
"""List uncovered and partly covered lines per source file from each module's Kover XML report.

Usage (from anywhere in the repo, after `./gradlew koverXmlReport`):
    python3 .agents/skills/kotlin-coverage/scripts/uncovered_lines.py [module ...]

Reads <module>/build/reports/kover/report.xml (JaCoCo XML format) for every module, or only the
modules named. Prints, per file: `missed` lines (no instruction ran) and `partial` lines (ran, but
some branches never did). Exit code: 0 on success, 2 when no report exists yet.
Part of the kotlin-coverage skill (.agents/skills/kotlin-coverage/SKILL.md).
"""
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
REPORT = Path("build/reports/kover/report.xml")


def ranges(numbers):
    """[1, 2, 3, 7] -> '1-3, 7'"""
    out, start, prev = [], None, None
    for n in sorted(numbers):
        if start is None:
            start = prev = n
        elif n == prev + 1:
            prev = n
        else:
            out.append(f"{start}-{prev}" if prev != start else f"{start}")
            start = prev = n
    if start is not None:
        out.append(f"{start}-{prev}" if prev != start else f"{start}")
    return ", ".join(out)


def source_path(module_dir, package, file_name):
    candidate = module_dir / "src" / "main" / "kotlin" / package / file_name
    return candidate.relative_to(ROOT) if candidate.exists() else Path(module_dir.name) / package / file_name


def newest_source_mtime(module_dir):
    sources = list((module_dir / "src" / "main").rglob("*.kt")) + list((module_dir / "src" / "test").rglob("*.kt"))
    return max((p.stat().st_mtime for p in sources), default=0)


def report_module(module_dir):
    report = module_dir / REPORT
    root = ET.parse(report).getroot()
    lines = {c.get("type"): c for c in root.findall("counter")}.get("LINE")
    missed_total = int(lines.get("missed")) if lines is not None else 0
    covered_total = int(lines.get("covered")) if lines is not None else 0
    total = missed_total + covered_total
    percent = f"{100.0 * covered_total / total:.1f}%" if total else "n/a"
    print(f"{module_dir.name}: line coverage {percent} ({covered_total}/{total} lines) — {report.relative_to(ROOT)}")
    if report.stat().st_mtime < newest_source_mtime(module_dir):
        print("  warning: report is older than the module's sources; re-run ./gradlew koverXmlReport")

    found = False
    for package in root.iter("package"):
        for source in package.iter("sourcefile"):
            missed, partial = [], []
            for line in source.iter("line"):
                nr, mi, ci = int(line.get("nr")), int(line.get("mi")), int(line.get("ci"))
                mb, cb = int(line.get("mb")), int(line.get("cb"))
                if mi > 0 and ci == 0:
                    missed.append(nr)
                elif mb > 0:
                    partial.append((nr, mb, mb + cb))
            if not missed and not partial:
                continue
            found = True
            print(f"  {source_path(module_dir, package.get('name'), source.get('name'))}")
            if missed:
                print(f"    missed:  {ranges(missed)}")
            if partial:
                detail = ", ".join(f"{nr} ({mb}/{total_branches} branches missed)" for nr, mb, total_branches in partial)
                print(f"    partial: {detail}")
    if not found:
        print("  no uncovered lines")


def main(argv):
    wanted = set(argv)
    modules = sorted(p.parents[3] for p in ROOT.glob(f"*/{REPORT}"))
    if wanted:
        modules = [m for m in modules if m.name in wanted]
    if not modules:
        which = ", ".join(sorted(wanted)) or "any module"
        print(f"No Kover XML report for {which}. Run ./gradlew koverXmlReport first.", file=sys.stderr)
        return 2
    for module_dir in modules:
        report_module(module_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
