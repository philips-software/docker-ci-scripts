#!/bin/sh -l

echo "directory      : $1"

echo "tags           : $2"

echo "push branch    : $3"

echo "docker registry: $4"

export PUSH_BRANCH=$3

export DOCKER_REGISTRY=$4

cd /
./docker_build_and_push.sh /github/workspace/"$1" "$2"

