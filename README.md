<div align="center">

# GitHub Action for creating and publishing docker images

[![Marketplace](https://img.shields.io/badge/GitHub-Marketplace-green.svg)](https://github.com/marketplace/actions/docker-build-and-publish) [![Release](https://img.shields.io/github/release/philips-software/docker-ci-scripts.svg)](https://github.com/philips-software/docker-ci-scripts/releases)

This action will build a docker image from a given directory.
</div>

- You can give a docker image multiple tags.
- You can specify for which branch it should push to a docker registry ( `docker.io` by default ).
- Each docker image contains information about the exact context in which the image is build.
- When pushing to docker.io, the description is updated with the `readme.md` file.
- If required, the image is signed with [cosign](https://github.com/sigstore/cosign).
- If required, a provenance file is created according to the [SLSA.dev](https://slsa.dev) specifications.
- If required, the provenance file is attached to the container.
- If required, a SBOM file is created according to the [SPDX](https://spdx.dev) specifications. We're using [VMWare Tern](https://github.com/tern-tools/tern) for that. (very slow at the moment)
- If required, the SBOM file is attached to the container.

In every docker image two files are added to the build context:
* `TAGS` - contains all tags associated with the image at time it was build.
* `REPO` - contains a link to the github repository with the commit sha.

This information can also be found in the provenance file. Using the provenance file is more secure,
because you don't need to download and run the image in order to get the information.

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
| slsa-provenance | Create SLSA Provenance json | `false` |  |
| sbom | Create Software Bill Of Material in SPDX format | `false` |  |
| sign | Sign image with Cosign. Requires COSIGN environment variables to be set. When used in combination with slsa-provenance / sbom it will also attach the results to the image. | `false` |  |
| github_context | internal (do not set): the "github" context object in json | `true` | ${{ toJSON(github) }} |
| runner_context | internal (do not set): the "runner" context object in json | `true` | ${{ toJSON(runner) }} |



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

### `COSIGN_PRIVATE_KEY`

**Optional** Cosign Private Key used to attach provenance file.
Please make sure this is a GitHub Secret.

###  `COSIGN_PASSWORD`

**Optional** Cosign Password used to attach provenance file.
Please make sure this is a GitHub Secret.

###  `COSIGN_PUBLIC_KEY`

**Optional** Cosign Public Key used to attach provenance file.
No need to put this in GitHub Secret vault. Good practice is to put this also in a repo as `cosign.pub`.

### `COSIGN_DOCKER_MEDIA_TYPES`

**Optional** Cosign supports older MEDIA_TYPES.
You can set this to `1` with this environment variable. Can be used for Artifactory for example.

<!-- action-docs-outputs -->
## Outputs

| parameter | description |
| - | - |
| container-digest | Container digest. Can be used for generating provenance and signing |
| container-tags | Container tags. Can be used for generating provenance and signing |
| push-indicator | Is set to true when containers have been pushed to the container repository |
| slsa-provenance-file | SLSA provenance filename if created |
| sbom-file | SBOM filename if created |



<!-- action-docs-outputs -->
<!-- action-docs-runs -->
## Runs

This action is a `docker` action.


<!-- action-docs-runs -->

## Example usage

```yaml
- uses: philips-software/docker-ci-scripts@v4.1.2
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

```yaml
- name: Build Docker Images
  uses: philips-software/docker-ci-scripts@v4.1.2
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

#### Signing the Image:

We can automatically sign the image with Cosign if you pass the `sign` argument.
You need to provide the COSIGN environment variables in order to actually sign it.

You can create a key pair by installing Cosign on your local machine and run:
```bash
  $ cosign generate-key-pair
```

Store the content of `cosign.pub`, `cosign.key` and the password in GitHub Secrets.

```yaml
- name: Build Docker Images
  uses: philips-software/docker-ci-scripts@v4.1.2
  with:
    dockerfile: .
    image-name: image-name-here
    tags: latest 0.1
    push-branches: main develop
    sign: true
  env:
    DOCKER_USERNAME: ${{ github.actor }}
    DOCKER_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
    DOCKER_REGISTRY: ghcr.io/organization-here
    GITHUB_ORGANIZATION: organization-here
    COSIGN_PRIVATE_KEY: ${{ secrets.COSIGN_PRIVATE_KEY }}
    COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
    COSIGN_PUBLIC_KEY: ${{ secrets.COSIGN_PUBLIC_KEY }}
```

Now you can verify the image f.e. `jeroenknoops/test-image:latest`:

```bash
  $ cosign verify --key cosign.pub jeroenknoops/test-image:latest
```

You will get a result when the image is valid.

#### With SLSA Provenance:

```yaml
- name: Build Docker Images
  id: docker
  uses: philips-software/docker-ci-scripts@v4.1.2
  with:
    dockerfile: .
    image-name: image-name-here
    tags: latest 0.1
    push-branches: main develop
    slsa-provenance: true
  env:
    DOCKER_USERNAME: ${{ github.actor }}
    DOCKER_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
    DOCKER_REGISTRY: ghcr.io/organization-here
    GITHUB_ORGANIZATION: organization-here
- name: Show provenance
  run: |
    cat ${{ steps.docker.outputs.slsa-provenance-file }}
```

#### With SLSA Provenance attached to Image:

You can use Cosign to attach the Provenance file to the image. Obviously you will need to set
the COSIGN environment variables. (see #sign how to generate the key-pair)

```yaml
- name: Build Docker Images
  uses: philips-software/docker-ci-scripts@v4.1.2
  with:
    dockerfile: .
    image-name: image-name-here
    tags: latest 0.1
    push-branches: main develop
    slsa-provenance: true
    sign: true
  env:
    DOCKER_USERNAME: ${{ github.actor }}
    DOCKER_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
    DOCKER_REGISTRY: ghcr.io/organization-here
    GITHUB_ORGANIZATION: organization-here
    COSIGN_PRIVATE_KEY: ${{ secrets.COSIGN_PRIVATE_KEY }}
    COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
    COSIGN_PUBLIC_KEY: ${{ secrets.COSIGN_PUBLIC_KEY }}
```

Now you can verify the attestation for a certain docker-repo f.e. `jeroenknoops/test-image:latest`:

```bash
  $ cosign verify-attestation --key cosign.pub jeroenknoops/test-image:latest | jq '.payload |= @base64d | .payload | fromjson | select(.predicateType=="https://slsa.dev/provenance/v0.2" ) | .'
```

This is nice, because you can see how and when the image was build, without downloading it!
You can inspect the provenance and decide on whether you want use the image.

#### With Software Bill of Material (SBOM):

```yaml
- name: Build Docker Images
  id: docker
  uses: philips-software/docker-ci-scripts@v4.1.2
  with:
    dockerfile: .
    image-name: image-name-here
    tags: latest 0.1
    push-branches: main develop
    sbom: true
  env:
    DOCKER_USERNAME: ${{ github.actor }}
    DOCKER_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
    DOCKER_REGISTRY: ghcr.io/organization-here
    GITHUB_ORGANIZATION: organization-here
- name: Show SBOM
  run: |
    cat ${{ steps.docker.outputs.sbom-file }}
```

#### With Software Bill of Material (SBOM) attached to Image:

You can use Cosign to attach the SBOM file to the image. Obviously you will need to set
the COSIGN environment variables. (see #sign how to generate the key-pair)

```yaml
- name: Build Docker Images
  uses: philips-software/docker-ci-scripts@v4.1.2
  with:
    dockerfile: .
    image-name: image-name-here
    tags: latest 0.1
    push-branches: main develop
    sbom: true
    sign: true
  env:
    DOCKER_USERNAME: ${{ github.actor }}
    DOCKER_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
    DOCKER_REGISTRY: ghcr.io/organization-here
    GITHUB_ORGANIZATION: organization-here
    COSIGN_PRIVATE_KEY: ${{ secrets.COSIGN_PRIVATE_KEY }}
    COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
    COSIGN_PUBLIC_KEY: ${{ secrets.COSIGN_PUBLIC_KEY }}
```

Now you can verify the attestation for a certain docker-repo f.e. `jeroenknoops/test-image:latest`:

```bash
$ cosign verify-attestation --key cosign.pub jeroenknoops/test-image:latest | jq '.payload |= @base64d | .payload | fromjson | select( .predicateType=="https://spdx.dev/Document" ) | .predicate.Data | fromjson | .'
```

#### With SLSA-Provenance and Software Bill of Material (SBOM) attached to Image:

You can use Cosign to attach the SBOM file and the SLSA-provenance file to the image. Obviously you will need to set
the COSIGN environment variables. (see #sign how to generate the key-pair)

```yaml
- name: Build Docker Images
  uses: philips-software/docker-ci-scripts@v4.1.2
  with:
    dockerfile: .
    image-name: image-name-here
    tags: latest 0.1
    push-branches: main develop
    sbom: true
    sign: true
    slsa-provenance: true
  env:
    DOCKER_USERNAME: ${{ github.actor }}
    DOCKER_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
    DOCKER_REGISTRY: ghcr.io/organization-here
    GITHUB_ORGANIZATION: organization-here
    COSIGN_PRIVATE_KEY: ${{ secrets.COSIGN_PRIVATE_KEY }}
    COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
    COSIGN_PUBLIC_KEY: ${{ secrets.COSIGN_PUBLIC_KEY }}
```

Now you can verify the attestation for a certain docker-repo f.e. `jeroenknoops/test-image:latest`:


```bash
$ cosign verify-attestation --key cosign.pub jeroenknoops/test-image:latest | jq '.payload |= @base64d | .payload | fromjson | select( .predicateType=="https://spdx.dev/Document" ) | .predicate.Data | fromjson | .'
$ cosign verify-attestation --key cosign.pub jeroenknoops/test-image:latest | jq '.payload |= @base64d | .payload | fromjson | select(.predicateType=="https://slsa.dev/provenance/v0.2" ) | .'
```

This is nice, because you can see the SBOM of the image, without downloading it!
You can inspect the SBOM and decide on whether you want use the image.

#### Automatically create major minor and patch versions

Sometimes you want to automatically create major, minor and patch releases for certain tags in the repository.
For example when you create a git tag: `v2.32.1` you might want to automatically create versions: `2`, `2.32`, and `2.32.1`.

This can be done with a small snippet:

```yaml
- name: SplitTag
  if: startsWith(github.ref, 'refs/tags/v')
  run: |
    refIN=${GITHUB_REF##*/}
    arrIN=(${refIN//./ })
    echo "major=${arrIN[0]}" >> $GITHUB_ENV
    echo "minor=${arrIN[0]}.${arrIN[1]}" >> $GITHUB_ENV
    echo "patch=${arrIN[0]}.${arrIN[1]}.${arrIN[2]}" >> $GITHUB_ENV

- name: Set no tag
  if: startsWith(github.ref, 'refs/tags/v') == false
  run: |
    echo "major=" >> $GITHUB_ENV
    echo "minor=" >> $GITHUB_ENV
    echo "patch=" >> $GITHUB_ENV

- uses: philips-software/docker-ci-scripts@v4.2.0
  with:
    dockerfile: './docker/Dockerfile'
    image-name: 'node'
    tags: 'latest ${{ env.major }} ${{ env.minor }} ${{ env.patch }}'
  env:
    DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
    DOCKER_PASSWORD: '${{ secrets.DOCKER_PASSWORD }}'
    DOCKER_ORGANIZATION: myDockerOrganization
```

Thanks to [@daantimmer](https://github.com/daantimmer) to provide this snippet.

## Example projects

* [philips-software/docker-node](https://github.com/philips-software/docker-node)
* [philips-software/docker-blackduck](https://github.com/philips-software/docker-blackduck)
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
