#!/bin/bash

set -e

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

builddir=$1
shift
imagename=$1
shift
# basedir=$1 // Is not used, so why bother to capture this in a variable.
shift
alltags=$*
IFS=' '
read -ra tags <<<"$alltags"
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

docker pull "$docker_registry_prefix"/"$imagename":"$basetag"

echo "Getting digest for $docker_registry_prefix/$imagename:$basetag"
containerdigest=`docker inspect "$docker_registry_prefix"/"$imagename":"$basetag" --format '{{ index .RepoDigests 0 }}' | cut -d '@' -f 2`
echo "found: ${containerdigest}"
echo "::set-output name=container-digest::${containerdigest}"

echo "--------------------------------------------------------------------------------------------"

echo "Getting tags"
containertags=`docker inspect "$docker_registry_prefix"/"$imagename":"$basetag" --format '{{ join .RepoTags "\n" }}' | sed 's/.*://' | paste -s -d ',' -`
echo "found: ${containertags}"
echo "::set-output name=container-tags::${containertags}"

echo "============================================================================================"
echo "Finished getting docker digest and tags"
echo "============================================================================================"
