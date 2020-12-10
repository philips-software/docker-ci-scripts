#!/bin/bash

set -e

help() {
  echo "This script requires three arguments, directory with the Docker file, Docker image name and the Docker tag."
  echo "Usages: $(basename "$0") <docker-file-directory> <docker-image-name> <tag>"
}

if [ "$#" -lt 3 ]; then
  help
  exit 1
fi

"${FOREST_DIR}"/docker_build.sh "$@"

echo "Check if we need to push the docker images to docker hub:"
# shellcheck disable=SC2153
echo "Push branches: $PUSH_BRANCHES"
echo "GITHUB_EVENT_NAME: $GITHUB_EVENT_NAME"
echo "GITHUB_REF: $GITHUB_REF"
echo "GITHUB_HEAD_REF: $GITHUB_HEAD_REF"
echo "GITHUB_BASE_REF: $GITHUB_BASE_REF"

read -ra push_branches <<< "$PUSH_BRANCHES"

for branch in "${push_branches[@]}"; do
  if [[ "$GITHUB_EVENT_NAME" = "pull_request" ]]; then
    if [[ "$GITHUB_BASE_REF" = "$branch" ]]; then
      echo "Matches: start pushing"
      "${FOREST_DIR}"/docker_push.sh "$@"
      exit 0
    fi
  else
  if [[ "$GITHUB_REF" = "refs/heads/${branch}" ]]; then
      echo "Matches: start pushing"
      "${FOREST_DIR}"/docker_push.sh "$@"
      exit 0
    fi
  fi
done

echo "No branches matched to current branch. No need to push the images to docker hub."
exit 0
