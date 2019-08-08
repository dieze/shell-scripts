#!/usr/bin/env bash

function help_prune_help {
  printf "kgit help prune\n"
  printf "\tShow help for prune command.\n"
}
function help_prune {
  printf "\n" && help_prune_help
  printf "\n" && prune__trash_help
  printf "\n" && prune_help
}

function prune__trash_help {
  printf "kgit config prune.trash \"bool\"\n"
  printf "\tWhether to move project directories to trash or use \"rm\" on prune.\n"
  printf "\tdefault: \"true\"\n"
}
config_set 'prune.trash' 'true'

function prune_help {
  printf "kgit [-c config=\"value\"] prune\n"
  printf "\tRemove projects directories in current directory whose repository has been removed.\n"
  printf "\tExexutes \"kgit repositories\" to search repositories to compare against projects in current directory.\n"
  printf "\tThis is a dangerous command, because if you change \"repositories.\" config values, it may suppress\n"
  printf "\tdirectories in an unwanted manner. To avoid this, kgit.interactive will be automatically set to "true"\n"
  printf "\t(unless overriden by -c).\n"
  printf "\n"
  printf '\t%s\n' "-c"
  printf "\t\tConfiguration values. Includes:\n"
  printf "\t\t\t\"git.\"\n"
  printf "\t\t\t\"kgit.\"\n"
  printf "\t\t\t\"repositories.\"\n"
}
function prune {
  printf "prune"
}

help_prune
