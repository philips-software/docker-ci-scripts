#!/bin/bash

set -e

help() {
  echo "This script requires three arguments, directory with the Docker file, Docker image name and the Docker tag."
  echo "Usages: $(basename "$0") <docker-file-directory> <docker-image-name> <base-dir> <tag>"
}

if [ "$#" -lt 4 ]; then
  help
  exit 1
fi

"${FOREST_DIR}"/docker_build.sh "$@"

echo "Check if we need to push the docker images to docker hub:"
# shellcheck disable=SC2153
echo "Push branches: $PUSH_BRANCHES"
echo "GITHUB_REF: $GITHUB_REF"

read -ra push_branches <<< "$PUSH_BRANCHES"

for branch in "${push_branches[@]}"; do
  if [[ "$GITHUB_REF" = "refs/heads/${branch}" ]]; then
    echo "Matches: start pushing"
    "${FOREST_DIR}"/docker_push.sh "$@"
    "${FOREST_DIR}"/container-digest.sh "$@"
    exit 0
  fi
done

echo "No branches matched to current branch. No need to push the images to docker hub."
exit 0

