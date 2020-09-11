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
echo "PUSH_BRANCH: $PUSH_BRANCH"
echo "GITHUB_REF: $GITHUB_REF"

if [[ "$GITHUB_REF" = "refs/heads/$PUSH_BRANCH" ]]; then
  echo "Matches: start pushing"
  "${FOREST_DIR}"/docker_push.sh "$@"
else
  echo "Do not match: $GITHUB_REF != refs/heads/$PUSH_BRANCH"
  echo "No need to push the images to docker hub."
  exit 0
fi
