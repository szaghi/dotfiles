#!/usr/bin/env bash
# check.sh TASKDIR — run inside the repository under test. Passes when the task's hidden tests pass and the
# task's protected files are neither modified nor deleted against the base commit ($BENCH_BASE, default HEAD~1: in delegate's
# check checkout HEAD is the patch commit and its parent is the starting tree).
set -u
task=$1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
tar -xzf "$task/hidden.tar.gz" -C "$tmp"
status=0
PYTHONPATH="$PWD" PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s "$tmp" -t "$tmp" -p 'test_*.py' || status=1
mapfile -t protect <"$task/protect"
# Modified or deleted only: adding a test file next to the protected ones is allowed.
if ! git diff --quiet --diff-filter=MD "${BENCH_BASE:-HEAD~1}" -- "${protect[@]}"; then
  echo "protected paths modified or deleted: ${protect[*]}"
  status=1
fi
exit "$status"
