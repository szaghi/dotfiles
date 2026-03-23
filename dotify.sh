#!/usr/bin/env bash
set -euo pipefail

DOT="$(cd "$(dirname "$0")" && pwd)"
PACKAGES=(bash vim git claude modules python scripts miscellanea)

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
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)    STOW_FLAGS+=(-n); shift ;;
    -D|--uninstall)  STOW_FLAGS+=(-D); shift ;;
    -v|--verbose)    STOW_FLAGS+=(-v); shift ;;
    -h|--help)       usage; exit 0 ;;
    -*)              echo "Unknown option: $1"; usage; exit 1 ;;
    *)               PACKAGES=("$@"); break ;;
  esac
done

if ! command -v stow &>/dev/null; then
  echo "ERROR: GNU Stow not found. Install with: sudo apt install stow"
  exit 1
fi

for pkg in "${PACKAGES[@]}"; do
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
