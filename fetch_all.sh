#!/usr/bin/env sh

for project in *; do
  [ -d "$project" ] && [ -d "$project/.git" ] && ./fetch.sh "$project"
done;
