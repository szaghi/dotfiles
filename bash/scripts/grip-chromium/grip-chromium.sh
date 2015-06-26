# wrapper for grip, running chromium as app on the rendered markdown file

function grip-chromium {
  if [ $# -eq 0 ] ; then
    grip --gfm 1123 >/dev/null 2>&1 &
    gripid=$!
  else
    grip --gfm $1 1123 >/dev/null 2>&1 &
    gripid=$!
  fi
  echo Press CTRL+C to quit
  chromium http://localhost:1123 >/dev/null 2>&1 &
  trap "kill -9 $gripid" SIGINT
}
