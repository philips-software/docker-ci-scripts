#!/bin/bash

set -e

cd "$(dirname "$0")"

# shellcheck disable=SC2153
docker_organization=$DOCKER_ORGANIZATION

if [ "$#" -lt 3 ]; then
  echo "You need to provide a directory with a Dockerfile in it, Docker image name and a tag."
  exit 1
fi

builddir=$1
shift
imagename=$1
shift
alltags=$*
IFS=' '
read -ra tags <<< "$alltags"
basetag=${tags[0]}

if [ -z "$DOCKER_PASSWORD" ]; then
  echo "  No DOCKER_PASSWORD set. Please provide"
  exit 1
fi

if [ -z "$DOCKER_USERNAME" ]; then
  echo "  No DOCKER_USERNAME set. Please provide"
  exit 1
fi

echo "Login to docker"
echo "--------------------------------------------------------------------------------------------"
echo "$DOCKER_PASSWORD" | docker login "$DOCKER_REGISTRY" -u "$DOCKER_USERNAME" --password-stdin
 
echo "Pushing $DOCKER_REGISTRY/$docker_organization/$imagename:$basetag"
docker push "$DOCKER_REGISTRY"/"$docker_organization"/"$imagename":"$basetag"

for tag in "${tags[@]:1}"
do
  echo "Pushing $DOCKER_REGISTRY/$docker_organization/$imagename:$tag"
  docker push "$DOCKER_REGISTRY"/"$docker_organization"/"$imagename":"$tag"
done
echo "============================================================================================"
echo "Finished pushing docker images: $builddir"
echo "============================================================================================"
