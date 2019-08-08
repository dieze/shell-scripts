#!/usr/bin/env bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/config.bash"

function help_git {
  printf "\n" && git__quiet_help
}

function git__quiet_help {
  printf "kgit config git.quiet \"bool\"\n"
  printf "\tWhether to add option --quiet to git command.\n"
  printf "\tdefault: \"true\"\n"
}
config_set 'git.quiet' 'true'

help_git
