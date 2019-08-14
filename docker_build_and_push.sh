#!/bin/bash

set -e

help() { 
	echo "This script requires two arguments, directory with the Docker file and the DOcker tag.\n"
  echo -e "Usages: "`basename "$0"` "<docker-file-directory> <tag>"
} 

directory=`dirname "$0"`

if [ "$#" -lt 2 ]; then
  help
  exit 1
fi

./${directory}/docker_build.sh $@
./${directory}/docker_push.sh $@
