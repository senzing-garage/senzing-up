# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
[markdownlint](https://dlaa.me/markdownlint/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2021-05-06

### Changed in 1.3.0

- Migration to `senzingdata-2.0.0`
- Update docker image versions
  - senzing/init-container:1.6.6 to senzing/init-container:1.6.9
  - senzing/yum:1.1.3 to senzing/yum:1.1.4

## [1.2.2] - 2021-02-05

### Added in 1.2.2

- Pinning of docker image versions

## [1.2.1] - 2020-11-02

### Changed in 1.2.1

- Added `--privileged` flag.

## [1.2.0] - 2020-10-19

### Changed in 1.2.0

- Create and use private docker network
- Improved output
- Use `docker-bin/senzing-webapp-demo.sh` directly
- Use "Truth Set" delivered with SenzingAPI RPM.

## [1.1.0] - 2020-07-23

### Changed in 1.1.0

- Better support for "truth set"

## [1.0.1] - 2020-07-08

### Fixed in 1.0.1

- Fixed appending to history file

## [1.0.0] - 2020-05-25

### Added to 1.0.0

- Initial functionality
