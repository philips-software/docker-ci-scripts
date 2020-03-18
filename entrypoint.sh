#!/bin/sh -l

echo "directory      : $1"
echo "image name     : $2"
echo "tags           : $3"
echo "push branch    : $4"
echo "docker registry: $5"

export PUSH_BRANCH=$4

export DOCKER_REGISTRY=$5

cd /
./docker_build_and_push.sh /github/workspace/"$1" "$2" "$3"

