#!/usr/bin/env bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/checkout.bash"
. "$DIR/clone.bash"
. "$DIR/config.bash"
. "$DIR/fetch.bash"
. "$DIR/git.bash"
. "$DIR/prune.bash"
. "$DIR/repositories.bash"
. "$DIR/status.bash"
. "$DIR/update.bash"
. "$DIR/user.bash"

#
# kgit config kgit.interactive "bool"
#   Whether to ask before executing git command.
#   default: "false"
#
config_set 'kgit.interactive' 'false'
