# docker-ci-scripts
Docker CI scripts

## Purpose

## Content

```
.
├── docker_build.sh
├── docker_build_and_push.sh
└── docker_push.sh
```

`docker_build.sh` - builds docker container in the given directory and tags container as given as extra parameters
`docker_build_and_push.sh` - builds and pushes the dockers
`docker_push.sh` - pushes the docker containers

## Usage

### Include scripts in repo

Include the scripts as submodule in your project:
```
git submodule add -b master https://github.com/philips-software/docker-ci-scripts.git ci/bin 
```

## Use the scripts in your CI 

This is an example how you can use the scripts in your CI/CD system. 
There are several CI/CD systems available. We start with instructions on [Travis CI](https://travis-ci.org/).

### Travis
Example for Travis:

`.travis.yml`:
```
language:
  - bash

services:
  - docker

sudo: true

jobs:
  include:
    - stage: build
      script: ./ci/bin/docker_build_and_push.sh 11/jdk/slim-aws openjdk:11-aws openjdk:11-jdk-aws openjdk:11-jdk-slim-aws openjdk:11.0.2-jdk-slim-aws
```

## Example projects

- [philips-software/openjdk](https://github.com/philips-software/openjdk)
- [philips-software/goss](https://github.com/philips-software/goss)
- [philips-software/bats](https://github.com/philips-software/bats)
- [philips-software/scala](https://github.com/philips-software/bats)
