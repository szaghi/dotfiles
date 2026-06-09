#!/usr/bin/env bash
# export-public-skills.sh
#
# Local, one-way export of the PUBLIC (allowlisted) HPC reference skills from
# this dotfiles repo (the source of truth) into the claude-skills-hpc public
# repository working tree.
#
#   dotfiles/claude/.claude/skills/<name>  -->  <REPO>/skills/<name>
#
# It does NOT git add, commit, or push anything. It only copies files so you
# can review and publish the repo manually. Re-running overwrites the exported
# copies (idempotent).
#
# Only skills in the ALLOWLIST below are ever exported. Anything not listed
# (e.g. private GPU-book skills) can never leak out through this script.

set -euo pipefail

DOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$DOT/claude/.claude/skills"
REPO="${CLAUDE_SKILLS_HPC_REPO:-$HOME/claude/claude-skills-hpc}"
DEST="$REPO/skills"

# --- ALLOWLIST: the only skills permitted to be exported -------------------
ALLOWLIST=(
  mpi-5.0
  openmp-6.0
  openacc-3.4
  fortran-2023-standard
  cuda-programming
  iso-c-9899-2024
)
# ---------------------------------------------------------------------------

DRY=0
[[ "${1:-}" == "-n" || "${1:-}" == "--dry-run" ]] && DRY=1

if [[ ! -d "$REPO" ]]; then
  echo "ERROR: target repo not found: $REPO" >&2
  echo "       create it first (mkdir -p \"$REPO/skills\") or set CLAUDE_SKILLS_HPC_REPO." >&2
  exit 1
fi

mkdir -p "$DEST"
echo "Exporting public skills:"
echo "  source: $SRC"
echo "  target: $DEST"
[[ $DRY -eq 1 ]] && echo "  (dry-run — no files written)"
echo

for skill in "${ALLOWLIST[@]}"; do
  s="$SRC/$skill"
  if [[ ! -f "$s/SKILL.md" ]]; then
    echo "  SKIP  $skill (not found in dotfiles source)" >&2
    continue
  fi
  if [[ $DRY -eq 1 ]]; then
    echo "  would export  $skill"
    continue
  fi
  # Resolve symlinks at source; replace the destination copy wholesale so
  # deletions in the source propagate. Exclude VCS cruft.
  rm -rf "${DEST:?}/$skill"
  cp -RL "$s" "$DEST/$skill"
  # Belt-and-braces: never carry a nested .git or editor backups into the repo.
  find "$DEST/$skill" -name '.git' -prune -exec rm -rf {} + 2>/dev/null || true
  echo "  exported  $skill"
done

echo
echo "Done. Review the changes in: $REPO"
echo "Then publish manually (the script does not git add/commit/push)."
