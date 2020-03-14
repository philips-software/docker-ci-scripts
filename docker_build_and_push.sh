#!/bin/bash

set -e

help() { 
  echo "This script requires two arguments, directory with the Docker file and the Docker tag.\n"
  echo -e "Usages: "`basename "$0"` "<docker-file-directory> <tag>"
} 

if [ "$#" -lt 2 ]; then
  help
  exit 1
fi

./docker_build.sh $@

echo "PUSH_BRANCH: $PUSH_BRANCH"
echo "GITHUB_REF: $GITHUB_REF"

if [[ "$GITHUB_REF" = "refs/heads/$PUSH_BRANCH" ]]
then
    echo "Matches"
    echo "run docker_push"
    ./docker_push.sh $@
else
    echo "Do not match: $GITHUB_REF != refs/heads/$PUSH_BRANCH"
    exit 0
fi

