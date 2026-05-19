#!/usr/bin/env bash
# SessionStart hook: inject path-gated reference docs into the conversation.
#
# Stdout from a SessionStart hook is fed to Claude as context (no JSON wrapper
# needed). The script gates on the session's project root — falling back to PWD
# when CLAUDE_PROJECT_DIR is unset — and emits one or more CLAUDE-*.md files
# from ~/.claude/ that apply to that tree.
#
# Add new gates by appending a `case` arm below.

set -u

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
home_real="$(readlink -f "$HOME")"
dir_real="$(readlink -f "$dir" 2>/dev/null || printf '%s' "$dir")"

emit() {
   local f="$HOME/.claude/$1"
   if [ -r "$f" ]; then
      printf '\n# Context loaded from %s\n\n' "$1"
      cat "$f"
   fi
}

case "$dir_real" in
   "$home_real/fortran"|"$home_real/fortran"/*)
      emit CLAUDE-fortran.md
      emit CLAUDE-gpu.md
      ;;
   "$home_real/python"|"$home_real/python"/*)
      : # nothing python-specific extracted yet
      ;;
esac

exit 0
