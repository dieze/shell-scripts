#!/bin/bash

command=(git -c color.ui=always $@);

for file in *; do
  if [ -d "$file" ] && [ -d "$file/.git" ]; then
    (
      cd "$file";

      result="$(${command[@]})";

      if [ -n "$result" ]; then
        printf "\n$file\n";
        printf "$result\n";
      fi;
    );
  fi;
done;
