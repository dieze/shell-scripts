#!/usr/bin/env bash

arg1="${1:-.}"

if [ ! -d "$arg1" ]; then
  echo "not a directory: $arg1" >&2
  exit 1
fi

if [ ! -d "$arg1/.git" ]; then
  echo "not a git repository: $arg1" >&2
  exit 1
fi

(
  cd "$arg1"
  project="${PWD##*/}"

  fetch_err="$(git fetch --prune --tags --quiet 2>&1)"

  status="$(git -c color.ui=always status --short)"
  branches="$(LC_MESSAGES=C git -c color.ui=false --no-pager branch -vv | grep -v -E '^[[:space:]\*][[:space:]]([^[:space:]]+).*?\[[^\/]+\/\1\]')"
  pull_requests="$(
    if [ -n "$(which hub)" ] && [ -n "$(git remote | grep '^origin$')" ]; then
      repository="$(git remote get-url origin | sed -E 's/[^:]+:(.+\/.+)/\1/' | sed 's/\.git$//')"

      hub pr list --state="open" --sort="created" --format="%B;<;%H;%au;%U;%l%n" 2> /dev/null | while read pull_request_csv; do
        printf "${pull_request_csv/%;/;-}"

        repository_api_url="repos/$repository/pulls/$(printf "$pull_request_csv" | sed -E 's/.*\/pull\/([0-9]+).*/\1/')"

        hub api --flat "$repository_api_url/reviews" | grep -e '.user.login' -e '.state' | while read login && read state; do
          printf ";"
          printf "$login:" | cut -d$'\t' -f2 | tr -d $'\n'
          printf "$state" | cut -d$'\t' -f2 | tr -d $'\n'
          printf "\n"
        done | sort -u | tr -d $'\n'

        printf "\n"
      done | column -ts ';' | sed 's/^/  /'
    fi
  )"

  if [ -n "$fetch_err" ] || [ -n "$branches" ] || [ -n "$status" ] || [ -n "$pull_requests" ]; then
    printf "\n$project\n"
  fi

  if [ -n "$fetch_err" ]; then
    printf "\n$fetch_err\n"
  fi

  if [ -z "$branches" ] && [ -z "$status" ] && [ -z "$pull_requests" ]; then
    exit 0
  fi

  while true; do
    behind="$(printf "$branches" | grep -E '^[[:space:]][[:space:]]([^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]\[[^\/]+\/\1:[[:space:]]behind[[:space:]]\d+\]')"

    if [ -z "$behind" ]; then
      break
    fi

    [[ $behind =~ ^[[:space:]][[:space:]]([^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]\[([^/]+) ]]
    b="${BASH_REMATCH[1]}"
    r="${BASH_REMATCH[2]}"
    git fetch "$r" "$b":"$b" 2>&1 > /dev/null | grep -E "^[[:space:]][[:space:]][[:space:]][^\.]+\.\.[^\.]+[[:space:]][[:space:]]$b[^-]+->[[:space:]]$b$"
    branches="$(printf "$branches" | grep -v -E "^[[:space:]][[:space:]]$b[[:space:]]")"
  done

  behind="$(printf "$branches" | grep -E '^\*[[:space:]]([^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]\[[^\/]+\/\1:[[:space:]]behind[[:space:]]\d+\]')"

  if [ -n "$behind" ]; then
    [[ $behind =~ ^\*[[:space:]]([^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]\[([^/]+) ]]
    b="${BASH_REMATCH[1]}"
    r="${BASH_REMATCH[2]}"
    git pull "$r" "$b" && branches="$(printf "$branches" | grep -v -E "^\*[[:space:]]$b[[:space:]]")"
  fi

  if [ -n "$status" ]; then
    printf "$status\n"
  fi

  printf "$branches" | sed -E 's/^[[:space:]\*][[:space:]]([^[:space:]]+).*$/\1/' | xargs git -c color.ui=always --no-pager branch -vv --list
  printf "$branches" | grep 'HEAD detached'
  [ -n "$pull_requests" ] && printf "$pull_requests\n"
)
