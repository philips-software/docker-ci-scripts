#!/bin/bash

set -e

currentdir=$(pwd)

cd "$(dirname "$0")"

# Checking number of arguments

if [ "$#" -lt 2 ]; then
  echo "You need to provide a directory with a Dockerfile in it and one or more tags."
  exit 1
fi

# Checking DOCKER_ORGANIZATION environment variable 

echo "-------------------------------------------------------------------------------------------"

# shellcheck disable=SC2153
docker_organization=$DOCKER_ORGANIZATION
if [ -z "$docker_organization" ]; then
  echo "  No DOCKER_ORGANIZATION set. Please provde"
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
echo "-------------------------------------------------------------------------------------------"

builddir=$1
shift
basetag=$1
alltags=$*

project=$(basename "$currentdir")

commitsha=${GITHUB_SHA}
if [ -z "$GITHUB_SHA" ]; then
  echo "  No GITHUB_SHA set. Try to get it myself with git."
  commitsha=$(git rev-parse --verify HEAD)
fi

cd "$builddir"

echo "Building docker image: $builddir with tag: $basetag"
echo "-------------------------------------------------------------------------------------------"

echo "$alltags" > TAGS
echo "https://github.com/$github_organization/$project/tree/$commitsha" > REPO

docker build . -t "$docker_organization"/"$basetag"

echo "-------------------------------------------------------------------------------------------"
while test ${#} -gt 0
do
  echo "Tagging $docker_organization/$basetag as $docker_organization/$1"
  docker tag "$docker_organization"/"$basetag" "$docker_organization"/"$1"
  shift
done
echo "============================================================================================"
echo "Finished building docker images: $builddir"
echo "============================================================================================"
