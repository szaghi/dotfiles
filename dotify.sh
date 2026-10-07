#!/usr/bin/env bash
set -euo pipefail

DOT="$(cd "$(dirname "$0")" && pwd)"
PACKAGES=(bash vim nvim git claude modules python scripts miscellanea ssh)

usage() {
  echo "Usage: $(basename "$0") [OPTIONS] [packages...]"
  echo ""
  echo "Options:"
  echo "  -n, --dry-run    Show what would be done, make no changes"
  echo "  -D, --uninstall  Remove managed symlinks"
  echo "  -v, --verbose    Print every action"
  echo "  -h, --help       Show this help"
  echo ""
  echo "Default packages: ${PACKAGES[*]}"
  echo "Machine-specific packages are loaded from machines/<hostname> if present."
}

STOW_FLAGS=(--dir="$DOT" --target="$HOME")
DRY_RUN=0
UNINSTALL=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)    STOW_FLAGS+=(-n); DRY_RUN=1; shift ;;
    -D|--uninstall)  STOW_FLAGS+=(-D); UNINSTALL=1; shift ;;
    -v|--verbose)    STOW_FLAGS+=(-v); shift ;;
    -h|--help)       usage; exit 0 ;;
    -*)              echo "Unknown option: $1"; usage; exit 1 ;;
    *)               PACKAGES=("$@"); break ;;
  esac
done

if ! command -v stow &>/dev/null; then
  echo "ERROR: GNU Stow not found. Install with: pacman -S stow (Arch) or apt install stow (Debian/Ubuntu)"
  exit 1
fi

# Claude Code rewrites settings.json (e.g. on /model or plugin toggles) by
# replacing the file, which turns the stow symlink into a plain file and makes
# stow abort with "existing target is neither a link nor a directory".
# Identical content carries no state, so it is safe to drop and re-link.
# Differing content is live state the dotfile lacks: show it and stop. Never
# overwrite the dotfile here; it may hold uncommitted edits of its own.
check_drift() {
  local rel="$1" pkg="$2"
  local live="$HOME/$rel" tracked="$DOT/$pkg/$rel"
  [[ -f "$live" && ! -L "$live" && -f "$tracked" ]] || return 0
  # -L only tests the last component: if stow folded a parent directory
  # (~/.claude -> repo, on a host with no prior ~/.claude), $live IS the
  # tracked file and removing it would delete it from the repo.
  [[ "$(realpath "$live")" == "$DOT"/* ]] && return 0
  if cmp -s "$live" "$tracked"; then
    echo "  drift: ~/$rel is a plain file identical to the dotfile; re-linking"
    (( DRY_RUN )) || rm "$live"
    return 0
  fi
  echo "ERROR: ~/$rel is a plain file that differs from $pkg/$rel:"
  diff -u "$tracked" "$live" || true
  echo ""
  echo "The dotfile is the source of truth. Keep the live changes with:"
  echo "  cp ~/$rel $tracked && rm ~/$rel && bash $DOT/dotify.sh $pkg"
  echo "or discard them with:"
  echo "  rm ~/$rel && bash $DOT/dotify.sh $pkg"
  exit 1
}

for pkg in "${PACKAGES[@]}"; do
  if [[ "$pkg" == claude ]] && (( ! UNINSTALL )); then
    check_drift .claude/settings.json claude
  fi
  echo "  stowing $pkg..."
  stow "${STOW_FLAGS[@]}" "$pkg"
done

# Machine-specific packages
MACHINE="$(hostname -s)"
if [[ -f "$DOT/machines/$MACHINE" ]]; then
  echo "  loading machine profile: $MACHINE"
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    echo "  stowing $pkg (machine: $MACHINE)..."
    stow "${STOW_FLAGS[@]}" "$pkg"
  done < "$DOT/machines/$MACHINE"
fi

echo "Done."
