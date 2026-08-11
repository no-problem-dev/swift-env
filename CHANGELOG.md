# Changelog

All notable changes to this project are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.0.0] - 2026-08-11

### Removed

- The `@_exported` re-export of swift-configuration. Code naming `ConfigReader`, `ConfigKey`, or
  `EnvironmentVariablesProvider` — including anything calling the generated `load()` — must now
  `import Configuration` alongside `import Env`.

### Added

- `.spi.yml`, so Swift Package Index builds and hosts the DocC documentation
- `CONTRIBUTING.md`
- `scripts/release.sh` and `scripts/compute-next-version.sh`, which derive the next version from
  the public API diff and stamp it into this file

### Changed

- CI no longer builds or tests; it creates a GitHub Release from a pushed tag. Verification runs
  locally before pushing.

## [1.0.4] - 2026-07-19

### Changed

- Moved the `scope:` and stored-property helpers shared by `@Env` and `@EnvGroup` into
  `MacroHelpers.swift`
- DocC is built on macOS 26 / Xcode 26 (Swift 6.2) and published to GitHub Pages via
  `actions/deploy-pages`
- Rewrote doc comments and the DocC catalog in Japanese, and split the README into English and
  Japanese editions

### Removed

- The `missingValueAttribute`, `invalidValueArguments`, and `unsupportedType` error cases, none of
  which were ever thrown
- The auto-release-on-merge workflow, replaced by a tag-triggered release

### Fixed

- The macro expansion example in the README

## [1.0.3] - 2026-01-02

### Changed

- Unified dependency requirements on `.upToNextMajor`

## [1.0.2] - 2026-01-02

### Added

- Linux x86_64 tests, run in the `swift:6.2-bookworm` container

### Changed

- Swift 6.2 support: `swift-tools-version` 6.0 → 6.2, swift-syntax 600.0.0 → 602.0.0

## [1.0.1] - 2026-01-02

### Added

- `@EnvGroup` macro, generating a facade struct that aggregates several `@Env` structs
  - `static func load()` reads every nested configuration in one call
  - Nested `@Env` and `@EnvGroup` structs are supported
- Macro expansion tests for `@EnvGroup`

## [1.0.0] - 2026-01-02

### Added

- `@Env` macro, generating from a struct:
  - a `Keys` enum of `ConfigKey` static properties
  - a `Defaults` enum of default-value static properties
  - an `init(config: ConfigReader)` initializer
  - `Sendable` conformance
  - a `scope` parameter for key prefixes
- `@Value` macro, declaring a property's configuration key and default value
  - `String`, `Int`, `Double`, and `Bool` support
  - Dot-separated keys, mapped to environment variable names (`"gcp.project.id"` → `GCP_PROJECT_ID`)
- Re-export of Apple swift-configuration 1.0, exposing `ConfigReader`, `ConfigKey`, and
  `EnvironmentVariablesProvider`
- 11 macro expansion tests covering primitive types, multiple properties, scopes, and edge cases
- README, RELEASE_PROCESS.md, and the DocC catalog

[Unreleased]: https://github.com/no-problem-dev/swift-env/compare/1.0.4...HEAD
[1.0.4]: https://github.com/no-problem-dev/swift-env/compare/v1.0.3...1.0.4
[1.0.3]: https://github.com/no-problem-dev/swift-env/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/no-problem-dev/swift-env/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/no-problem-dev/swift-env/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/no-problem-dev/swift-env/releases/tag/v1.0.0
