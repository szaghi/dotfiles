#!/bin/bash
# Archive all "entities" (files and directories) of the current directory into its own archive.
# Optionally, remove archived entities.
# Optionally, compress all archives by means of "pbzip2".

# default options
delete=0
pbzip2=0

function print_usage {
  # Print correct usage
  echo
  echo "`basename $0`"
  echo "archive all entities (files and directories) into the current directory"
  echo "Usage: `basename $0` [--delete][--pbzip2]"
  echo "Options:"
  echo "  --delete # => delete archived entities"
  echo "  --pbzip2 # => compress archives by means of pbzip2"
}

#parsing command line
while [ $# -gt 0 ]; do
  case "$1" in
    "--delete")
      delete=1
      ;;
    "--pbzip2")
      pbzip2=1
      ;;
    *)
      echo; echo "Unknown switch $1"; print_usage; exit 1
      ;;
  esac
  shift
done

IFS=$(echo -en "\n\b")
for entity in $( ls | grep -v archive*.log  | grep -v *.tar* ); do
  echo Archive "$entity"
  tar cvf "$entity".tar "$entity" > archive.$$.log
  if [ $? -eq 0 ]; then
    if [ $delete -eq 1 ] ; then
      echo "Remove ""$entity"
      rm -rf "$entity"
    fi
    if [ $pbzip2 -eq 1 ] ; then
      echo "pbzip2 ""$entity"
      pbzip2 "$entity".tar
    fi
  else
    echo "Archive ""$entity"" failed! see archive.$$.log"
  fi
done
