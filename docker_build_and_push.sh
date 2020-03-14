#!/bin/bash

set -e

help() { 
  echo "This script requires two arguments, directory with the Docker file and the Docker tag.\n"
  echo -e "Usages: "`basename "$0"` "<docker-file-directory> <tag>"
} 

directory=`dirname "$0"`

if [ "$#" -lt 2 ]; then
  help
  exit 1
fi

./${directory}/docker_build.sh $@

echo "TODO: add git check on PUSH_BRANCH"

echo "PUSH_BRANCH: $PUSH_BRANCH"
echo "GITHUB_REF: $GITHUB_REF"

exit 1
./${directory}/docker_push.sh $@
