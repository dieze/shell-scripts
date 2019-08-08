#!/usr/bin/env bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/config.bash"

function help_status_help {
  printf "kgit help status\n"
  printf "\tShow help for status command.\n"
}
function help_status {
  printf "\n" && help_status_help
  printf "\n" && status_help
}

function status_help {
  printf "kgit status\n"
  printf "\tExecute \"git status\" on cloned project in current directory.\n"
  printf "\tOnly outputs if there is untracked/uncommitted changes.\n"
  printf "\tExecutes \"kgit repositories\" to search repositories on which execute status.\n"
}
function status {
  printf "status"
}

help_status
