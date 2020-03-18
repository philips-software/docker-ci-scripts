# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project uses the version of main tool as main version number .

## [Unreleased]

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

[#21]: https://github.com/philips-software/docker-ci-scripts/issues/21
[#17]: https://github.com/philips-software/docker-ci-scripts/issues/17
[#10]: https://github.com/philips-software/docker-ci-scripts/issues/10
[#3]: https://github.com/philips-software/docker-ci-scripts/issues/3
[#1]: https://github.com/philips-software/docker-ci-scripts/issues/1

[Unreleased]: https://github.com/philips-software/docker-ci-scripts/compare/1.0.1...HEAD
[1.0.1]: https://github.com/philips-software/docker-ci-scripts/compare/1.0.0...1.0.1

