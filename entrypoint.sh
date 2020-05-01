#!/bin/sh -l

echo "directory      : $1"
echo "image name     : $2"
echo "tags           : $3"
echo "push branch    : $4"

export PUSH_BRANCH=$4

cd /
./docker_build_and_push.sh /github/workspace/"$1" "$2" "$3"

