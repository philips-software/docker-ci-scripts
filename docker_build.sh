#!/bin/bash

set -e

source libs/docker-build.sh

checkArguments "$@"
checkDockerOrganization "$@"
checkGitHubOrganization "$@"

getDockerFile "$@"
getImageName "$@"
getAllTags "$@"
getProjectAndCommitSHA "$@"

createTagsFile
createRepoFile

delimiter
info "Building docker image from: $dockerfilepath with name: $imagename/$basetag"
delimiter

docker build . -f "${dockerfilepath}" -t "$docker_registry_prefix"/"$imagename":"$basetag"

delimiter
for tag in "${tags[@]:1}"; do
  info "Tagging $docker_registry_prefix/$imagename:$basetag as $docker_registry_prefix/$imagename:$tag"
  docker tag "$docker_registry_prefix"/"$imagename":"$basetag" "$docker_registry_prefix"/"$imagename":"$tag"
done
delimiter
success "Finished building docker images from: $dockerfilepath"

