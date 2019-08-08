#!/usr/bin/env bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/config.bash"

function help_repositories__warn {
  printf "\n" && repositories__warn_help
  printf "\n" && repositories__warn__missing_help
  printf "\n" && repositories__warn__missing__repository_help
  printf "\n" && repositories__warn__missing__branch__development_help
  printf "\n" && repositories__warn__missing__branch__production_help
}

config_set 'repositories.warn' 'true'
function repositories__warn_help {
  printf "kgit config repositories.warn \"bool\"\n"
  printf "\tWhether to enable warnings or not for repositories command.\n"
  printf "\tdefault: \"$(config_get 'repositories.warn')\"\n"
}
#
# Applies repositories.warn config.
#
# Main entry point: prints warnings for repositories command.
#
# stdin: repositories names, without organization prefix, separated by newline.
# stdout: nothing.
# stderr: warnings.
#
function repositories__warn {
  local REPOSITORY_NAME

  if [ "$(config_get 'repositories.warn')" == "true" ]; then
    while IFS=$'\n' read -r -d $'\n' REPOSITORY_NAME; do
      printf "$REPOSITORY_NAME\n" | \
        repositories__warn__missing
    done
  fi
}

config_set 'repositories.warn.missing' 'true'
function repositories__warn__missing_help {
  printf "kgit config repositories.warn.missing \"bool\"\n"
  printf "\tWhether to enable warnings or not for missing elements for repositories command.\n"
  printf "\tdefault: \"$(config_get 'repositories.warn.missing')\"\n"
}
#
# Applies repositories.warn.missing config.
#
# stdin: repositories names, without organization prefix, separated by newline.
# stdout: nothing.
# stderr: warnings.
#
function repositories__warn__missing {
  local REPOSITORY_NAME

  if [ "$(config_get 'repositories.warn.missing')" == "true" ]; then
    while IFS=$'\n' read -r -d $'\n' REPOSITORY_NAME; do
      printf "$REPOSITORY_NAME\n" | repositories__warn__missing__repository
      printf "$REPOSITORY_NAME\n" | repositories__warn__missing__branch
    done
  fi
}

config_set 'repositories.warn.missing.repository' 'true'
function repositories__warn__missing__repository_help {
  printf "kgit config repositories.warn.missing.repository \"bool\"\n"
  printf "\tWhether to enable warnings or not for missing repository on current directory for repositories command.\n"
  printf "\tdefault: \"$(config_get 'repositories.warn.missing.repository')\"\n"
}
#
# Applies repositories.warn.missing.repository config.
#
# stdin: repositories names, without organization prefix, separated by newline.
# stdout: nothing.
# stderr: warnings.
#
function repositories__warn__missing__repository {
  local REPOSITORY_NAME

  if [ "$(config_get 'repositories.warn.missing.repository')" == "true" ]; then
    while IFS=$'\n' read -r -d $'\n' REPOSITORY_NAME; do
      if ! [ -d "$REPOSITORY_NAME" ]; then
        repositories_warn "missing repository $REPOSITORY_NAME"
      fi
    done
  fi
}

config_set 'repositories.warn.missing.branch' 'true'
function repositories__warn__missing__branch_help {
  printf "kgit config repositories.warn.missing.branch \"bool\"\n"
  printf "\tWhether to warn for missing branch for repositories command.\n"
  printf "\tdefault: \"$(config_get 'repositories.warn.missing.branch')\n"
}
#
# stdin: repositories names, without organization prefix, separated by newline.
# stdout: nothing.
# stderr: warnings.
#
function repositories__warn__missing__branch {
  local REPOSITORY_NAME

  if [ "$(config_get 'repositories.warn.missing.branch')" == "true" ]; then
    while IFS=$'\n' read -r -d $'\n' REPOSITORY_NAME; do
      printf "$REPOSITORY_NAME\n" | repositories__warn__missing__branch__ "development"
      printf "$REPOSITORY_NAME\n" | repositories__warn__missing__branch__ "production"
    done
  fi
}

config_set 'repositories.warn.missing.branch.development' 'true'
function repositories__warn__missing__branch__development_help {
  printf "kgit config repositories.warn.missing.branch.development \"bool\"\n"
  printf "\tWhether to warn for missing development remote branch for repositories command.\n"
  printf "\tdefault: \"$(config_get 'repositories.warn.missing.branch.development')\"\n"
}
#
# $1: type of branch "development" or "production".
#
# stdin: repositories names, without organization prefix, separated by newline.
# stdout: nothing.
# stderr: warnings.
#
# expects: remote name is "origin".
#
function repositories__warn__missing__branch__ {
  local BRANCH_TYPE="$1"
  local REPOSITORY_NAME

  if [ "$(config_get "repositories.warn.missing.branch.$BRANCH_TYPE")" == "true" ]; then
    local BRANCH_NAME="$(config_get "repositories.branch.$BRANCH_TYPE")"

    while IFS=$'\n' read -r -d $'\n' REPOSITORY_NAME; do
      (
        if [ -d "$REPOSITORY_NAME" ]; then
          cd "$REPOSITORY_NAME"

          if [ -z "$(git branch -r | grep "origin/$BRANCH_NAME")" ]; then
            repositories_warn "missing $BRANCH_TYPE branch $BRANCH_NAME for repository $REPOSITORY_NAME"
          fi
        fi
      )
    done
  fi
}

config_set 'repositories.warn.missing.branch.production' 'true'
function repositories__warn__missing__branch__production_help {
  printf "kgit config repositories.warn.missing.branch.production \"bool\"\n"
  printf "\tWhether to warn for missing production branch for repositories command.\n"
  printf "\tdefault \"$(config_get 'repositories.warn.missing.branch.production')\"\n"
}

#
# Print warning message to stderr.
#
# $1: Warning message detail.
# stderr: Full warning message.
#
function repositories_warn {
  printf "\e[33mWARN: %b\e[0m\n" "$1" 1>&2
}
