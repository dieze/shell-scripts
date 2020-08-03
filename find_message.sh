#!/usr/bin/env bash

#
# Initially copied from:
# https://gist.github.com/helhum/2b2078901f040622b403
#
# Modified by Adrien Desfourneaux
#

help() {
  cat <<EOF

USAGE:
        $0 [<options>] 'pattern1' ['pattern2'] ...

DESCRIPTION:
        Search remote branches and tags containing a commit whose description
        matches at least one of the supplied patterns.

        Issue a "git fetch --prune --prune-tags --tags" by default to synchronize
        remote branches and tags. Use option --no-fetch to prevent this.

EXAMPLE:
        $0 'NBD[-_\\s]*687' 'NCEV[-_\\s]*6385'

        $0 --pattern-type=fixed NBD-687 NCEV-6385

        $0 --pattern-type=fixed "[TECH] Add new services provider"

OPTIONS:
        --help
            Show this help and exit with success return code.

        --no-fetch
            Don't synchronize with the remote, i.e. do not fetch for newer commits and tags,
            and don't prune remote branches and tags that are not effectively present on remote
            ("git fetch --prune" for branches and tags).

        --all-match
            Limit the commits to ones that match all given patterns, instead of ones that match at least one.

        -i, --regexp-ignore-case
            Match the regular expression limiting patterns without regard to letter case.

        --pattern-type=<type>
            Type of pattern used. Can be "basic", "extended", "fixed", or "perl". Defaults to "extended".

ADVICES:
        This command accepts extended regexp by default, so some characters such as '[' and ']'
        will be interpreted as regular expressions. To match plain '[' it must be escaped, i.e. '\\['.
        Single-quotes should be used instead of double quotes, otherwise '[' must be escaped twice, i.e. "\\\\[".

KNOWN BUGS:
        For a specific commit, if the number of tags to display is higher than the number of branches to display,
        then only the oldest tags will be printed until there are no more vertical space for tags.

EOF
}

[ $# -eq 0 ] && { help; exit 0; }

# grep.extendedRegexp is ignored when --basic-regex, --extended-regexp, ... are used (--pattern-type option of this script)
#
# --oneline is very important: it contains --abbrev-commit for commits to be 9 characters long
# 10 characters are usually removed from lines on variables (see "remove_commit_prefix()" below)
#
cmd=(git -c grep.extendedRegexp=true log --oneline --all --no-merges)

#
# $1 or stdin: line with commit prefix (9 characters long) followed by a space.
# $1 has precedence.
#
# example:
#
# 240f44f67 branch1 branch2 branch3
#
# will output:
#
# branch1 branch2 branch3
#
remove_commit_prefix() {
  line="$1"
  [ -z "$line" ] && line="$(</dev/stdin)"
  printf "${line:10}"
}

pattern_type() {
  case "$1" in
    "basic") printf '%s' "--basic-regexp";;
    "extended") printf '%s' "--extended-regexp";;
    "fixed") printf '%s' "--fixed-strings";;
    "perl") printf '%s' "--perl-regexp";;
    *) printf "invalid --pattern-type ; expected one of \"basic\", \"extended\", \"fixed\", \"perl\" but was \"$1\"\n" >&2; exit 1;
  esac
}

while ! [ $# -eq 0 ]; do
  [ "$1" = "--help" ] && { help; exit 0; }
  [ "$1" = "--no-fetch" ] && { no_fetch=true; shift; continue; }
  [ "$1" = "--all-match" ] && { cmd+=(--all-match); shift; continue; }
  { [ "$1" = "-i" ] || [ "$1" = "--regexp-ignore-case" ]; } && { cmd+=(--regexp-ignore-case); shift; continue; }
  [[ $1 =~ ^--pattern-type=(.*) ]] && { cmd+=($(pattern_type ${BASH_REMATCH[1]})) || exit $?; shift; continue; }
  [[ $1 =~ ^--.* ]] && { printf "fatal: unsupported option \"${BASH_REMATCH[0]}\"\n" >&2; exit 1; }
  cmd+=(--grep "$1"); shift
done

[ -z "$no_fetch" ] && { git fetch --prune --tags; git fetch --prune origin "refs/tags/*:refs/tags/*"; }
commit_messages="$("${cmd[@]}")"
commits="$(cut -d" " -f 1 <<< "$commit_messages")"

# sha1 AIC-1234 KCA-5678 AICRB-13 ...
commit_tickets="$(
  while read commit; do
    printf '%s%s\n' "$commit" "$(
      git show --pretty='tformat:%s' --no-patch "$commit" | tr ' ' '\n' | tr [:lower:] [:upper:] | grep --only-matching --extended-regexp -e '[A-Z]{1,5}[-_ ]\d+' -e 'TECH' | sort --version-sort --unique | tr '\n' ' ' | sed -E -e 's/^([^ ])/ \1/' -e 's/ $//'
    )"
  done <<< "$commits"
)"

#
# stdin: string
#
no_color() {
  sed $'s/\\\e\\[[0-9;]*m//g'
}

commit_branches="$(
  while read commit; do
    printf '%s%s\n' "$commit" "$(
      {
        branches="$(</dev/stdin)"
        while read branch; do
          grep '^\x1b\[31m' <<< "$branch" > /dev/null && { printf "$branch\n"; continue; } # remote branch in red is always printed
          grep '^\x1b\[32m' <<< "$branch" > /dev/null && { grep "^\\x1b\\[31m$(no_color <<< "$branch")" <<< "$branches" > /dev/null || printf "$branch\n"; continue; } # current branch in green is printed only if there is no remote branch with same name
          grep "^\\x1b\\[31m$(no_color <<< "$branch")" <<< "$branches" > /dev/null || printf "$branch\n" # local branch (no color) is printed only if there is no remote branch with same name
        done <<< "$branches"
      } < <(git -c color.ui=always branch --all --contains "$commit" |
        grep --invert-match --fixed-strings ' -> ' |                               # filter symbolic remote ref HEAD
        grep --invert-match --basic-regexp $'^* \\\e\\[32m(' |                     # filter "* (HEAD detached at ...)"
        sed -e 's/^  //' -e 's/^* //' |                                            # remove indent, remove "*" indicating current checked out branch
        sed -e $'s#^\\\e\\[31mremotes/#\e[31m#' -e $'s#^\\\e\\[31morigin/#\e[31m#' # remove "remotes/" and "remotes/origin" ; any remote other than "origin" is kept for clarity to end user
      ) |
        sort --ignore-case |
        tr '\n' ' ' | sed -E -e 's/^([^ ])/ \1/' -e 's/ $//' # leading space required by '%s%s\n' format ; remove trailing space from tr '\n' ' '
    )"
  done <<< "$commits"
)"

#
# For use only by $commit_tags because of the trailing space in printf format.
#
# $1: version
#
print_version() {
  printf '%s%s%s ' $'\e[1;33m' "$1" $'\e[m'
}

commit_tags="$(
  while read commit; do
    printf '%s%s\n' "$commit" "$(
      while read version; do
        IFS='.-' read -a major_minor_patch_suffix <<< "$version"
        next=
        [ -z "$next" ] && [ -z "$prev_major_minor_patch_suffix" ] && { print_version "$version"; next="next"; } # always print first version
        [ -z "$next" ] && [ -n "${major_minor_patch_suffix[4]}" ] && { print_version "$version"; next="next"; } # always print versions that have a suffix
        [ -z "$next" ] && [ "${#prev_major_minor_patch_suffix[@]}" -lt 3 -o "${#major_minor_patch_suffix[@]}" -lt 3 ] && { print_version "$version"; next="next"; } # version without at least 3 digits cannot be compared and is printed
        [ -z "$next" ] && [ "${major_minor_patch_suffix[0]}" -gt "${prev_major_minor_patch_suffix[0]}" ] && { print_version "$version"; next="next"; } # changing major: 1.x.x[-SUFFIX] => 2.x.x[-SUFFIX]
        [ -z "$next" ] && [ "${major_minor_patch_suffix[1]}" -gt "${prev_major_minor_patch_suffix[1]}" ] && { print_version "$version"; next="next"; } # changing minor: 1.1.x[-SUFFIX] => 1.2.x[-SUFFIX]
        # changing minor is ignored: only first minor is printed
        prev_major_minor_patch_suffix=("${major_minor_patch_suffix[@]}")
      done < <(git tag --contains "$commit" | sort --version-sort) | sed -E -e 's/^([^ ])/ \1/' -e 's/ $//'
    )"
  done <<< "$commits"
)"

#
# Determine max length (number of characters) of multiple lines after removing color.
#
# stdin: lines
#
max_length() {
  no_color | awk '{print length}' | sort --numeric-sort --reverse | head -n 1
}

#
# Draw final table with indented columns.
#
while read commit; do
  #
  # commit message tickets
  #
  printf '%s\t%s\t%s\n' \
    "$commit" \
    "$(grep "^$commit " <<< "$commit_messages" | remove_commit_prefix)" \
    "$(grep "^$commit " <<< "$commit_tickets" | remove_commit_prefix)"
done <<< "$commits" | column -ts $'\t' | {
  #
  # ... branch1[\n][indent]branch2
  #
  lines="$(</dev/stdin)"
  indent="$(($(max_length <<< "$lines") + 2))" # 2 spaces columns separator

  while read line; do
    commit="$(cut -d ' ' -f 1 <<< "$line")"
    branches="$(grep "^$commit " <<< "$commit_branches" | remove_commit_prefix)"
    [ -z "$branches" ] && { printf "$line\n"; continue; }
    first_branch="$(cut -d ' ' -f 1 <<< "$branches")"
    branches="${branches#"$first_branch"}"
    branches="${branches#" "}"

    printf "%s%$(($indent - $(max_length <<< "$line")))s%s" "$line" "" "$first_branch"

    while read -d ' ' branch; do
      printf "$(printf "\n%${indent}s%s" "" "$branch")"
    done <<< "$branches " # trailing space required for read -d ' ' to have return code 0 for while

    printf "\n"
  done <<< "$lines"
} | {
  #
  # ... tag1[\n][indent]tag2
  #
  lines="$(</dev/stdin)"
  indent="$(($(max_length <<< "$lines") + 2))" # 2 spaces columns separator

  while IFS=$'\n' read line; do
    [[ $line =~ ^[a-z0-9]+ ]] && {
      commit="${BASH_REMATCH[0]}"
      tags="$(grep "^$commit " <<< "$commit_tags" | remove_commit_prefix)"
    }

    read -d ' ' tag <<< "$tags"
    tags="${tags#"$tag"}"
    tags="${tags#" "}"

    printf "%s%$(($indent - $([ -z "$tag" ] && printf "$indent" || max_length <<< "$line")))s%s\n" "$line" "" "$tag"
  done <<< "$lines"
}
