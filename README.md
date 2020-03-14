<div align="center">

# GitHub Action for creating and publishing docker images 

[![Marketplace](https://img.shields.io/badge/GitHub-Marketplace-green.svg)](https://github.com/marketplace/actions/docker-build-and-publish) [![Release](https://img.shields.io/github/release/philips-software/docker-ci-scripts.svg)](https://github.com/philips-software/docker-ci-scripts/releases)

This action will build a docker container from a given directory. You can give the docker container multiple tags.

You can specify for which branch it should also push it to docker hub. Default branch is `master`

Each docker container contains information about the exact context in which the container is build.
</div>

## Contents

- [Inputs](#inputs)
- [Environment Variables](#environment-variables)
- [Example Usage](#example-usage)
- [Example Projects](#example-projects)
- [Contributors](#contributors)
- [License](#license)

## Inputs

### `dockerfile`

**Required** Path to Dockerfile. Example: `12`

### `tags`

**Required** String with tags, separated by a space. Example: `node node:12 node:12.1`

### `push-branch`

**Optional** Specifies branch to push. Defaults to `master`

## Environment variables

These variables can be set in the github repository secret vault.

### `DOCKER_USERNAME`

**Required** Docker hub username

### `DOCKER_PASSWORD`

**Required**  Docker hub password

### `DOCKER_ORGANIZATION`

**Required** Container will be pushed in this organization. Example: `. philipssoftware`
No need to put this in GitHub Secret vault. This will be public anyway.

### `GITHUB_ORGANIZATION`

**Optional** Github organization. defaults to DOCKER_ORGANIZATION. Example: `philips-software`
No need to put this in GitHub Secret vault. This will be public anyway.

In every docker container there are two files:
- `TAGS` - contains all tags associated with this container at time it was build.
- `REPO` - contains a link to the github repository with the commit sha..

## Example usage

```
- uses: github.com/philips-software/docker-ci-scripts@v1
  with:
    dockerfile: '12'
    tags: 'node node:12 node:12.1 node 12.1.4'
  env:
    DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
    DOCKER_PASSWORD: '${{ secrets.DOCKER_PASSWORD }}'
    DOCKER_ORGANIZATION: myDockerOrganization
```

## Example projects

- [philips-software/docker-openjdk](https://github.com/philips-software/docker-openjdk)
- [philips-software/docker-goss](https://github.com/philips-software/docker-goss)
- [philips-software/docker-bats](https://github.com/philips-software/docker-bats)
- [philips-software/docker-scala](https://github.com/philips-software/docker-bats)

## Contributors

[Thanks goes to these contributors](https://github.com/philips-software/docker-ci-scripts/graphs/contributors)!

## License

[MIT License](./LICENSE)
