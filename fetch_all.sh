#!/bin/bash

for project in *; do
  if [ -d "$project" ]; then
    (
      cd "$project";

      if [ -d ".git" ]; then
        fetch_err="$(git fetch --prune --quiet 2>&1)";

        status="$(git -c color.ui=always status --short)";
        branches="$(LANG=en_US git -c color.ui=false --no-pager branch -vv | grep -v -E '^[[:space:]\*][[:space:]]([^[:space:]]+).*?\[[^\/]+\/\1\]')";

        if [ -n "$fetch_err" ] || [ -n "$branches" ] || [ -n "$status" ]; then
          printf "\n$project\n";
        fi;

        if [ -n "$fetch_err" ]; then
          printf "\n$fetch_err\n";
        fi;

        if [ -z "$branches" ] && [ -z "$status" ]; then
          continue;
        fi;

        while true; do
          behind="$(printf "$branches" | grep -E '^[[:space:]][[:space:]]([^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]\[[^\/]+\/\1:[[:space:]]behind[[:space:]]\d+\]')";

          if [ -z "$behind" ]; then
            break;
          fi;

          [[ $behind =~ ^[[:space:]][[:space:]]([^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]\[([^/]+) ]];
          b="${BASH_REMATCH[1]}";
          r="${BASH_REMATCH[2]}";
          git fetch "$r" "$b":"$b" 2>&1 > /dev/null | grep -E "^[[:space:]][[:space:]][[:space:]][^\.]+\.\.[^\.]+[[:space:]][[:space:]]$b[^-]+->[[:space:]]$b$";
          branches="$(printf "$branches" | grep -v -E "^[[:space:]][[:space:]]$b[[:space:]]")";
        done;

        behind="$(printf "$branches" | grep -E '^\*[[:space:]]([^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]\[[^\/]+\/\1:[[:space:]]behind[[:space:]]\d+\]')";

        if [ -n "$behind" ]; then
          [[ $behind =~ ^\*[[:space:]]([^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]\[([^/]+) ]];
          b="${BASH_REMATCH[1]}";
          r="${BASH_REMATCH[2]}";
          git pull "$r" "$b" && branches="$(printf "$branches" | grep -v -E "^\*[[:space:]]$b[[:space:]]")";
        fi;

        if [ -n "$status" ]; then
          printf "$status\n";
        fi;

        printf "$branches" | sed -E 's/^[[:space:]\*][[:space:]]([^[:space:]]+).*$/\1/' | xargs git -c color.ui=always --no-pager branch -vv --list;
        printf "$branches" | grep 'HEAD detached';
      fi;
    );
  fi;
done;
