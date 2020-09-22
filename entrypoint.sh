#!/bin/sh -l

echo "dockerfile     : $1"
echo "image name     : $2"
echo "tags           : $3"
echo "push branches  : $4"
echo "push branch    : $5"

if [ -z "$5" ]
  then
    export PUSH_BRANCHES="$4"
  else
    echo "DEPRECATION WARNING: push-branch will be replaced by push-branches"
    export PUSH_BRANCHES="$5"
fi

"${FOREST_DIR}"/docker_build_and_push.sh "$1" "$2" "$3"
