#!/usr/bin/env bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/config.bash"
. "$DIR/repositories.bash"

function help_checkout_help {
  printf "kgit help checkout\n"
  printf "\tShow help for checkout command.\n"
}
function help_checkout {
  printf "\n" && help_checkout_help
  printf "\n" && checkout__allow_remote_help
  printf "\n" && checkout_help
}

config_set 'checkout.allow_remote' 'true'
function checkout__allow_remote_help {
  printf "kgit config \"checkout.allow_remote\" \"bool\"\n"
  printf "\tWhether to create tracking local branch when checkout.\n"
  printf "\tdefault: \"$(config_get 'checkout.allow_remote')\"\n"
}
#
# Checkout to remote branch, if any.
#
# $1: the branch name to checkout to.
# stdin: repositories names, without organization prefix, separated by newline.
# stdout: print from git checkout.
# stderr: errors from git checkout.
#
# expects: remote name is "origin".
#
function checkout__allow_remote {
  local BRANCH_NAME="$1"
  local REPOSITORY_NAME

  if [ "$(config_get 'checkout.allow_remote')" == "true" ]; then
    while IFS=$'\n' read -r -d $'\n' REPOSITORY_NAME; do
      (
        cd "$REPOSITORY_NAME"

        if [ -n "$(git branch -r | grep "origin/$BRANCH_NAME")" ]; then
          git checkout "$BRANCH_NAME"
        fi
      )
    done
  fi
}

function checkout_help {
  printf "kgit [-c config=\"value\"] checkout [branch]\n"
  printf "\tCheckout to a branch in cloned repositories.\n"
  printf "\tExecutes \"kgit repositories\" to search matching repositories on which execute checkout command.\n"
  printf "\tCheckout only if there is a local branch (or remote branch if config \"checkout.allow-remote=\"true\") matching [branch].\n"
  printf "\n"
  printf '\t%s\n' "-c"
  printf "\t\tConfiguration values. Includes:\n"
  printf "\t\t\t\"checkout.\"\n"
  printf "\t\t\t\"git.\"\n"
  printf "\t\t\t\"kgit.\"\n"
  printf "\t\t\t\"repositories.\"\n"
}
#
# Parameters (after config_apply_parameters and shift):
# $0: branch to checkout to.
#
# stdout: print from git checkout.
# stderr: errors from git checkout.
#
function checkout {
  config_apply_parameters "$@"
  shift "$?"

  local BRANCH_NAME="$1"
  local REPOSITORY_NAME

  repositories -c repositories.format='[REPO]' | \
    while IFS= read -r -d '' REPOSITORY_NAME; do
      if [ -d "$REPOSITORY_NAME" ]; then
        (
          cd "$REPOSITORY_NAME"

          if [ -n "$(git branch | grep "$BRANCH_NAME")" ]; then
            # checkout to local branch
            git checkout "$BRANCH_NAME"
            return 0
          else
            return 1
          fi
        ) || \
          # may checkout to remote branch
          printf "$REPOSITORY_NAME\n" | checkout__allow_remote "$BRANCH_NAME"
      fi
    done
}

checkout "$@"
