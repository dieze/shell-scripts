#!/usr/bin/env bash

#
# $1: file name to print
#
print_single() {
  [ "${1: -4}" = "Test" ] &&
    printf '%s,%s\n' "-" "$1" ||
    printf '%s,%s\n' "$1" "-"
}

column -t -s ',' <(
  last_file=
  counter=0
  found=false

  for file in $(
    git log -1 --name-status --pretty= | \
      grep -E '\.java$' | \
      awk -F" " '{print $2}' | \
      awk -F"/" '{print $NF}' | \
      sed 's/\.java$//' | \
      sort
  ); do
    ((counter++))

    # first loop
    [ -z "$last_file" ] && {
      last_file="$file"
      continue
    }

    # previous loop found Class/ClassTest pair
    # we must ignore the current last_file
    if $found; then
      found=false
      last_file=
      continue
    fi

    regexp="^${last_file}Test$"

    if [[ $file =~ $regexp ]]; then
      printf '%s,%s\n' "$last_file" "$file"
      found=true
    else
      print_single "$last_file"
    fi

    last_file="$file"
  done

  # handles single file ; there was only 1 iteration
  ((counter == 0)) && { print_single "$last_file"; exit 0; }

  # handles last file ; there was n iterations (n being odd number)
  ((counter % 2 == 1)) && { print_single "$file"; exit 0; }

  # handles last file when found=false ; there was n iterations (n being even number)
  if ! $found; then print_single "$file"; fi
)
