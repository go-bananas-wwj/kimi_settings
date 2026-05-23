#!/usr/bin/env python3
"""ServerChan (Server酱) notification hook for Kimi Code CLI.

Reads assistant message content from session context files and sends
a notification to WeChat via ServerChan.
"""

import json
import os
import sys
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SENDKEY = os.environ.get("SERVERCHAN_SENDKEY", "")
if not SENDKEY:
    raise RuntimeError("SERVERCHAN_SENDKEY environment variable is not set")
API_URL = f"https://sctapi.ftqq.com/{SENDKEY}.send"
MAX_RESULT_LEN = 800
LOG_FILE = Path("~/.kimi/hooks/serverchan-notify.log").expanduser()

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
def _log(msg: str) -> None:
    """Append a timestamped line to the debug log."""
    try:
        timestamp = datetime.now().isoformat()
        with LOG_FILE.open("a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {msg}\n")
    except Exception:
        pass

# ---------------------------------------------------------------------------
# Content extraction
# ---------------------------------------------------------------------------
def extract_assistant_text(ctx_path: Path) -> str:
    """Extract the latest assistant text/think content from a context.jsonl."""
    if not ctx_path.exists():
        return ""

    try:
        with ctx_path.open("r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception as exc:
        _log(f"Failed to read {ctx_path}: {exc}")
        return ""

    latest_text = ""
    latest_think = ""

    # Search from the end (most recent) to the beginning
    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError as exc:
            _log(f"JSON decode error in {ctx_path}: {exc}")
            continue

        if obj.get("role") != "assistant":
            continue

        content = obj.get("content", [])

        # Case 1: content is a string (legacy format)
        if isinstance(content, str):
            if content:
                latest_text = content
                break
            continue

        # Case 2: content is a list (modern format)
        if not isinstance(content, list):
            continue

        # Try to find text parts first
        text_parts = []
        think_parts = []
        for item in content:
            if not isinstance(item, dict):
                continue
            item_type = item.get("type")
            if item_type == "text":
                # Handle null text gracefully
                t = item.get("text") or ""
                if t:
                    text_parts.append(t)
            elif item_type == "think":
                t = item.get("think") or ""
                if t:
                    think_parts.append(t)

        if text_parts:
            latest_text = "\n".join(text_parts)
            break
        if think_parts and not latest_think:
            # Remember the first think we see, but keep searching for text
            latest_think = "\n".join(think_parts)

    # If no text found anywhere, fallback to think
    if not latest_text and latest_think:
        latest_text = latest_think

    return latest_text

# ---------------------------------------------------------------------------
# Notification
# ---------------------------------------------------------------------------
def send_notification(title: str, desp: str) -> None:
    """Send a notification via ServerChan."""
    post_data = urllib.parse.urlencode({
        "title": title,
        "desp": desp,
    }).encode("utf-8")

    req = urllib.request.Request(API_URL, data=post_data, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            body = resp.read().decode("utf-8", errors="ignore")
            try:
                resp_json = json.loads(body)
                if resp_json.get("code") != 0 and resp_json.get("data", {}).get("error") != "SUCCESS":
                    _log(f"ServerChan API error: {body}")
            except Exception:
                if "SUCCESS" not in body:
                    _log(f"ServerChan unexpected response: {body}")
    except Exception as exc:
        _log(f"ServerChan notify failed: {exc}")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> int:
    # Read hook JSON from stdin (as provided by kimi-cli hook runner)
    try:
        raw_input = sys.stdin.read()
        data = json.loads(raw_input) if raw_input.strip() else {}
    except json.JSONDecodeError as exc:
        _log(f"Failed to parse hook JSON: {exc}")
        return 1

    event = data.get("hook_event_name", "Unknown")
    session_id = data.get("session_id", "unknown")
    cwd = data.get("cwd", "unknown")

    _log(f"--- Hook triggered: event={event}, session_id={session_id}, cwd={cwd} ---")

    # Skip repeated stop hooks to avoid duplicate notifications
    if event == "Stop" and data.get("stop_hook_active"):
        _log("Skipping: stop_hook_active is true")
        return 0

    # We handle both Stop and SessionEnd events
    if event == "Stop":
        notify_title = "✅ Kimi 任务完成"
    elif event == "SessionEnd":
        notify_title = "🔚 Kimi 会话结束"
    else:
        _log(f"Ignoring unsupported event: {event}")
        return 0

    # Locate the session directory
    session_dir = Path(f"~/.kimi/sessions/{session_id}").expanduser()
    _log(f"Session dir: {session_dir}, exists={session_dir.is_dir()}")

    if not session_dir.is_dir():
        _log("Session directory does not exist, aborting")
        return 0

    # Gather all turns and sort by mtime (newest first)
    turns = []
    for turn_entry in session_dir.iterdir():
        turn_path = turn_entry
        ctx_path = turn_path / "context.jsonl"
        if turn_path.is_dir() and ctx_path.exists():
            try:
                mtime = ctx_path.stat().st_mtime
                turns.append((mtime, turn_path, ctx_path))
            except OSError as exc:
                _log(f"Failed to stat {ctx_path}: {exc}")

    turns.sort(key=lambda x: x[0], reverse=True)
    _log(f"Found {len(turns)} turns")
    for mtime, turn_path, _ in turns[:5]:
        _log(f"  turn={turn_path.name}, mtime={mtime}")

    # Try each turn from newest to oldest until we find content
    latest_assistant_text = ""
    chosen_turn = None
    for mtime, turn_path, ctx_path in turns:
        text = extract_assistant_text(ctx_path)
        _log(f"  Extracted from {turn_path.name}: len={len(text)}")
        if text:
            latest_assistant_text = text
            chosen_turn = turn_path.name
            break

    _log(f"Chosen turn: {chosen_turn}, content_len={len(latest_assistant_text)}")

    # Truncate for notification
    result_display = latest_assistant_text
    if len(result_display) > MAX_RESULT_LEN:
        result_display = result_display[:MAX_RESULT_LEN] + "\n\n... (内容已截断)"

    if not result_display:
        result_display = "（本轮无文本输出，可能是工具调用或空回复）"
        _log("Fallback: no text content found in any turn")

    # Send notification
    send_notification(notify_title, result_display)
    _log(f"Notification sent: title={notify_title}, desp_len={len(result_display)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
