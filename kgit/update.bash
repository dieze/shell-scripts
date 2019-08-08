#!/usr/bin/env bash

function help_update_help {
  printf "kgit help update\n"
  printf "\tShow help for command update.\n"
}
function help_update {
  printf "\n" && help_update_help
  printf "\n" && update_help
}

function update_help {
  printf "kgit update\n"
  printf "\tUpdate all cloned repositories to latest commits.\n"
  printf "\tExecutes \"kgit repositories\" to search repositories to update in current directory.\n"
  printf "\tPulls behind branches only if fast-forward. Warns for non fast-forward.\n"
  printf "\tPulls behind branches only if working tree is clean. Warns for non clean working trees.\n"
}
function update {
  printf "update"
}

help_update
