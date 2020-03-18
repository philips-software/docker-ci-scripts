#!/bin/bash

set -e

currentdir=$(pwd)

cd "$(dirname "$0")"

# Checking number of arguments

if [ "$#" -lt 3 ]; then
  echo "You need to provide a directory with a Dockerfile in it, Docker image name and one or more tags."
  exit 1
fi

# Checking DOCKER_ORGANIZATION environment variable 

echo "--------------------------------------------------------------------------------------------"

# shellcheck disable=SC2153
docker_organization=$DOCKER_ORGANIZATION
if [ -z "$docker_organization" ]; then
  echo "  No DOCKER_ORGANIZATION set. Please provide"
  exit 1
fi
echo "Docker organization: $docker_organization"

# Checking GITHUB_ORGANIZATION environment variable

# shellcheck disable=SC2153
github_organization=$GITHUB_ORGANIZATION
if [ -z "$github_organization" ]; then
  echo "  No GITHUB_ORGANIZATION set. Using the DOCKER_ORGANIZATION ( $docker_organization ) instead."
  github_organization=$docker_organization
fi
echo "Github organization: $github_organization"
echo "--------------------------------------------------------------------------------------------"

builddir=$1
shift
imagename=$1
shift
alltags=$*
IFS=' '
read -ra tags <<< "$alltags"
basetag=${tags[0]}

project=$(basename "$currentdir")

commitsha=${GITHUB_SHA}
if [ -z "$GITHUB_SHA" ]; then
  echo "  No GITHUB_SHA set. Try to get it myself with git."
  commitsha=$(git rev-parse --verify HEAD)
fi

cd "$builddir"

echo "Building docker image: $builddir with name: $imagename/$basetag"
echo "--------------------------------------------------------------------------------------------"

echo "$alltags" > TAGS
echo "https://github.com/$github_organization/$project/tree/$commitsha" > REPO

docker build . -t "$DOCKER_REGISTRY"/"$docker_organization"/"$imagename":"$basetag"

echo "--------------------------------------------------------------------------------------------"
for tag in "${tags[@]:1}"
do
  echo "Tagging $DOCKER_REGISTRY/$docker_organization/$imagename:$basetag as $DOCKER_REGISTRY/$docker_organization/$imagename:$tag"
  docker tag "$DOCKER_REGISTRY"/"$docker_organization"/"$imagename":"$basetag" "$DOCKER_REGISTRY"/"$docker_organization"/"$imagename":"$tag"
done
echo "============================================================================================"
echo "Finished building docker images: $builddir"
echo "============================================================================================"
