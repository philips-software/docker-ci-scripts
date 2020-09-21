#!/bin/sh -l

echo "dockerfile     : $1"
echo "image name     : $2"
echo "tags           : $3"
echo "push branches  : $4"

export PUSH_BRANCHES=$4

"${FOREST_DIR}"/docker_build_and_push.sh "$1" "$2" "$3"
