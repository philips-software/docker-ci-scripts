#!/usr/bin/env bats

source ./libs/docker-build.sh
source ./libs/messages.sh
source ./tests/common/helpers.sh

@test "correct number of checkArguments" {
  run checkArguments arg1 arg2 arg3
  assert_success
}

@test "incorrect number of checkArguments" {
  run checkArguments arg1 arg2
  assert_failure
  [ "$output" = $(error "You need to provide a directory with a Dockerfile in it, Docker image name and one or more tags.") ]
}

@test "check setting of environment variables when using docker.io" {
  local DOCKER_ORGANIZATION="test"
  run checkDockerOrganization
  assert_success
  [ "${lines[0]}" = $(delimiter) ]
  [ "${lines[1]}" = $(info "Docker organization: test") ]
  [ "${lines[2]}" = $(info "docker_registry_prefix: docker.io/test") ]
  # TODO: test environment variables : docker organization and docker registry_prefix
}

@test "check setting of environment variables when using docker.io - missing organization" {
  run checkDockerOrganization
  assert_failure
  [ "${lines[0]}" = $(delimiter) ]
  [ "${lines[1]}" = $(error "  No DOCKER_ORGANIZATION set. This is mandatory when using docker.io") ]
}

@test "check setting of environment variables when using custom docker registry" {
  local DOCKER_REGISTRY="example.com"
  run checkDockerOrganization
  assert_success
  [ "${lines[0]}" = $(delimiter) ]
  [ "${lines[1]}" = $(info "docker_registry_prefix: example.com") ]
  # TODO: test environment variables : docker organization and docker registry_prefix
}

