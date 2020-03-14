# Docker CI scripts

This action will build a docker container from a given directory. You can give the docker container multiple tags.

You can specify for which branch it should also push it to docker hub. Default branch is `master`

Each docker container contains information about the exact context in which the container is build.

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

### `GITHUB_ORGANIZATION`

**Optional** Github organization. defaults to DOCKER_ORGANIZATION. Example: `philips-software`

In every docker container there are two files:
- `TAGS` - contains all tags associated with this container at time it was build.
- `REPO` - contains a link to the github repository with the commit sha..

## Example usage

```
uses: github.com/philips-software/docker-ci-scripts@v1
with:
  dockerfile: '12'
  tags: 'node node:12 node:12.1 node 12.1.4'
```

## Example projects

- [philips-software/docker-openjdk](https://github.com/philips-software/docker-openjdk)
- [philips-software/docker-goss](https://github.com/philips-software/docker-goss)
- [philips-software/docker-bats](https://github.com/philips-software/docker-bats)
- [philips-software/docker-scala](https://github.com/philips-software/docker-bats)
