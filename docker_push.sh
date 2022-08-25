#!/bin/bash

set -e

# shellcheck disable=SC2153
docker_organization=$DOCKER_ORGANIZATION

if [ -z "$REGISTRY_URL" ]; then
  if [ -z "$docker_organization" ]; then
    echo "::error::No DOCKER_ORGANIZATION set. This is mandatory when using docker.io"
    exit 1
  fi
  REGISTRY_URL="docker.io"
  registry_url_prefix="$REGISTRY_URL/$docker_organization"
  echo "Docker organization: $docker_organization"
else
  registry_url_prefix="$REGISTRY_URL"
fi

echo "registry_url_prefix: $registry_url_prefix"

if [ "$#" -lt 4 ]; then
  echo "::error::You need to provide a directory with a Dockerfile in it, Docker image name, base-dir and a tag."
  exit 1
fi

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

if [ -z "$REGISTRY_TOKEN" ]; then
  echo "::error::No REGISTRY_TOKEN set. Please provide"
  exit 1
fi

if [ -z "$REGISTRY_USERNAME" ]; then
  echo "::error::No REGISTRY_USERNAME set. Please provide"
  exit 1
fi

echo "Login to docker"
echo "--------------------------------------------------------------------------------------------"
echo "$REGISTRY_TOKEN" | docker login "$REGISTRY_URL" -u "$REGISTRY_USERNAME" --password-stdin

{
  echo '## Images pushed'
  echo ''
  echo '| Image |'
  echo '| ---- |'
  echo "| $registry_url_prefix/$imagename:$basetag |"
} >> "$GITHUB_STEP_SUMMARY"

docker push "$registry_url_prefix"/"$imagename":"$basetag"

for tag in "${tags[@]:1}"; do
  echo "| $registry_url_prefix/$imagename:$tag |" >> "$GITHUB_STEP_SUMMARY"
  docker push "$registry_url_prefix"/"$imagename":"$tag"
done
echo '' >> "$GITHUB_STEP_SUMMARY"

echo "--------------------------------------------------------------------------------------------"

echo "Update readme"
echo "--------------------------------------------------------------------------------------------"

export DOCKER_REPOSITORY="$docker_organization"/"$imagename"

[ "$REGISTRY_URL" = "docker.io" ] && "${FOREST_DIR}"/update_readme.sh || echo "no docker.io so no update"

echo "============================================================================================"
echo "Finished pushing docker images: $builddir"
echo "============================================================================================"
