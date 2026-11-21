#!/usr/bin/env python3
"""Rewrite the facts the docs repeat from their single sources.

    python3 scripts/docs-sync.py           rewrite the docs in place
    python3 scripts/docs-sync.py --check   exit 1 and name each stale doc

Sources and what they feed:

- tests/*-test.sh (minus base-test.sh): the suite count in README.md,
  docs/STRUCTURE.md and docs/MAINTENANCE.md, and MAINTENANCE's Testing list
  between <!-- SUITES_START --> and <!-- SUITES_END -->, one bullet per
  suite from its "# doc: <Name> — <description>" line.
- The flag table in bin/dotfiles-toggle's header ("#   <flag>  <what it
  switches>"): the same script's summary line and KNOWN_FLAGS, the flag
  lists in QUICK_REFERENCE.md, docs/MAINTENANCE.md and the skill's command
  table, and the skill's toggle list between <!-- TOGGLES_START --> and
  <!-- TOGGLES_END -->.

tests/docs-test.sh runs --check, so a new suite or toggle only needs its
own line plus one run of this script. Standard library only.
"""

import os
import re
import sys
from pathlib import Path

# DOCS_SYNC_ROOT lets tests point it at a copy of the repo.
ROOT = Path(os.environ.get("DOCS_SYNC_ROOT") or Path(__file__).resolve().parent.parent)


def suites():
    out = []
    for p in sorted((ROOT / "tests").glob("*-test.sh")):
        if p.name == "base-test.sh":
            continue
        area = p.name[: -len("-test.sh")]
        m = re.search(r"^# doc: (.+?) — (.+)$", p.read_text(), re.M)
        if not m:
            sys.exit(f"{p.relative_to(ROOT)}: no '# doc: <Name> — <description>' line")
        out.append((area, m.group(1), m.group(2)))
    return out


def toggles():
    text = (ROOT / "bin/dotfiles-toggle").read_text()
    block = text.split("--enabled <flag>`:\n#\n", 1)[1].split("\n#\n", 1)[0]
    rows = []
    for line in block.splitlines():
        m = re.match(r"^#   ([a-z0-9-]+)\s+(.+)$", line)
        if not m:
            sys.exit(f"bin/dotfiles-toggle: unreadable flag row: {line!r}")
        rows.append((m.group(1), m.group(2)))
    return rows


def between(text, start, end, body):
    pattern = re.compile(re.escape(start) + r"\n.*?" + re.escape(end), re.S)
    if not pattern.search(text):
        sys.exit(f"markers {start} / {end} not found")
    return pattern.sub(lambda _: f"{start}\n{body}{end}", text, count=1)


def sub_once(text, pattern, repl, what):
    new, n = re.subn(pattern, repl, text, count=1, flags=re.M)
    if n != 1:
        sys.exit(f"{what}: pattern not found")
    return new


def render():
    s = suites()
    t = toggles()
    n = len(s)
    flags = [f for f, _ in t]
    files = {}

    def edit(rel, fn):
        path = ROOT / rel
        old = files.get(rel, path.read_text())
        files[rel] = fn(old)

    edit("README.md", lambda x: sub_once(x, r"\b\d+ CI suites\b", f"{n} CI suites", "README suite count"))
    edit("docs/STRUCTURE.md", lambda x: sub_once(x, r"# \d+ suites, one per area", f"# {n} suites, one per area", "STRUCTURE suite count"))
    edit("docs/MAINTENANCE.md", lambda x: sub_once(x, r"runs \d+ test suites", f"runs {n} test suites", "MAINTENANCE suite count"))
    bullets = "".join(f"- **{name}** (`{area}`) — {desc}\n" for area, name, desc in s)
    edit("docs/MAINTENANCE.md", lambda x: between(x, "<!-- SUITES_START -->", "<!-- SUITES_END -->", bullets))

    edit("bin/dotfiles-toggle", lambda x: sub_once(
        x, r"^(# dotfiles:summary=Turn a feature on or off with a flag file )\(.*\)$",
        lambda m: m.group(1) + "(" + ", ".join(flags) + ")", "toggle summary"))
    edit("bin/dotfiles-toggle", lambda x: sub_once(
        x, r"^KNOWN_FLAGS=\(.*\)$", "KNOWN_FLAGS=(" + " ".join(flags) + ")", "KNOWN_FLAGS"))
    edit("QUICK_REFERENCE.md", lambda x: sub_once(
        x, r"^(dotfiles toggle <f>\s+# Flip ).*$", lambda m: m.group(1) + " / ".join(flags), "QUICK_REFERENCE toggles"))
    edit("docs/MAINTENANCE.md", lambda x: sub_once(
        x, r"^(dotfiles toggle <f>\s+# Flip a feature flag: ).*( \(--list\))$",
        lambda m: m.group(1) + ", ".join(flags) + m.group(2), "MAINTENANCE toggles"))
    skill = "agents/skills/dotfiles/commands.md"
    edit(skill, lambda x: sub_once(
        x, r"^(\| `dotfiles toggle <flag> \[on\\\|off\]` \| flip ).*?( \(or any name\) \|)",
        lambda m: m.group(1) + ", ".join(f"`{f}`" for f in flags) + m.group(2), "skill toggle row"))
    edit(skill, lambda x: between(x, "<!-- TOGGLES_START -->", "<!-- TOGGLES_END -->",
                                  "".join(f"- `{f}` — {d}\n" for f, d in t)))
    return files


def main():
    check = "--check" in sys.argv[1:]
    stale = []
    for rel, new in render().items():
        path = ROOT / rel
        if path.read_text() != new:
            stale.append(rel)
            if not check:
                path.write_text(new)
    if check:
        if stale:
            print("Out of date (run: python3 scripts/docs-sync.py): " + ", ".join(stale))
            sys.exit(1)
        print("docs in sync")
    else:
        print("updated: " + (", ".join(stale) if stale else "nothing"))


if __name__ == "__main__":
    main()
