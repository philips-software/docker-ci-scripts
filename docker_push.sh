#!/bin/bash

cd `dirname "$0"`

if [ "$#" -lt 2 ]; then
  echo "You need to provide a directory with a Dockerfile in it and a tag."
  exit 1
fi

builddir=$1
shift
basetag=$1
shift
tags=$@

echo "Login to docker"
echo "-------------------------------------------------------------------------"
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

cd $builddir

echo "Pushing philipssoftware/$basetag"
docker push philipssoftware/$basetag

while test ${#} -gt 0
do
  echo "Pushing philipssoftware/$1"
  docker push philipssoftware/$1
  shift
done
echo "============================================================================================"
echo "Finished pushing docker images: $builddir"
echo "============================================================================================"


