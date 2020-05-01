#!/bin/bash

set -e

cd "$(dirname "$0")"

# shellcheck disable=SC2153
docker_organization=$DOCKER_ORGANIZATION

if [ -z "$DOCKER_REGISTRY" ]; then
  if [ -z "$docker_organization" ]; then
    echo "  No DOCKER_ORGANIZATION set. This is mandatory when using docker.io"
    exit 1
  fi
  DOCKER_REGISTRY="docker.io"
  docker_registry_prefix="$DOCKER_REGISTRY/$docker_organization"
  echo "Docker organization: $docker_organization"
else
  docker_registry_prefix="$DOCKER_REGISTRY"
fi

echo "docker_registry_prefix: $docker_registry_prefix"

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

echo "Pushing $docker_registry_prefix/$imagename:$basetag"
docker push "$docker_registry_prefix"/"$imagename":"$basetag"

for tag in "${tags[@]:1}"
do
  echo "Pushing $docker_registry_prefix/$imagename:$tag"
  docker push "$docker_registry_prefix"/"$imagename":"$tag"
done
echo "--------------------------------------------------------------------------------------------"

echo "Update readme"
echo "--------------------------------------------------------------------------------------------"

[ "$DOCKER_REGISTRY" = "docker.io" ] && ./update_readme.sh || echo "no docker.io so no update"

echo "============================================================================================"
echo "Finished pushing docker images: $builddir"
echo "============================================================================================"
