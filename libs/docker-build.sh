#!/bin/bash

source libs/messages.sh

set -e

function expandDockerfile {
  [ -f "$1" ] && echo "$1"
  [ -f "$1/Dockerfile" ] && echo "$1/Dockerfile"
  echo
}

# Checking number of arguments
function checkArguments {
  if [ "$#" -lt 3 ]; then
    error "You need to provide a directory with a Dockerfile in it, Docker image name and one or more tags."
    exit 1
  fi
}

function checkDockerOrganization {
  # Checking DOCKER_ORGANIZATION environment variable
  delimiter

  # shellcheck disable=SC2153
  export docker_organization=$DOCKER_ORGANIZATION

  if [ -z "$DOCKER_REGISTRY" ]; then
    if [ -z "$docker_organization" ]; then
      error "  No DOCKER_ORGANIZATION set. This is mandatory when using docker.io"
      exit 1
    fi
    docker_registry_prefix="docker.io/$docker_organization"
    info "Docker organization: $docker_organization"
  else
    docker_registry_prefix="$DOCKER_REGISTRY"
  fi

  info "docker_registry_prefix: $docker_registry_prefix"

  export docker_registry_prefix
}

function checkGitHubOrganization {
  # Checking GITHUB_ORGANIZATION environment variable
  # shellcheck disable=SC2153
  github_organization=$GITHUB_ORGANIZATION
  if [ -z "$github_organization" ]; then
    warn "  No GITHUB_ORGANIZATION set. Using the DOCKER_ORGANIZATION ( $docker_organization ) instead."
    github_organization=$docker_organization
  fi
  info "Github organization: $github_organization"
  delimiter 

  export github_organization
}

function getDockerFile {
  export dockerfile=$1
  dockerfilepath=$(expandDockerfile "$dockerfile")
  export dockerfilepath
}

function getImageName {
  export imagename=$2
}

function getAllTags {
  shift
  shift
  export alltags=$*
  IFS=' '
  read -ra tags <<<"$alltags"
  export basetag=${tags[0]}
}

function getProjectAndCommitSHA {
  project=${GITHUB_REPOSITORY}
  if [ -z "$GITHUB_REPOSITORY" ]; then
    warn "No GITHUB_REPOSITORY, so I will get it from the remote."
    # shellcheck disable=SC2016 
    project=$(git remote show origin -n | ruby -ne 'puts /^\s*Fetch.*:(.*).git/.match($_)[1] rescue nil')
  fi

  info "project: $project"

  export project

  commitsha=${GITHUB_SHA}
  if [ -z "$GITHUB_SHA" ]; then
    warn "No GITHUB_SHA set. Try to get it myself with git."
    commitsha=$(git rev-parse --verify HEAD)
  fi

  export commitsha
}

function createTagsFile {
  info "tags: $alltags"
  echo "$alltags" >TAGS
}

function createRepoFile {
  info "repo: https://github.com/$project/tree/$commitsha"
  echo "https://github.com/$project/tree/$commitsha" >REPO
}
