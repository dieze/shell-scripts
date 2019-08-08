#!/usr/bin/env bash

# unfortunately associative arrays are not supported in bash 3
if [ -z ${CONFIG_KEYS+"defined"} ] && [ -z ${CONFIG_VALUES+"defined"} ]; then
  # security do not reset config if config.bash is sourced many times
  # CONFIG_KEYS and CONFIG_VALUES must always be declared together.
  CONFIG_KEYS=()
  CONFIG_VALUES=()
fi

function help_config_help {
  printf "kgit help config\n"
  printf "\tShow help for config command.\n"
}
function help_config {
  printf "\n" && help_config_help
  printf "\n" && config_set_help
  printf "\n" && config_get_help
  printf "\n" && config_list_help
}

#
# Find matching index for a config key.
#
# $1: The config key to find index for.
# stdout: -1 if not found, or config index.
#
function config_index {
  local KEY="$1"
  local CONFIG_KEY

  local LENGTH="${#CONFIG_KEYS[@]}"
  local I=0

  for (( I=0; I<$LENGTH; I++ )); do
    CONFIG_KEY="${CONFIG_KEYS[$I]}"

    if [ "$CONFIG_KEY" == "$KEY" ]; then
      printf '%d' "$I"
      return 0
    fi
  done

  printf '%d' '-1'
}

function config_set_help {
  printf "kgit config [key] [value]\n"
  printf "\tSet configuration value.\n"
}
#
# $1: Config key to set value.
# $2: Value to set.
#
function config_set {
  local KEY="$1"
  local VALUE="$2"

  local INDEX="$(config_index "$KEY")"

  if [ "$INDEX" -gt "-1" ]; then
    CONFIG_VALUES["$INDEX"]="$VALUE"
  else
    CONFIG_KEYS+=("$KEY")
    CONFIG_VALUES+=("$VALUE")
  fi
}

function config_get_help {
  printf "kgit config [key]\n"
  printf "\tShow value for configuration key.\n"
}
#
# $1: Config key to show value.
# stdout: Value for config key.
#
# returns: 0 if config key exists, or -1.
#
function config_get {
  local KEY="$1"
  local INDEX=$(config_index "$KEY")

  if [ "$INDEX" -gt -1 ]; then
    printf "${CONFIG_VALUES[$INDEX]}"
    return 0
  fi

  return -1
}

function config_list_help {
  printf "kgit config --list\n"
  printf "\tList configurations.\n"
}
#
# stdout: one key=value per line.
#
function config_list {
  local LENGTH="${#CONFIG_KEYS[@]}"
  local I

  for (( I=0; I<$LENGTH; I++ )); do
    printf '%s=%s\n' "${CONFIG_KEYS[$I]}" "${CONFIG_VALUES[$I]}"
  done
}

#
# Apply configuration passed to command through -c parameters.
#
# $@: command with parameters.
# returns: the number of parameters to remove from $@ (n.b.: bad, should be status code).
#
function config_apply_parameters {
  local OPTIND

  local CONFIG_PARAMETER
  local CONFIG_KEY
  local CONFIG_VALUE

  while getopts "c:" CONFIG_PARAMETER; do
    IFS="=" read -r CONFIG_KEY CONFIG_VALUE <<< "$OPTARG"
    config_set "$CONFIG_KEY" "$CONFIG_VALUE"
  done

  return $((OPTIND - 1))
}
