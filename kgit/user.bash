#!/usr/bin/env bash

function help_user_help {
  printf "kgit help user\n"
  printf "\tShow help for user command\n"
}
function help_user {
  printf "\n" && help_user_help
  printf "\n" && user_login_help
}

function user_login_help {
  printf "kgit user --login\n"
  printf "\tLogin user to GitHub.\n"
}
function user_login {
  gh user --login
}
