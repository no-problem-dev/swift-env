English | [日本語](./README.ja.md)

# swift-env

Declarative access to environment variable configuration via Swift macros. Wraps Apple [swift-configuration](https://github.com/apple/swift-configuration) to eliminate boilerplate.

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![macOS 15+](https://img.shields.io/badge/macOS-15+-purple.svg)
![iOS 18+](https://img.shields.io/badge/iOS-18+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- **Declarative**: just annotate a struct with `@Env` and its properties with `@Value`
- **Type-safe**: supports `String`, `Int`, `Double`, `Bool`, and `RawRepresentable` enums
- **DI-friendly**: `init(config: ConfigReader)` makes injection straightforward
- **Scope support**: `@Env(scope: "prefix")` prepends a key prefix automatically
- **Zero runtime overhead**: all code is generated at compile time

## Quick Start

```swift
import Env

@Env
struct GCPConfig {
    @Value("gcp.project.id", default: "my-project")
    var projectId: String

    @Value("firebase.emulator", default: false)
    var useEmulator: Bool
}

// Usage
let config = ConfigReader(provider: EnvironmentVariablesProvider())
let gcp = GCPConfig(config: config)
print(gcp.projectId)  // reads GCP_PROJECT_ID, falls back to "my-project"
```

## Installation

### Swift Package Manager

Add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-env.git", from: "1.0.0")
]
```

Add to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Env", package: "swift-env")
    ]
)
```

## Macros

### `@Env`

Apply to a struct to auto-generate:

- `Keys` enum — `ConfigKey`-typed static properties
- `Defaults` enum — default value static properties
- `init(config: ConfigReader)` initializer
- `EnvConfigurable` conformance (which includes `Sendable`)

```swift
@Env
struct ServerConfig {
    @Value("server.port", default: 8080)
    var port: Int
}

// Expands to:
struct ServerConfig {
    var port: Int

    private enum Keys {
        static let port: ConfigKey = "server.port"
    }

    private enum Defaults {
        static let port = 8080
    }

    public init(config: ConfigReader) {
        self.port = config.int(forKey: Keys.port, default: Defaults.port)
    }
}

extension ServerConfig: EnvConfigurable {}
```

### `@Env(scope:)`

Providing a scope causes the initializer to call `config.scoped(to:)` internally:

```swift
@Env(scope: "emulator")
struct EmulatorConfig {
    @Value("firestore.host", default: "localhost")
    var firestoreHost: String

    @Value("firestore.port", default: 8090)
    var firestorePort: Int
}

// Pass the root config — scoping is handled internally
let emulator = EmulatorConfig(config: config)
// Reads EMULATOR_FIRESTORE_HOST, EMULATOR_FIRESTORE_PORT
```

### `@Value`

Apply to a stored property inside an `@Env` struct to declare its environment key and default:

```swift
@Value("key.name", default: defaultValue)
var propertyName: Type
```

**Supported types**:
- `String` — `config.string(forKey:default:)`
- `Int` — `config.int(forKey:default:)`
- `Double` — `config.double(forKey:default:)`
- `Bool` — `config.bool(forKey:default:)`
- `RawRepresentable where RawValue == String` — stored as the raw string, restored via `Type(rawValue:) ?? default`

### `@EnvGroup`

Groups multiple `@Env` structs and auto-generates `init(config:)` plus `static func load()`:

```swift
@EnvGroup
public struct AppConfig {
    let gcp: GCPConfig
    let server: ServerConfig
}

// Usage
let app = AppConfig.load()
print(app.gcp.projectId)
```

## Environment Variable Mapping

Keys follow swift-configuration naming rules — dot-separated segments become `UPPER_SNAKE_CASE`:

| Key | Environment variable |
|-----|---------------------|
| `gcp.project.id` | `GCP_PROJECT_ID` |
| `server.port` | `SERVER_PORT` |
| `feature.enabled` | `FEATURE_ENABLED` |

With a scope, the scope name is prepended:

| Scope | Key | Environment variable |
|-------|-----|---------------------|
| `emulator` | `firestore.host` | `EMULATOR_FIRESTORE_HOST` |

## Advanced Usage

### Combining Multiple Configs

```swift
@Env
struct GCPConfig {
    @Value("gcp.project.id", default: "stockle-app")
    var projectId: String

    @Value("firebase.emulator", default: false)
    var useEmulator: Bool
}

@Env(scope: "emulator")
struct EmulatorConfig {
    @Value("firestore.host", default: "localhost")
    var firestoreHost: String

    @Value("firestore.port", default: 8090)
    var firestorePort: Int
}

@EnvGroup
public struct AppConfig {
    let gcp: GCPConfig
    let emulator: EmulatorConfig
}

// Dependency injection
let app = AppConfig.load()
let gcp = app.gcp
let emulator = app.emulator
```

## Dependencies

| Package | Purpose |
|---------|---------|
| [swift-configuration](https://github.com/apple/swift-configuration) | Reading environment variables |
| [swift-syntax](https://github.com/swiftlang/swift-syntax) | Macro implementation |

## Documentation

Full API documentation is available on [GitHub Pages](https://no-problem-dev.github.io/swift-env/documentation/env/).

## License

MIT License — see [LICENSE](LICENSE) for details.
