#!/usr/bin/env bash

#
# Find the project version in pom.xml
#
# $1: path to pom.xml
#

read_dom() {
  local IFS=\>
  read -d \< entity content
}

is_project_entity=true
level=0
previous_entity=

while read_dom; do
  if [ -z "$entity" ] && [ -z "$content" ]; then
    # first iteration
    continue
  fi

  if [[ "$entity" =~ ^\?xml ]]; then
    # <?xml header
    continue
  fi

  if [[ "$entity" =~ ^!-- ]]; then
    # xml comment
    continue
  fi

  if [[ "$entity" =~ \/$ ]]; then
    # self-closing entity
    continue
  fi

  if [[ "$entity" =~ ^\/ ]]; then
    if [ -z "$previous_entity" ]; then
      echo "Invalid xml: document starts with a closing tag $entity" > /dev/stderr
      exit 2
    fi

    if ! [[ "$previous_entity" =~ ^\/ ]] && ! [[ "$entity" =~ /$previous_entity ]]; then
      echo "Invalid xml: non matching entities: $previous_entity, $entity" > /dev/stderr
      exit 3
    fi

    level=$((level-1))
  else
    level=$((level+1))
  fi

  if [ "$entity" = "version" ] && [ "$level" -eq 2 ]; then
    # level = 1: inside <project>
    # level = 2; inside <version>
    printf "$content"
    exit 0
  fi

  previous_entity="$entity"
done < "$1"

echo "Could not find artifact version" > /dev/stderr
exit 1
