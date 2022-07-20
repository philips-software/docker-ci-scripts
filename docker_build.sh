#!/bin/bash

set -e

function expandDockerfile {
  [ -f "$1" ] && echo "$1"
  [ -f "$1/Dockerfile" ] && echo "$1/Dockerfile"
  echo
}

# Checking number of arguments

if [ "$#" -lt 4 ]; then
  echo "You need to provide a directory with a Dockerfile in it, Docker image name, the base-dir and one or more tags."
  exit 1
fi

# Checking DOCKER_ORGANIZATION environment variable

echo "--------------------------------------------------------------------------------------------"

# shellcheck disable=SC2153
docker_organization=$DOCKER_ORGANIZATION

if [ -z "$DOCKER_REGISTRY" ]; then
  if [ -z "$docker_organization" ]; then
    echo "  No DOCKER_ORGANIZATION set. This is mandatory when using docker.io"
    exit 1
  fi
  docker_registry_prefix="docker.io/$docker_organization"
  echo "Docker organization: $docker_organization"
else
  docker_registry_prefix="$DOCKER_REGISTRY"
fi

echo "docker_registry_prefix: $docker_registry_prefix"

# Checking GITHUB_ORGANIZATION environment variable

# shellcheck disable=SC2153
github_organization=$GITHUB_ORGANIZATION
if [ -z "$github_organization" ]; then
  echo "  No GITHUB_ORGANIZATION set. Using the DOCKER_ORGANIZATION ( $docker_organization ) instead."
  github_organization=$docker_organization
fi
echo "Github organization: $github_organization"
echo "--------------------------------------------------------------------------------------------"

# Checking DOCKER_BUILD_ARGS environment variable

# shellcheck disable=SC2153
docker_build_args=$DOCKER_BUILD_ARGS
if [ -z "$docker_build_args" ]; then
  echo "  No DOCKER_BUILD_ARGS provided."
else
  echo "  Using DOCKER_BUILD_ARGS=${docker_build_args}"
fi

dockerfile=$1
shift
imagename=$1
shift
basedir=$1
shift
alltags=$*

IFS=' '
read -ra tags <<<"$alltags"
basetag=${tags[0]}

echo "Switching to $basedir"
echo "--------------------------------------------------------------------------------------------"
cd "$basedir"

dockerfilepath=$(expandDockerfile "$dockerfile")

project=${GITHUB_REPOSITORY}

commitsha=${GITHUB_SHA}
if [ -z "$GITHUB_SHA" ]; then
  echo "  No GITHUB_SHA set. Try to get it myself with git."
  commitsha=$(git rev-parse --verify HEAD)
fi

echo "Building docker image from: $dockerfilepath with name: $imagename/$basetag"
echo "--------------------------------------------------------------------------------------------"

echo "tags: $alltags"
echo "$alltags" >TAGS

echo "repo: https://github.com/$project/tree/$commitsha"
echo "https://github.com/$project/tree/$commitsha" >REPO
echo $docker_build_args
docker build . -f "$dockerfilepath" -t "$docker_registry_prefix"/"$imagename":"$basetag" $docker_build_args

echo "--------------------------------------------------------------------------------------------"
for tag in "${tags[@]:1}"; do
  echo "Tagging $docker_registry_prefix/$imagename:$basetag as $docker_registry_prefix/$imagename:$tag"
  docker tag "$docker_registry_prefix"/"$imagename":"$basetag" "$docker_registry_prefix"/"$imagename":"$tag"
done
echo "============================================================================================"
echo "Finished building docker images from: $dockerfilepath"
echo "============================================================================================"
