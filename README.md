<div align="center">

# GitHub Action for creating and publishing docker images 

[![Marketplace](https://img.shields.io/badge/GitHub-Marketplace-green.svg)](https://github.com/marketplace/actions/docker-build-and-publish) [![Release](https://img.shields.io/github/release/philips-software/docker-ci-scripts.svg)](https://github.com/philips-software/docker-ci-scripts/releases)

This action will build a docker container from a given directory. 
</div>

- You can give the docker container multiple tags.
- You can specify for which branch it should push it a docker registry ( `docker.io` by default ). 
- Each docker container contains information about the exact context in which the container is build.
- When pushing to docker.io, the description is updated with the `readme.md` file.

## Contents

* [Description](#description)
* [Inputs](#inputs)
* [Environment Variables](#environment-variables)
* [Outputs](#outputs)
* [Runs](#runs)
* [Example Usage](#example-usage)
* [Example Projects](#example-projects)
* [Contributors](#contributors)
* [License](#license)

<!-- action-docs-description -->
## Description

Builds docker images and publish them on request


<!-- action-docs-description -->
<!-- action-docs-inputs -->
## Inputs

| parameter | description | required | default |
| - | - | - | - |
| dockerfile | Path to Dockerfile | `true` |  |
| image-name | The name of the image | `true` |  |
| tags | String with tags, separated by a space | `true` |  |
| push-branch | Specifies branch to push, separated by a space - DEPRECATED - Will be replaced by push-branches | `false` |  |
| push-branches | Specifies branches to push, separated by a space | `false` | master main |
| base-dir | Base directory to perform the build | `false` | . |



<!-- action-docs-inputs -->

## Environment variables

These variables can be set in the github repository secret vault.

### `DOCKER_USERNAME` 

**Required** Docker username

### `DOCKER_PASSWORD` 

**Required**  Docker password

### `DOCKER_REGISTRY` 

**Optional** Registry to push the docker image to. Defaults to Docker hub.

### `DOCKER_ORGANIZATION` 

**Required for Docker hub** Container will be pushed in this organization. Example: `philipssoftware`
No need to put this in GitHub Secret vault. This will be public anyway.

### `GITHUB_ORGANIZATION` 

**Optional** Github organization. Defaults to DOCKER_ORGANIZATION. Example: `philips-software` 
No need to put this in GitHub Secret vault. This will be public anyway.

In every docker container there are two files:

* `TAGS` - contains all tags associated with this container at time it was build.
* `REPO` - contains a link to the github repository with the commit sha.

<!-- action-docs-outputs -->
## Outputs

| parameter | description |
| - | - |
| container-digest | Container digest. Can be used for generating provenance and signing. |
| container-tags | Container tags. Can be used for generating provenance and signing. |
| push-indicator | Is set to true when containers have been pushed to the container repository |



<!-- action-docs-outputs -->
<!-- action-docs-runs -->
## Runs

This action is an `docker` action.


<!-- action-docs-runs -->

## Example usage

``` 
- uses: philips-software/docker-ci-scripts@v3.0.0
  with:
    dockerfile: './docker/Dockerfile'
    image-name: 'node'
    tags: 'latest 12 12.1 12.1.4'
  env:
    DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
    DOCKER_PASSWORD: '${{ secrets.DOCKER_PASSWORD }}'
    DOCKER_ORGANIZATION: myDockerOrganization
```

#### With GitHub Package registry:

```
      - name: Build Docker Images
        uses: philips-software/docker-ci-scripts@v3.3.2
        with:
          dockerfile: .
          image-name: image-name-here
          tags: latest 0.1
          push-branches: main develop
        env:
          DOCKER_USERNAME: ${{ github.actor }}
          DOCKER_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
          DOCKER_REGISTRY: ghcr.io/organization-here
          GITHUB_ORGANIZATION: organization-here
```

## Example projects

* [philips-software/docker-openjdk](https://github.com/philips-software/docker-openjdk)
* [philips-software/docker-goss](https://github.com/philips-software/docker-goss)
* [philips-software/docker-bats](https://github.com/philips-software/docker-bats)
* [philips-software/docker-scala](https://github.com/philips-software/docker-scala)

## Breaking changes v3.0.0

The `docker build` command is now being called from the root of the project
instead of the directory. 

This has impact when your project has these two things:
- Directories with dockerfiles
- The dockerfile contains an `ADD` or a `COPY` command.

You now need to change the path to include the directory.

Example:
- `ADD /scripts/entrypoint.sh entrypoint.sh` becomes: `ADD /6/java/scripts/entrypoint.sh entrypoint` 

## Contributors

[Thanks goes to these contributors](https://github.com/philips-software/docker-ci-scripts/graphs/contributors)!

## License

[MIT License](./LICENSE)

