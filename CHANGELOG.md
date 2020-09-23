# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project uses the version of main tool as main version number .

## [Unreleased]

- [#50] - Fix: Automatic push of README to docker hub is broken.
- [#48] - Loop through entire array of push-branches

## v3.1.0 - 2020-09-23
- Allow users to specify multiple branches to push to the artifact repository. `push-branches`

### DEPRECATION
- [#47] - `push-branch` is now deprecated by `push-branches`. Will be removed in next major release.

## v3.0.0 - 2020-09-15

### BREAKING
- Allow users to specify specific dockerfile instead of path

The `docker build` command is now being called from the root of the project
instead of the directory. 

This has impact when your project has:
- Directories with multiple dockerfiles
- The dockerfile contains an `ADD` or a `COPY` command.

You now need to change the path to include the directory.

Example:
- `ADD /scripts/entrypoint.sh entrypoint.sh` becomes: `ADD /6/java/scripts/entrypoint.sh entrypoint` 

## v2.2.1 - 2020-05-18
### Changed
- [#38] - Auto update readme was not working anymore 

## v2.2.0
- [#33] - DOCKER_ORGANIZATION is optional when other repository store is used.
- [#32] - DOCKER_REGISTRY should be an environment variable. 
- Fix shellinter

### Add
- [#28] - Update readme on docker.io

## [v2.0.1] - 2020-03-18

### Changed

* [#26] - REPO file is not correct.

## [v2] - 2020-03-18

### BREAKING

* [#17] - Now available as github action. No more git submodules.
* [#21] - Support for different docker registries. Seperated image name from tags.

### Changed

* [#10] - Adjust paths for Github Actions runners

## [1.0.1] - 2019-03-05

### Changed

* [#3] - Fix error in docker_push.sh script related to buildpath

## 1.0.0 - 2019-02-16

### Added

* [#1] - Custom DOCKER_ORGANIZATION and GITHUB_ORGANIZATION.
* Initial start

[#50]: https://github.com/philips-software/docker-ci-scripts/issues/50
[#48]: https://github.com/philips-software/docker-ci-scripts/issues/48
[#47]: https://github.com/philips-software/docker-ci-scripts/pull/47
[#38]: https://github.com/philips-software/docker-ci-scripts/issues/38
[#28]: https://github.com/philips-software/docker-ci-scripts/issues/28
[#26]: https://github.com/philips-software/docker-ci-scripts/issues/26
[#21]: https://github.com/philips-software/docker-ci-scripts/issues/21
[#17]: https://github.com/philips-software/docker-ci-scripts/issues/17
[#10]: https://github.com/philips-software/docker-ci-scripts/issues/10
[#3]: https://github.com/philips-software/docker-ci-scripts/issues/3
[#1]: https://github.com/philips-software/docker-ci-scripts/issues/1

[Unreleased]: https://github.com/philips-software/docker-ci-scripts/compare/v2...HEAD
[v2]: https://github.com/philips-software/docker-ci-scripts/compare/1.0.1...v2
[1.0.1]: https://github.com/philips-software/docker-ci-scripts/compare/1.0.0...1.0.1

