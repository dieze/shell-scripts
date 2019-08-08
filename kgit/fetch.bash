#!/usr/bin/env bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/config.bash"

function help_fetch_help {
  printf "kgit help fetch\n"
  printf "\tShow help for fetch command.\n"
}
function help_fetch {
  printf "\n" && help_fetch_help
  printf "\n" && fetch__prune_help
  printf "\n" && fetch_help
}

function fetch__prune_help {
  printf "kgit config \"fetch.prune\" \"bool\"\n"
  printf "\tWhether to add --prune option to git fetch.\n"
  printf "\tdefault: \"true\"\n"
}
config_set 'fetch.prune' 'true'

function fetch_help {
  printf "kgit [-c config=\"value\"] fetch\n"
  printf "\tFetch latest commits from remote in cloned repositories.\n"
  printf "\tExecutes \"kgit repositories\" to search matching repositories to fetch.\n"
  printf "\n"
  printf '\t%s\n' "-c"
  printf "\t\tConfiguration values. Includes:\n"
  printf "\t\t\t\"fetch.\"\n"
  printf "\t\t\t\"git.\"\n"
  printf "\t\t\t\"kgit.\"\n"
  printf "\t\t\t\"repositories.\"\n"
}
function fetch {
  printf "fetch"
}

help_fetch
