rm_target_directory=false;

if [ "$1" == "--rm-target-directory" ]; then
  rm_target_directory=true; # global variable
  shift;
fi;

target_branch_or_tag="$1";
fallback_target_branch_or_tag="$2";

if [ -z "$target_branch_or_tag" ]; then
    printf "\nusage: $0 [--rm-target-directory] target_branch_or_tag [fallback_target_branch_or_tag]\n" 1>&2;
    printf "\n";
    printf "[--rm-target-directory]\n";
    printf "\tIf the option --rm-target-directory is used, java generated target/ directory\n";
    printf "\twill be removed if present after successful checkout.\n";
    printf "\n";
    printf "target_branch_or_tag\n";
    printf "\tRequired target branch or tag to checkout to.\n";
    printf "\n";
    printf "[fallback_target_branch_or_tag]\n";
    printf "\tOptional fallback target branch or tag to checkout to if target_branch_or_tag\n";
    printf "\tdoes not exist on the git repository.\n";
    printf "\n";
    exit 1;
fi;

#
# Checkout to target branch or tag, and may remove java target/ directory
#
# $1: target branch or tag
#
# uses global variable $rm_target_directory
#
# returns  0: already on target branch or tag, or succeeded to checkout
#         -1: cannot checkout, and further checkout will fail anyway whatever the target branch or tag
#          1: cannot checkout, but checkout to another branch or tag may succeed
#
checkout_and_may_remove_target_directory() {
  local target_branch_or_tag="$1";

  if [ -n "$(git branch --list "$target_branch_or_tag")" ] || [ -n "$(git branch --all --list "*/$target_branch_or_tag" | grep -E "^[[:space:]][[:space:]]remotes/[^\/]+?\/$target_branch_or_tag$")" ] || [ -n "$(git tag --list "$target_branch_or_tag")" ]; then
    if [ "$(git branch | grep -E '^\*' | cut -d ' ' -f2)" != "$target_branch_or_tag" ] || [ "$(git describe --tags --exact-match 2> /dev/null)" != "$target_branch_or_tag" ]; then
      if [ -z "$(git status --porcelain)" ]; then
        git checkout --quiet "$target_branch_or_tag";

        if [ $? -eq 0 ] && [ "$rm_target_directory" == "true" ] && [ -d "target" ]; then
          rm -r target/ && printf "\e[33mremoved $(pwd)/target/\e[0m\n" 1>&2
        fi;

        return 0;
      else
        printf "\e[33mhas uncommited changes\e[0m\n" 1>&2;
        return -1;
      fi;
    fi;
  else
    printf "\e[33mdoesn't have $target_branch_or_tag\e[0m\n" 1>&2;
    return 1;
  fi;
}

for project in *; do
  if [ -d "$project" ]; then
    (
      cd "$project";

      if [ -d ".git" ]; then
        printf "\n\e[1m$project\e[0m\n";

        checkout_and_may_remove_target_directory $target_branch_or_tag;
        if [ $? -eq 1 ] && [ ! -z "$fallback_target_branch_or_tag" ]; then
          checkout_and_may_remove_target_directory $fallback_target_branch_or_tag;
        fi;

        label="$(git branch | grep -E '^\*' | grep -E -v '^\* \(HEAD detached at .*\)$' | cut -d ' ' -f2)";

        if [ -z "$label" ]; then
          label="$(git describe --tags --exact-match)";
        fi;

        printf "\e[92m$label\e[0m\n";
      fi;
    );
  fi;
done;
