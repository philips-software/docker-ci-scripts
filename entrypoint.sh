#!/bin/sh -l

echo "args 1"
echo $1

echo "args 2"
echo $2

echo "args 3"
echo $3

export PUSH_BRANCH=$3

echo "pwd"
pwd

echo "ls"
ls

cd /

docker_build_and_push.sh /github/workspace/$1 $2

