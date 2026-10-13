#!/usr/bin/env bash
# context-memory-guard.sh — ask Claude to save its memory before the context
# window fills up, so a /compact never loses the session state.
#
# How it works
#   * statusline-command.sh writes the current context usage (percent of the
#     model's window) to $STATE_DIR/<session_id>.pct on every status update.
#   * This hook runs on UserPromptSubmit, PostToolUse and Stop. When usage is
#     at or above $CLAUDE_MEMORY_GUARD_PCT (default 60) and the reminder has not
#     fired in this cycle, it injects `additionalContext` telling the model to
#     save the session state to memory and then tell the user it is safe to
#     compact. PostToolUse catches long autonomous turns (auto-compact can fire
#     mid-turn); Stop and UserPromptSubmit catch turn boundaries.
#   * A per-session marker keeps it to one reminder per cycle. The marker is
#     cleared when usage drops back below the threshold (i.e. after /compact),
#     which re-arms the guard. No PostCompact hook is needed.
#
# Caveat: used_percentage is measured against the model's full context window.
# If CLAUDE_CODE_AUTO_COMPACT_WINDOW is set, the percentage no longer matches
# the point where auto-compact runs.
#
# Shared by every profile: ~/.claude-{cnr,iac,soma} symlink hooks/ and
# settings.json to ~/.claude, which is stowed from ~/dotfiles/claude/.claude.

input=$(cat)

CLAUDE_HOOK_INPUT="$input" python3 - <<'PY'
import json, os, sys

try:
    d = json.loads(os.environ.get("CLAUDE_HOOK_INPUT") or "{}")
except json.JSONDecodeError:
    sys.exit(0)

event = d.get("hook_event_name", "")
sid = d.get("session_id", "")
if not sid or event not in ("UserPromptSubmit", "PostToolUse", "Stop"):
    sys.exit(0)

# Never chain a second continuation off our own Stop reminder.
if event == "Stop" and d.get("stop_hook_active"):
    sys.exit(0)

state_dir = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or "/tmp", "claude-ctx")
pct_file = os.path.join(state_dir, sid + ".pct")
marker = os.path.join(state_dir, sid + ".fired")

try:
    threshold = float(os.environ.get("CLAUDE_MEMORY_GUARD_PCT", "60"))
except ValueError:
    threshold = 60.0

try:
    with open(pct_file) as f:
        pct = float(f.read().strip())
except (OSError, ValueError):
    sys.exit(0)  # no reading yet (early in the session, or right after /compact)

if pct < threshold:
    # Below threshold again (fresh session or after compaction): re-arm.
    try:
        os.remove(marker)
    except OSError:
        pass
    sys.exit(0)

if os.path.exists(marker):
    sys.exit(0)  # already reminded in this cycle

try:
    os.makedirs(state_dir, exist_ok=True)
    with open(marker, "w") as f:
        f.write(str(round(pct)))
except OSError:
    sys.exit(0)

msg = (
    f"[context-guard] The context window is at {round(pct)}% "
    f"(threshold {round(threshold)}%). Before doing anything else, save this "
    "session's state to your persistent memory, following your memory "
    "instructions: work completed, decisions taken and still open, the exact "
    "resume point and next steps, and any lessons learned. Update existing "
    "memory files rather than duplicating them. Then tell the user that "
    "memory is saved and it is safe to run /compact. Do this once; do not "
    "repeat it unless reminded again."
)
print(json.dumps({"hookSpecificOutput": {"hookEventName": event,
                                         "additionalContext": msg}}))
PY
exit 0
