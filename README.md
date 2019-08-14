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
Currently the preferred way of using these scripts are [Github Actions](https://github.com/features/actions).

### Github Actions
Example for Github Actions:

Make sure you set the following secrets in github:
  - DOCKER_USERNAME --> Docker hub username
  - DOCKER_PASSWORD --> Docker hub password
  - DOCKER_ORGANIZATION --> Container will be pushed in this organization. f.e. philipssoftware

Optional environment variable:
  - GITHUB_ORGANIZATION --> Github organization. defaults to DOCKER_ORGANIZATION. f.e. philips-software

`.github/workflows/build_docker.yml`:

```
on: [push]

name: Build Docker images

jobs:
  build_scala:
    name: Build scala
    runs-on: ubuntu-latest

    steps:

    - uses: actions/checkout@master
      with:
        submodules: true

    - name: Build Docker Images with node
      run: |
        export DOCKER_USERNAME=${{secrets.DOCKER_USERNAME}}
        export DOCKER_PASSWORD='${{secrets.DOCKER_PASSWORD}}'
        export DOCKER_ORGANIZATION=${{secrets.DOCKER_ORGANIZATION}}
        export GITHUB_ORGANIZATION=${{secrets.GITHUB_ORGANIZATION}}
        ./ci/bin/docker_build_and_push.sh 2/alpine scala scala:2 scala:2.13 scala:2.13.0-1.2.8-alpine
```

### Travis
When you want to use these scripts with Travis, you should use the `trabis-ci` branch of the scripts.
https://github.com/philips-software/docker-ci-scripts/tree/travis-ci

Instructions can be found in the README of that branch.


## Example projects

- [philips-software/openjdk](https://github.com/philips-software/openjdk)
- [philips-software/goss](https://github.com/philips-software/goss)
- [philips-software/bats](https://github.com/philips-software/bats)
- [philips-software/scala](https://github.com/philips-software/bats)
