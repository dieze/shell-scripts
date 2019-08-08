#!/usr/bin/env bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/config.bash"
. "$DIR/repositories.filter.bash"
. "$DIR/repositories.warn.bash"
. "$DIR/user.bash"

function help_repositories_help {
  printf "kgit help repositories\n"
  printf "\tShow help for repositories command.\n"
}
function help_repositories {
  printf "\n" && help_repositories_help
  printf "\n" && repositories__branch__development_help
  printf "\n" && repositories__branch__production_help

  help_repositories__filter
  help_repositories__warn

  printf "\n" && repositories_help
}

config_set 'repositories.branch.development' 'dev_pi3'
function repositories__branch__development_help {
  printf "kgit config repositories.branch.development \"dev\"\n"
  printf "\tName of the development branch in repositories.\n"
  printf "\tdefault: \"$(config_get 'repositories.branch.development')\"\n"
}

config_set 'repositories.branch.production' 'master'
function repositories__branch__production_help {
  printf "kgit config repositories.branch.production \"prod\"\n"
  printf "\tName of the production branch in repositories.\n"
  printf "\tdefault: \"$(config_get 'repositories.branch.production')\"\n"
}

config_set 'repositories.format' '[USER]/[REPO]\n[URL]\n[DESC]\n[LAST_UPDATE]\n'
function repositories__format__help {
  # command substitution removes trailing newline characters
  local DEFAULT
  IFS= read -r -d '' DEFAULT < <(config_get 'repositories.format')

  printf "kgit config repositories.format \"format\"\n"
  printf "\tDisplay format of repositories.\n"
  printf "\tPossible placeholders are:\n"
  printf "\t\t\"[USER]\": repository owner (user/organization).\n"
  printf "\t\t\"[REPO]\": repository name.\n"
  printf "\t\t\"[URL]\": repository url (https).\n"
  printf "\t\t\"[DESC]\": repository description.\n"
  printf "\t\t\"[LAST_UPDATE]\": information about last update.\n"
  printf "\tEmpty format mutes the output.\n"
  printf "\tdefault: \"$DEFAULT\"\n"
}
#
# Applies repositories.format config.
#
# Outputs repositories command in a specific format.
#
# stdin: Repository details, separated by null character.
# stdout: Output matching format, separated by null character.
#
function repositories__format {
  local REPOSITORY_DETAIL
  local FORMAT
  local RESULT

  # command substitution removes trailing newline characters
  IFS= read -r -d '' FORMAT < <(config_get 'repositories.format')

  while IFS= read -r -d '' REPOSITORY_DETAIL; do
    RESULT="$FORMAT"

    if [ -z "$FORMAT" ]; then
      printf "$RESULT"
    else
      # REPOSITORY_DETAIL:
      #
      # [USER]/[REPO]\n
      # [URL]\n
      # [DESC]\n         <= can be absent
      # [LAST_UPDATE]\n

      local ALPHA_NUM_SYM="[-_a-zA-Z0-9]+"
      local NUM="[0-9]+"
      local NEWLINE=$'\n'

      # bash only: "+="
      local R="^"
      R+="(${ALPHA_NUM_SYM})\/(${ALPHA_NUM_SYM})${NEWLINE}"
      R+="([^${NEWLINE}]+)${NEWLINE}" # URL
      R+="([^${NEWLINE}]*)${NEWLINE}?" # DESC
      R+="(last update .*)${NEWLINE}"
      R+="$"

      [[ $REPOSITORY_DETAIL =~ $R ]]

      local USER="${BASH_REMATCH[1]}"
      local REPO="${BASH_REMATCH[2]}"
      local URL="${BASH_REMATCH[3]}"
      local DESC="${BASH_REMATCH[4]}"
      local LAST_UPDATE="${BASH_REMATCH[5]}"

      RESULT="${RESULT//\[USER\]/$USER}"
      RESULT=${RESULT//\[REPO\]/$REPO}
      RESULT="${RESULT//\[URL\]/$URL}"
      RESULT="${RESULT//\[DESC\]/$DESC}"
      RESULT="${RESULT//\[LAST_UPDATE\]/$LAST_UPDATE}"

      # printf in command substitution removes trailing \n
      printf "$RESULT\0"
    fi
  done
}

function repositories_help {
  printf "kgit [-c config=\"value\"] repositories\n"
  printf "\tList repositories.\n"
}
function repositories {
  local REPOSITORY_DETAIL

  user_login > /dev/null
  config_apply_parameters "$@"

  local COMMAND=('gh' 'repo' '--list' '--detailed' $(repositories__filter_gh))

  "${COMMAND[@]}" | \
    repositories_details | \
    repositories__filter | \
    while IFS= read -r -d '' REPOSITORY_DETAIL; do
      printf "$REPOSITORY_DETAIL\0" # print to stdout

      printf "$REPOSITORY_DETAIL\0" | \
        repositories_full_names | \
        repositories_names | \
        repositories__warn
        # repositories__warn:
        #   * needs repositories names as stdin
        #   * prints on stderr
        #   * does not print on stdout
    done | \
    repositories__format
}

#
# Split repositories details in paragraphs split by \n\0 characters.
#
# stdin: repositories details, unsplitted.
# stdout: repositories details, split by \n\0 character.
#
function repositories_details {
  local REPOSITORY_DETAIL=""
  local LINE

  while IFS=$'\n' read -r -d $'\n' LINE; do
    REPOSITORY_DETAIL="$REPOSITORY_DETAIL\n$LINE"

    if [[ $LINE =~ ^last\ update ]]; then
      printf '%b\n\0' "${REPOSITORY_DETAIL/\\n}"
      REPOSITORY_DETAIL=""
    fi
  done
}

#
# Extract repositories full names from repositories details.
#
# A repository full name is: user/repository (without git suffix).
#
# stdin: repositories details, separated by null character.
# stdout: repositories names, separated by newline character.
#
function repositories_full_names {
  local REPOSITORY_DETAIL

  while IFS= read -r -d '' REPOSITORY_DETAIL; do
    if [[ $REPOSITORY_DETAIL =~ ^[-_\/a-zA-Z0-9]+ ]]; then
      printf '%b\n' "${BASH_REMATCH[0]}"
    fi
  done
}

#
# Extract repositories names from respositories full names.
#
# A repository name is: repository (without user/ prefix nor git suffix).
#
# stdin: repositories full names, separated by newline character.
# stdout: repositories names, separated by newline character.
#
function repositories_names() {
  local REPOSITORY_FULL_NAME

  while read -r REPOSITORY_FULL_NAME; do
    if [[ $REPOSITORY_FULL_NAME =~ ^[-_a-zA-Z0-9]+\/([-_a-zA-Z0-9]+) ]]; then
      printf '%b\n' "${BASH_REMATCH[1]}"
    fi
  done
}

#repositories "$@"
