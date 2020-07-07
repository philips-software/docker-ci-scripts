#!/bin/sh -l

echo "directory      : $1"
echo "image name     : $2"
echo "tags           : $3"
echo "push branch    : $4"

export PUSH_BRANCH=$4

${FOREST_DIR}/docker_build_and_push.sh "$1" "$2" "$3"
