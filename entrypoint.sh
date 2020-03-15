#!/bin/sh -l

echo "directory  : $1"

echo "tags       : $2"

echo "push branch: $3"

export PUSH_BRANCH=$3

cd /
./docker_build_and_push.sh /github/workspace/"$1" "$2"

