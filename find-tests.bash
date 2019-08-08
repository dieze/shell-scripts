#!/bin/bash

column -t -s ',' <(
  last_file=;
  found=false;

  for file in $(
    git log -1 --name-status --pretty= | \
      grep -E '\.java$' | \
      awk -F" " '{print $2}' | \
      awk -F"/" '{print $NF}' | \
      sed 's/\.java$//' | \
      sort
  ); do
    # first loop
    if [ -z "$last_file" ]; then
      last_file="$file";
      continue;
    fi;

    # previous loop found Class/ClassTest pair
    # we must ignore the current last_file
    if $found; then
      found=false;
      last_file=;
      continue;
    fi;

    regexp="^${last_file}Test$";

    if [[ $file =~ $regexp ]]; then
      printf "$last_file,$file\n";
      found=true;
    else
      printf "$last_file\n";
    fi;

    last_file="$file";
  done;
);
