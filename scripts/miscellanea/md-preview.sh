#!/bin/bash

# preview all md files into the current directory

declare -a pids
declare -a files

function ctrl_c() {
  for pid in "${pids[@]}"; do
    echo $pid
    kill -9 $pid
  done

  for file in "${files[@]}"; do
    rm -f $file.html
  done

  exit 0
}

chromium &

for file in $( ls *.md ); do
  github-markdown-preview $file &
  lastpid=$!
  pids+=($lastpid)
  bname=$(basename $file)
  files+=($bname)
  chromium $file.html &
done

trap ctrl_c INT

while true; do read x; done

exit 0
