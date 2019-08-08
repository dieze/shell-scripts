#!/bin/bash

#
# Find deployed maven project versions on PCF
#
# It expects that cf login has already been called.
# It expects that the application name matches artifactId + PCF application suffix
#
# $1 : application suffix on PCF
# $2, $3, ... : fully qualified artifact names (groupId + artifactId), without PCF application suffix
#
# example:
#
# cf login
# (choose integration, int is the application suffix "-int")
#
# ./find_deployed_version int com.organization.project1 com.organization.project2
#

dir="${BASH_SOURCE%/*}";
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi;

suffix="$1";
shift;

for group_id_artifact_id in "$@"; do
  group_id="${group_id_artifact_id%.*}";
  artifact_id="${group_id_artifact_id##*.}";

  script="$dir/find_version_in_pom.sh";

  if ! [ -f "$script" ]; then
    printf "$script could not be found\n" > /dev/stderr;
    exit 1;
  fi;

  command="
  find_deployed_version() {
    $(cat "$script";)
  }

  find_deployed_version app/META-INF/maven/${group_id}/${artifact_id}/pom.xml;
  ";

  pcf_app="${artifact_id}-${suffix}";
  printf "\n$pcf_app: ";
  echo "$command" | cf ssh "$pcf_app";
done;
