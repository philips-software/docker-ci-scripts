#!/bin/bash

set -e

cd "$(dirname "$0")"

# shellcheck disable=SC2153
docker_organization=$DOCKER_ORGANIZATION

if [ "$#" -lt 2 ]; then
  echo "You need to provide a directory with a Dockerfile in it and a tag."
  exit 1
fi

builddir=$1
shift
basetag=$1
shift


if [ -z "$DOCKER_PASSWORD" ]; then
  echo "  No DOCKER_PASSWORD set. Please provde"
  exit 1
fi

if [ -z "$DOCKER_USERNAME" ]; then
  echo "  No DOCKER_USERNAME set. Please provde"
  exit 1
fi

echo "Login to docker"
echo "-------------------------------------------------------------------------"
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

echo "Pushing $docker_organization/$basetag"
docker push "$docker_organization"/"$basetag"

while test ${#} -gt 0
do
  echo "Pushing $docker_organization/$1"
  docker push "$docker_organization"/"$1"
  shift
done
echo "============================================================================================"
echo "Finished pushing docker images: $builddir"
echo "============================================================================================"
