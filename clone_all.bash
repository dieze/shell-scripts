#!/bin/bash

#
# git clone strategy.
#
# "https": clone using https.
# "ssh": clone using ssh.
#
GIT_CLONE_STRATEGY="ssh"

#
# Login to github.
#
function login_to_github() {
  gh user --login
}

#
# List detailed information for each private repository.
#
# stdout: repositories details separated by null character.
#
function list_private_repositories_details() {
  local IFS=$'\n'
  local REPOSITORY_DETAIL=""
  local LINE

  for LINE in $(gh re --list --detailed --type private); do
    REPOSITORY_DETAIL="$REPOSITORY_DETAIL\n$LINE"

    if [[ $LINE =~ ^last\ update ]]; then
      printf '%b\0' "${REPOSITORY_DETAIL/\\n}"
      REPOSITORY_DETAIL=""
    fi
  done
}

#
# Extract organization repositories details.
#
# stdin: repositories details separated by null character.
# stdout: organization repositories details separated by null character.
#
function extract_organization_repositories_details() {
  while IFS= read -r -d '' REPOSITORY_DETAIL; do
    if [[ $REPOSITORY_DETAIL =~ ^orginanization/(prefix[-_a-zA-Z0-9]+) ]]; then
      printf '%b\0' "$REPOSITORY_DETAIL"
    fi
  done
}

#
# Extract active repositories details.
#
# A repository is active if its detail does not contain "poc" nor "deprecated".
#
# stdin: respositories details separated by null character.
# stdout: active repositories details separated by null character.
#
function extract_active_repositories_details() {
  while IFS= read -r -d '' REPOSITORY_DETAIL; do
    if ! [[ $REPOSITORY_DETAIL =~ (poc|POC|deprecated|DEPRECATED) ]]; then
      printf '%b\0' "$REPOSITORY_DETAIL"
    fi
  done
}

#
# Extract repositories full names from repositories details.
#
# A repository full name is: user/repository (without git suffix).
#
# stdin: repositories details separated by null character.
# stdout: repositories names separated by newline character.
#
function extract_repositories_full_names() {
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
# stdin: repositories full names separated by newline character.
# stdout: repositories names separated by newline character.
#
function extract_repositories_names() {
  while read -r REPOSITORY_FULL_NAME; do
    if [[ $REPOSITORY_FULL_NAME =~ ^[-_a-zA-Z0-9]+\/([-_a-zA-Z0-9]+) ]]; then
      printf '%b\n' "${BASH_REMATCH[1]}"
    fi
  done
}

#
# Clone repositories from their full names.
#
# The repository is cloned only if there is no matching folder in current directory.
#
# stdin: repositories full names separated by newline character.
#
function clone_repositories() {
  while read -r REPOSITORY_FULL_NAME; do
    REPOSITORY_NAME="$(echo "$REPOSITORY_FULL_NAME" | extract_repositories_names)"

    if ! [ -d "$REPOSITORY_NAME" ]; then
      git clone "$(echo "$REPOSITORY_FULL_NAME" | get_clone_urls)"
    fi
  done
}

#
# Get the clone urls from the repositories full names.
#
# stdin: repositories full names, in the format user/repository (without .git suffix), separated by newline character.
# stdout: repositories clone urls separated by newline character.
#
# Uses global variables:
#
# GIT_CLONE_STRATEGY: the clone strategy to use.
#
function get_clone_urls() {
  while read -r REPOSITORY_FULL_NAME; do
    case "$GIT_CLONE_STRATEGY" in
      ssh)
        printf '%b\n' "git@github.com:${REPOSITORY_FULL_NAME}.git"
        ;;
      https)
        printf '%b\n' "https://github.com/${REPOSITORY_NAME}.git"
        ;;
      *)
        echo "Unexpected git clone strategy: $GIT_CLONE_STRATEGY" >&2
        exit 1
        ;;
    esac
  done
}

login_to_github

list_private_repositories_details | \
  extract_organization_repositories_details | \
  extract_active_repositories_details | \
  extract_repositories_full_names | \
  clone_repositories
