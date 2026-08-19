#!/usr/bin/env python3
"""Stop hook: refuse to end a turn whose final message breaks the hard STE rules.

Claude Code runs this script when the assistant stops. It reads the session
transcript, takes the text of the final assistant message, and checks the three
mechanical rules that need no judgment:

  1. No em dash or en dash (the local addition to ASD-STE100).
  2. No semicolon.
  3. No contraction.

A hit returns `decision: block` with the offending text, so the model rewrites
the reply before the turn ends. The soft rules (sentence length, passive voice,
banned words) go into the same message as a score only. Those need judgment and
would block too often.

Code, inline code, and blockquotes are exempt, so a quoted `;` or a pasted error
message never blocks a turn.
"""

import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

# Only read the tail of a long transcript. The final message is at the end.
TAIL_BYTES = 4 * 1024 * 1024

# `word'd`, `word're`, ... are always contractions. A bare `'s` is usually a
# possessive, which STE allows, so only these stems count as a contraction.
CONTRACTION = re.compile(r"\b\w+['’](?:t|re|ve|ll|d|m)\b", re.I)
CONTRACTION_S = re.compile(
    r"\b(?:it|that|there|here|what|who|let|he|she|one|where|how|why)['’]s\b", re.I
)
DASH = re.compile(r"[—–]")
BLOCKQUOTE = re.compile(r"^\s*>.*$", re.M)


def load_linter():
    """Import ste-lint.py as a module. The hyphen blocks a plain import."""
    # Keep a __pycache__ dir out of the skill directory when this script runs
    # from the repo checkout instead of the read-only store copy.
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location(
        "ste_lint", os.path.join(HERE, "ste-lint.py")
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def read_tail(path):
    size = os.path.getsize(path)
    with open(path, "rb") as fh:
        if size > TAIL_BYTES:
            fh.seek(size - TAIL_BYTES)
            fh.readline()  # drop the partial first line
        return fh.read().decode("utf-8", "replace")


def final_assistant_text(path):
    """Return the text of the last assistant message, tool calls excluded.

    Tool results arrive as `user` rows, so the first `user` row above the end of
    the transcript marks the start of the final message.
    """
    lines = [line for line in read_tail(path).split("\n") if line.strip()]
    chunks = []
    for line in reversed(lines):
        try:
            row = json.loads(line)
        except ValueError:
            continue
        if row.get("isSidechain"):
            continue  # subagent output, not my reply
        kind = row.get("type")
        if kind == "user":
            break
        if kind != "assistant":
            continue
        content = row.get("message", {}).get("content", [])
        if isinstance(content, str):
            chunks.append(content)
            continue
        texts = [
            block.get("text", "")
            for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        ]
        if texts:
            chunks.append("\n".join(texts))
    return "\n".join(reversed(chunks)).strip()


def sample(pattern, text, limit=3):
    """Return up to `limit` short quotes around each match, for the report."""
    out = []
    for match in pattern.finditer(text):
        start = max(0, match.start() - 30)
        end = min(len(text), match.end() + 30)
        out.append("..." + " ".join(text[start:end].split()) + "...")
        if len(out) == limit:
            break
    return out


def main():
    try:
        event = json.load(sys.stdin)
    except ValueError:
        return 0

    # Set on the stop that follows a block. Without this guard the hook can
    # block the same turn forever.
    if event.get("stop_hook_active"):
        return 0

    path = event.get("transcript_path") or ""
    if not path or not os.path.isfile(path):
        return 0

    text = final_assistant_text(path)
    if not text:
        return 0

    linter = load_linter()
    prose = BLOCKQUOTE.sub(" ", linter.strip_code(text))

    hits = []
    for label, pattern in (
        ("em dash / en dash", DASH),
        ("semicolon", re.compile(r";")),
        ("contraction", CONTRACTION),
        ("contraction", CONTRACTION_S),
    ):
        found = sample(pattern, prose)
        if found:
            hits.append((label, len(pattern.findall(prose)), found))

    if not hits:
        return 0

    report = linter.lint(text)
    lines = ["Your final message breaks the hard STE rules in ~/.claude/CLAUDE.md."]
    for label, count, found in hits:
        lines.append(f"- {label} x{count}: " + " | ".join(found))
    lines.append(
        f"Soft score: {report['total_per100w']} violations per 100 words, "
        f"longest sentence {report['longest_sentence_words']} words."
    )
    lines.append(
        "Rewrite the reply without these. Do not add an apology and do not "
        "explain the rewrite. Say the same thing in plain STE."
    )
    reason = "\n".join(lines)

    json.dump(
        {
            "decision": "block",
            "reason": reason,
            "systemMessage": "STE lint blocked the reply: "
            + ", ".join(f"{label} x{count}" for label, count, _ in hits),
        },
        sys.stdout,
    )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        # A broken hook must never break the session.
        sys.exit(0)
