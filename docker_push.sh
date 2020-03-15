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
alltags=$*
IFS=' '
read -ra tags <<< "$alltags"
basetag=${tags[0]}

if [ -z "$DOCKER_PASSWORD" ]; then
  echo "  No DOCKER_PASSWORD set. Please provde"
  exit 1
fi

if [ -z "$DOCKER_USERNAME" ]; then
  echo "  No DOCKER_USERNAME set. Please provde"
  exit 1
fi

echo "Login to docker"
echo "--------------------------------------------------------------------------------------------"
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

echo "Pushing $docker_organization/$basetag"
docker push "$docker_organization"/"$basetag"

for tag in "${tags[@]:1}"
do
  echo "Pushing $docker_organization/$tag"
  docker push "$docker_organization"/"$tag"
done
echo "============================================================================================"
echo "Finished pushing docker images: $builddir"
echo "============================================================================================"
