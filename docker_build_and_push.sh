#!/bin/bash

set -e

directory=`dirname "$0"`

if [ "$#" -lt 2 ]; then
  echo "You need to provide a directory with a Dockerfile in it and a tag."
  exit 1
fi

./${directory}/docker_build.sh $@
./${directory}/docker_push.sh $@
