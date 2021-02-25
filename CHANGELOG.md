# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## v1.6.0 - 2021-02-25

### Changed

- Gleam version to 0.14.0 and `gleam_stdlib` version to 0.14.0.
- Relaxed `gleam_stdlib` version constraints in `rebar.config`.

## v1.5.1 - 2020-09-07

### Fixed

- Fix incomplete update of `gleam_stdlib` version to 0.11.0.

## v1.5.0 - 2020-09-06

### Changed

- Gleam version to 0.11.2 and `gleam_stdlib` version to 0.11.0.

## v1.4.0 - 2020-05-11

### Added

- Documentation via Gleam's new documentation features.

### Changed

- Gleam version to 0.8.0 and `gleam_stdlib` version to 0.8.0.

## v1.3.0 - 2020-04-14

### Changed

- Gleam version to 0.7.1 and `gleam_stdlib` version to 0.7.0.

## v1.2.0 - 2020-01-02

### Added

- An `ok_error_tuple` decoder for decoding `ok`/`error` tuples, (e.g. `{ok, Success}`/`{error, Failure}`).

## v1.1.0 - 2019-12-28

### Added

- A `dynamic` decoder for decoding `Dynamic` data into `Dynamic` data.
- Descriptive text to the top of the changelog.

## v1.0.0 - 2019-12-25

- Initial release! 🎄🎁
