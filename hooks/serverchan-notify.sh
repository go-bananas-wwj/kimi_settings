#!/bin/bash
# ServerChan (Server酱) notification hook for Kimi Code CLI
# 提取最后一轮生成的文本结果发送到微信

SENDKEY="${SERVERCHAN_SENDKEY:?Error: SERVERCHAN_SENDKEY not set}"
API_URL="https://sctapi.ftqq.com/${SENDKEY}.send"
LOG_FILE="$HOME/.kimi/hooks/serverchan-notify.log"

JSON_INPUT=$(cat)
export HOOK_JSON="$JSON_INPUT"

python3 - "$API_URL" "$LOG_FILE" <<'PYEOF'
import sys
import json
import os
import time
import urllib.request
import urllib.parse

api_url = sys.argv[1]
log_file = sys.argv[2]

def log(msg):
    try:
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")
    except Exception:
        pass

data = json.loads(os.environ.get("HOOK_JSON", "{}"))

event = data.get("hook_event_name", "Unknown")
session_id = data.get("session_id", "unknown")
cwd = data.get("cwd", "unknown")

log(f"Hook triggered: event={event}, session_id={session_id}, cwd={cwd}")

# Skip repeated stop hooks
if event == "Stop" and data.get("stop_hook_active"):
    log("Skipped: stop_hook_active is true")
    sys.exit(0)

if event not in ("Stop", "SessionEnd"):
    log(f"Skipped: event is {event}, not Stop/SessionEnd")
    sys.exit(0)

# Wait a moment for context.jsonl to be fully flushed to disk
time.sleep(2)

sessions_base = os.path.expanduser("~/.kimi/sessions")
log(f"sessions_base={sessions_base}, looking for turn_id={session_id}")

latest_turn_dir = None
latest_mtime = 0

# Hook's session_id is actually a TURN UUID, not the session directory name.
# We need to search recursively under ~/.kimi/sessions/ for a directory named session_id.
if os.path.isdir(sessions_base):
    for session_hash in os.listdir(sessions_base):
        session_path = os.path.join(sessions_base, session_hash)
        if not os.path.isdir(session_path):
            continue
        turn_path = os.path.join(session_path, session_id)
        ctx_path = os.path.join(turn_path, "context.jsonl")
        if os.path.isdir(turn_path) and os.path.exists(ctx_path):
            mtime = os.path.getmtime(ctx_path)
            if mtime > latest_mtime:
                latest_mtime = mtime
                latest_turn_dir = turn_path

# Fallback: if not found as turn_id, treat session_id as session_hash (old behavior)
if not latest_turn_dir:
    session_dir = os.path.join(sessions_base, session_id)
    if os.path.isdir(session_dir):
        for turn in os.listdir(session_dir):
            turn_path = os.path.join(session_dir, turn)
            ctx_path = os.path.join(turn_path, "context.jsonl")
            if os.path.isdir(turn_path) and os.path.exists(ctx_path):
                mtime = os.path.getmtime(ctx_path)
                if mtime > latest_mtime:
                    latest_mtime = mtime
                    latest_turn_dir = turn_path

log(f"latest_turn_dir={latest_turn_dir}")

# Try up to 3 times to read the result (with delays)
latest_assistant_text = ""
for attempt in range(3):
    if latest_turn_dir:
        ctx_path = os.path.join(latest_turn_dir, "context.jsonl")
        if os.path.exists(ctx_path):
            try:
                with open(ctx_path, "r", encoding="utf-8") as f:
                    lines = f.readlines()
                
                # Reverse search for text
                for line in reversed(lines):
                    line = line.strip()
                    if not line:
                        continue
                    obj = json.loads(line)
                    if obj.get("role") == "assistant":
                        content = obj.get("content", [])
                        text_parts = []
                        if isinstance(content, list):
                            for item in content:
                                if item.get("type") == "text":
                                    t = item.get("text", "")
                                    if t:
                                        text_parts.append(t)
                        elif isinstance(content, str) and content:
                            text_parts.append(content)
                        if text_parts:
                            latest_assistant_text = "\n".join(text_parts)
                            break
                
                # Fallback to think
                if not latest_assistant_text:
                    for line in reversed(lines):
                        line = line.strip()
                        if not line:
                            continue
                        obj = json.loads(line)
                        if obj.get("role") == "assistant":
                            content = obj.get("content", [])
                            if isinstance(content, list):
                                for item in content:
                                    if item.get("type") == "think":
                                        t = item.get("think", "")
                                        if t:
                                            latest_assistant_text = t
                                            break
                            if latest_assistant_text:
                                break
            except Exception as e:
                log(f"Read error on attempt {attempt+1}: {e}")
    
    if latest_assistant_text:
        break
    
    log(f"Attempt {attempt+1}: no text found, waiting...")
    time.sleep(1)

log(f"latest_assistant_text length={len(latest_assistant_text)}")

MAX_RESULT_LEN = 800
result_display = latest_assistant_text
if len(result_display) > MAX_RESULT_LEN:
    result_display = result_display[:MAX_RESULT_LEN] + "\n\n... (内容已截断)"

if not result_display:
    result_display = "（本轮无文本输出，可能是工具调用或空回复）"

notify_title = "✅ Kimi 任务完成"
desp = result_display

post_data = urllib.parse.urlencode({
    "title": notify_title,
    "desp": desp
}).encode("utf-8")

req = urllib.request.Request(api_url, data=post_data, method="POST")
try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = resp.read().decode("utf-8", errors="ignore")
        log(f"ServerChan response: {body}")
except Exception as e:
    log(f"ServerChan notify failed: {e}")

# --- SessionEnd: extract memory summary ---
if event == "SessionEnd":
    import datetime

    memory_dir = os.path.expanduser("~/.kimi/memories/sessions")
    os.makedirs(memory_dir, exist_ok=True)

    sessions_base = os.path.expanduser("~/.kimi/sessions")
    target_session_dir = None

    # Try session_id as session hash first
    candidate = os.path.join(sessions_base, session_id)
    if os.path.isdir(candidate):
        target_session_dir = candidate
    else:
        # Fallback: find most recently modified session
        latest_mtime = 0
        if os.path.isdir(sessions_base):
            for s in os.listdir(sessions_base):
                sp = os.path.join(sessions_base, s)
                if os.path.isdir(sp):
                    mtime = os.path.getmtime(sp)
                    if mtime > latest_mtime:
                        latest_mtime = mtime
                        target_session_dir = sp

    if not target_session_dir:
        log("No session directory found for summary")
        sys.exit(0)

    # Collect all turns in this session
    turns = []
    for turn in sorted(os.listdir(target_session_dir)):
        tp = os.path.join(target_session_dir, turn)
        ctx = os.path.join(tp, "context.jsonl")
        if os.path.isdir(tp) and os.path.exists(ctx):
            try:
                with open(ctx, "r", encoding="utf-8") as f:
                    lines = f.readlines()
                user_msgs = []
                assistant_msgs = []
                tool_calls = []
                for line in lines:
                    line = line.strip()
                    if not line:
                        continue
                    obj = json.loads(line)
                    role = obj.get("role", "")
                    if role == "user":
                        content = obj.get("content", "")
                        if isinstance(content, str) and content:
                            user_msgs.append(content[:200])
                    elif role == "assistant":
                        content = obj.get("content", [])
                        texts = []
                        if isinstance(content, list):
                            for item in content:
                                if item.get("type") == "text":
                                    t = item.get("text", "")
                                    if t:
                                        texts.append(t[:300])
                        elif isinstance(content, str) and content:
                            texts.append(content[:300])
                        if texts:
                            assistant_msgs.append(" ".join(texts))
                    if role == "assistant" and isinstance(content, list):
                        for item in content:
                            if item.get("type") == "tool_call":
                                tool_calls.append(item.get("tool_call", {}).get("name", "unknown"))
                turns.append({
                    "turn": turn,
                    "user": user_msgs,
                    "assistant": assistant_msgs,
                    "tools": tool_calls,
                })
            except Exception as e:
                log(f"Error reading turn {turn}: {e}")

    if not turns:
        log("No turns found in session")
        sys.exit(0)

    # Generate markdown summary
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    session_name = os.path.basename(target_session_dir)
    summary_path = os.path.join(memory_dir, f"{timestamp}_{session_name}.md")

    with open(summary_path, "w", encoding="utf-8") as f:
        f.write(f"# Session Summary: {session_name}\n")
        f.write(f"- Date: {datetime.datetime.now().isoformat()}\n")
        f.write(f"- CWD: {cwd}\n")
        f.write(f"- Turns: {len(turns)}\n")
        f.write(f"- Total tool calls: {sum(len(t['tools']) for t in turns)}\n\n")

        if any(t["tools"] for t in turns):
            all_tools = []
            for t in turns:
                all_tools.extend(t["tools"])
            from collections import Counter
            top_tools = Counter(all_tools).most_common(10)
            f.write("## Top Tools Used\n")
            for name, count in top_tools:
                f.write(f"- {name}: {count}\n")
            f.write("\n")

        f.write("## Conversation Log\n\n")
        for i, t in enumerate(turns, 1):
            f.write(f"### Turn {i} ({t['turn']})\n")
            if t["user"]:
                f.write(f"**User:** {t['user'][0]}\n\n")
            if t["assistant"]:
                f.write(f"**Assistant:** {t['assistant'][0][:500]}...\n\n")
            if t["tools"]:
                f.write(f"**Tools:** {', '.join(set(t['tools']))}\n\n")

    log(f"Session summary saved: {summary_path}")

sys.exit(0)
PYEOF
