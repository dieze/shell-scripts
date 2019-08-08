#!/usr/bin/env bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/config.bash"
. "$DIR/repositories.bash"

function help_clone_help {
  printf "kgit help clone\n"
  printf "\tShow help for clone command.\n"
}
function help_clone {
  printf "\n" && help_clone_help
  printf "\n" && clone__strategy_help
  printf "\n" && clone_help
}

function clone__strategy_help {
  printf "kgit config \"clone.strategy\" \"strategy\"\n"
  printf "\tSpecify which strategy to use on clone.\n"
  printf "\tPossible values are:\n"
  printf "\t\t\"https\": clone using https.\n"
  printf "\t\t\"ssl\": clone using ssl.\n"
  printf "\tdefault: \"ssl\"\n"
}
config_set 'clone.strategy' 'ssl'
#
# Applies clone.strategy config.
#
# $1: repository full name owner/repo.
#
# stdin: nothing
# stdout: clone url, according to clone.strategy.
#
function clone__strategy {
  local REPOSITORY_FULL_NAME="$1"
  local CLONE_STRATEGY="$(config_get 'clone.strategy')"

  if [ "$CLONE_STRATEGY" == "https" ]; then
    printf "https://github.com/$REPOSITORY_FULL_NAME.git"
  else
    # ssl by default
    printf "git@github.com:$REPOSITORY_FULL_NAME.git"
  fi
}

function clone_help {
  printf "kgit [-c config=\"value\"] clone\n"
  printf "\tClone repositories.\n"
  printf "\tExecutes \"kgit repositories\" to search matching repositories to clone.\n"
  printf "\tA found repository is cloned only if there is no directory matching repository project name in current directory.\n"
  printf "\n"
  printf '\t%s\n' "-c"
  printf "\t\tConfiguration values. Includes:\n"
  printf "\t\t\t\"clone.\"\n"
  printf "\t\t\t\"git.\"\n"
  printf "\t\t\t\"kgit.\"\n"
  printf "\t\t\t\"repositories\"\n"
}
#
# Parameters (after config_apply_parameters and shift):
# None.
#
# stdout: print from git clone.
# stderr: errors from git clone.
#
function clone {
  config_apply_parameters "$@"
  shift "$?"

  local REPOSITORY_ENTRY
  local REPOSITORY_OWNER
  local REPOSITORY_NAME

  # repository user [USER] should not contain space
  # repository name [REPO] should not contain space
  repositories -c repositories.format='[USER] [REPO]' -c repositories.warn.missing.repository=false | \
    while IFS= read -r -d '' REPOSITORY_ENTRY; do
      read REPOSITORY_OWNER REPOSITORY_NAME <<< "$REPOSITORY_ENTRY"

      if [ ! -d "$REPOSITORY_NAME" ]; then
        git clone "$(clone__strategy "$REPOSITORY_OWNER/$REPOSITORY_NAME")"
        printf "$REPOSITORY_NAME\n" | repositories__warn__missing__branch
      fi
    done
}

clone "$@"
