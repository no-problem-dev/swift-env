English | [日本語](./README.ja.md)

# swift-env

Declarative environment configuration for Swift. Declare the key and the default on each property;
the macro writes the key table, the defaults, and the initializer.

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20%7C%20Linux-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Overview

A wrapper around Apple's [swift-configuration](https://github.com/apple/swift-configuration) that
removes the three-way repetition of key, default, and assignment from a configuration struct.

- **Declarative** — annotate a struct with `@Env` and its properties with `@Value`
- **Type-safe** — `String`, `Int`, `Double`, `Bool`, and `RawRepresentable` enums
- **Injectable** — the generated `init(config:)` takes the reader, so tests pass their own
- **Scoped** — `@Env(scope:)` prefixes every key in the struct
- **Compile-time** — the macro generates code; nothing is resolved by reflection at runtime

Two behaviors are worth knowing before you adopt it. Values are read **once**, in `init(config:)`,
so an instance never observes a later change to the environment. And a value that is missing *or*
malformed resolves to the declared default **silently** — `PORT=abc` yields the default, not an
error.

It also reads values without marking them secret, so anything you declare with `@Value` can be
written in cleartext by a swift-configuration access reporter. Read credentials directly through
swift-configuration instead.

## Usage

```swift
import Configuration
import Env

@Env
struct APIConfig {
    @Value("api.base.url", default: "https://api.example.com")
    var baseURL: String

    @Value("api.timeout", default: 30)
    var timeoutSeconds: Int
}

let config = ConfigReader(provider: EnvironmentVariablesProvider())
let api = APIConfig(config: config)
print(api.baseURL)  // API_BASE_URL, or the default when unset
```

Both imports are required: `Env` provides the macros, `Configuration` provides the reader and
provider types the generated code names.

## Documentation

[API reference and guides](https://no-problem-dev.github.io/swift-env/documentation/env/) — key
naming, scoped configuration, and composing several structs with `@EnvGroup`.

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-env.git", from: "2.0.0")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Env", package: "swift-env")
    ]
)
```

## License

MIT — see [LICENSE](LICENSE).
