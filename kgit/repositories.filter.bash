#!/usr/bin/env bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/config.bash"

function help_repositories__filter {
  printf "\n" && repositories__filter_help
  printf "\n" && repositories__filter__exclude_help
  printf "\n" && repositories__filter__organization_help # node-gh/gh parameter
  printf "\n" && repositories__filter__prefix_help
  printf "\n" && repositories__filter__type_help # node-gh/gh parameter
}

config_set 'repositories.filter' 'true'
function repositories__filter_help {
  printf "kgit config repositories.filter \"bool\"\n"
  printf "\tWhether to enable filters or not.\n"
  printf "\tdefault: \"$(config_get 'repositories.filter')\"\n"
}
#
# Applies repositories.filter config.
#
# Main entry point: applies filters on repositories details.
#
# stdin: repositories details, separated by \n\0 characters.
# stdout: repositories details, filtered, separated by \n\0 characters.
#
function repositories__filter {
  local REPOSITORY_DETAIL

  if [ "$(config_get 'repositories.filter')" == "true" ]; then
    while IFS='' read -r -d '' REPOSITORY_DETAIL; do
      printf "$REPOSITORY_DETAIL\0" | \
        repositories__filter__organization | \
        repositories__filter__prefix | \
        repositories__filter__exclude
    done
  else
    while IFS='' read -r -d '' REPOSITORY_DETAIL; do
      printf "$REPOSITORY_DETAIL\0"
    done
  fi
}

#
# TODO Create profiles
#

REPOSITORIES__FILTER__EXCLUDE='('
REPOSITORIES__FILTER__EXCLUDE+='deprecated|DEPRECATED|'
REPOSITORIES__FILTER__EXCLUDE+='poc|POC'
REPOSITORIES__FILTER__EXCLUDE+=')'
config_set 'repositories.filter.exclude' "$REPOSITORIES__FILTER__EXCLUDE"
function repositories__filter__exclude_help {
  printf "kgit config repositories.filter.exclude \"exclude1,exclude2\"\n"
  printf "\tSet default exclude string (regexp) when searching repositories on GitHub. Case sensitive.\n"
  printf "\tdefault: \"$(config_get 'repositories.filter.exclude')\"\n"
}
#
# Applies repositories.filter.exclude config.
#
# stdin: repositories details, separated by null character.
# stdout: repositories details, separated by null character, with exclude config applied.
#
function repositories__filter__exclude {
  local EXCLUDE_PATTERN="$(config_get 'repositories.filter.exclude')"
  local REPOSITORY_DETAIL

  while IFS= read -r -d '' REPOSITORY_DETAIL; do
    if ! [[ $REPOSITORY_DETAIL =~ $EXCLUDE_PATTERN ]]; then
      printf '%b\0' "$REPOSITORY_DETAIL"
    fi
  done
}

config_set 'repositories.filter.organization' 'A-CMS'
function repositories__filter__organization_help {
  printf "kgit config repositories.filter.organization \"organization\"\n"
  printf "\tSet default repositories organization when searching repositories on GitHub.\n"
  printf "\tdefault: \"$(config_get 'repositories.filter.organization')\"\n"
}
#
# Applies repositories.filter.organization config.
#
# stdin: repositories details, separated by null character.
# stdout: repositories details, separated by null character, with prefix config applied.
#
function repositories__filter__organization {
  local ORGANIZATION="$(config_get 'repositories.filter.organization')"
  local REPOSITORY_DETAIL

  while IFS= read -r -d '' REPOSITORY_DETAIL; do
   if [[ $REPOSITORY_DETAIL =~ ^$ORGANIZATION ]]; then
      printf '%b\0' "$REPOSITORY_DETAIL"
   fi
  done
}

#
# Applies repositories.filter.organization config, as node-gh/gh parameter.
#
# stdout: --organization parameter to add to gh --list command.
#
function repositories__filter__organization_gh {
  local ORGANIZATION="$(config_get 'repositories.filter.organization')"

  if [ -n "$ORGANIZATION" ]; then
    local PARAMETER=('--organization' "$ORGANIZATION")
    printf '%s %s' "${PARAMETER[@]}"
  fi
}

config_set 'repositories.filter.prefix' 'deprecated-'
function repositories__filter__prefix_help {
  printf "kgit config repositories.filter.prefix \"prefix\"\n"
  printf "\tSet default repository prefix (regexp) when searching repositories on GitHub.\n"
  printf "\tThe prefix must not include repository organization name.\n"
  printf "\tdefault: \"$(config_get 'repositories.filter.prefix')\"\n"
}
#
# Applies repositories.filter.prefix config.
#
# stdin: repositories details, separated by null character.
# stdout: repositories details, separated by null character, with prefix config applied.
#
function repositories__filter__prefix {
  local PREFIX="$(config_get 'repositories.filter.prefix')"
  local REPOSITORY_DETAIL

  while IFS= read -r -d '' REPOSITORY_DETAIL; do
   if [[ $REPOSITORY_DETAIL =~ ^[-_a-zA-Z0-9]+/$PREFIX ]]; then
      printf '%b\0' "$REPOSITORY_DETAIL"
   fi
  done
}

config_set 'repositories.filter.type' 'private'
function repositories__type_help {
  printf "kgit config repositories.type \"type\"\n"
  printf "\tThe type of repositories to search on GitHub.\n"
  printf "\tPossible values are:\n"
  printf "\t\t\"all\": search in all repositories\n"
  printf "\t\t\"owner\": search in repositories owned by logged in user.\n"
  printf "\t\t\"public\": search only in public repositories.\n"
  printf "\t\t\"private\": search only in private repositories.\n"
  printf "\t\t\"member\": search only in repositories on which the logged in user is member.\n"
  printf "\tYou cannot use multiple values at a time.\n"
  printf "\tdefault: \"$(config_get 'repositories.filter.type')\"\n"
}
#
# Applies repositories.filter.type config.
#
# stdout: --type parameter to add to gh --list command.
#
function repositories__filter__type {
  local TYPE="$(config_get 'repositories.filter.type')"

  if [ -n "$TYPE" ]; then
    local PARAMETER=('--type' "$TYPE")
    printf '%s %s' "${PARAMETER[@]}"
  fi
}

#
# Apply node-gh/gh command filter parameters.
#
# stdout: filter parts to add to gh command.
#
function repositories__filter_gh {
  local PARTS=()

  PARTS+=($(repositories__filter__organization_gh))
  PARTS+=($(repositories__filter__type))

  echo "${PARTS[@]}"
}
