#!/usr/bin/env bash

#
# From github user/organization, clone all repositories having a given prefix.
#
# Requires node-gh : https://github.com/node-gh/gh
#

#
# git clone strategy.
#
# "https": clone using https.
# "ssh": clone using ssh.
#
git_clone_strategy="ssh"

#
# Name of organization/user from which clone repositories.
#
organization_name="dieze"

#
# Prefix of repositories to clone on the organization.
#
repositories_prefix="config"

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
  local repository_detail=""
  local line

  for line in $(gh re --list --detailed --type private); do
    repository_detail="$repository_detail\n$line"

    if [[ $line =~ ^last\ update ]]; then
      printf '%b\0' "${repository_detail/\\n}"
      repository_detail=""
    fi
  done
}

#
# Extract organization repositories details.
#
# stdin: repositories details separated by null character.
# stdout: organization repositories details separated by null character.
#
# Uses global variables:
#
# organization_name: name of organization/user from which clone repositories.
# repositories_prefix: prefix of repositories to clone on the organization.
#
function extract_organization_repositories_details() {
  regex="^${organization_name}/(${repositories_prefix}[-_a-zA-Z0-9]+)"
  while IFS= read -r -d '' repository_detail; do
    if [[ $repository_detail =~ $regex ]]; then
      printf '%b\0' "$repository_detail"
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
  while IFS= read -r -d '' repository_detail; do
    if ! [[ $repository_detail =~ (poc|POC|deprecated|DEPRECATED) ]]; then
      printf '%b\0' "$repository_detail"
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
  while IFS= read -r -d '' repository_detail; do
    if [[ $repository_detail =~ ^[-_\/a-zA-Z0-9]+ ]]; then
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
  while read -r repository_full_name; do
    if [[ $repository_full_name =~ ^[-_a-zA-Z0-9]+\/([-_a-zA-Z0-9]+) ]]; then
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
  while read -r repository_full_name; do
    repository_name="$(echo "$repository_full_name" | extract_repositories_names)"

    if ! [ -d "$repository_name" ]; then
      git clone "$(echo "$repository_full_name" | get_clone_urls)"
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
# git_clone_strategy: the clone strategy to use.
#
function get_clone_urls() {
  while read -r repository_full_name; do
    case "$git_clone_strategy" in
      ssh)
        printf '%b\n' "git@github.com:${repository_full_name}.git"
        ;;
      https)
        printf '%b\n' "https://github.com/${repository_name}.git"
        ;;
      *)
        echo "Unexpected git clone strategy: $git_clone_strategy" >&2
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
