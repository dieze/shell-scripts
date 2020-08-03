#!/usr/bin/env bash

command=(git -c color.ui=always $@)

for file in *; do
  if [ -d "$file" ] && [ -d "$file/.git" ]; then
    (
      cd "$file"

      result="$(${command[@]})"

      if [ -n "$result" ]; then
        printf '\n%s\n' "$file"
        printf '%s\n' "$result"
      fi
    )
  fi
done
