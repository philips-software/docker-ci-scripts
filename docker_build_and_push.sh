#!/bin/bash

cd `dirname "$0"`

if [ "$#" -lt 2 ]; then
  echo "You need to provide a directory with a Dockerfile in it and a tag."
  exit 1
fi

./docker_build.sh $@
./docker_push.sh $@
