#!/bin/bash

submodules=`git config --file .gitmodules --name-only --get-regexp path | sed 's/submodule.//' | sed 's/.path//'`
submodules=($(echo $submodules | tr " " "\n"))

echo "purge submodules directories"
for s in "${submodules[@]}" ; do
   rm -rf "$s"
done

echo "init submodules directories"
git submodule update --init --remote

for s in "${submodules[@]}" ; do
   echo updating master branch of "$s"
   cd "$s"
   git checkout master
   git pull
   cd -
done
