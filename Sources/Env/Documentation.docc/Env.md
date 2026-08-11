# ``Env``

Declarative access to environment variable configuration, through Swift macros.

## Overview

Env wraps Apple's [swift-configuration](https://github.com/apple/swift-configuration) so that a
configuration struct declares only its keys and defaults. The key table, the default table, and
the initializer are generated at compile time.

Written by hand, a configuration struct repeats itself three times:

```swift
struct GCPConfig: Sendable {
    private enum Keys {
        static let projectId: ConfigKey = "gcp.project.id"
        static let useEmulator: ConfigKey = "firebase.emulator"
    }

    private enum Defaults {
        static let projectId = "my-project"
        static let useEmulator = false
    }

    let projectId: String
    let useEmulator: Bool

    init(config: ConfigReader) {
        self.projectId = config.string(forKey: Keys.projectId, default: Defaults.projectId)
        self.useEmulator = config.bool(forKey: Keys.useEmulator, default: Defaults.useEmulator)
    }
}
```

Declared with the macros, the same struct states each fact once:

```swift
@Env
struct GCPConfig {
    @Value("gcp.project.id", default: "my-project")
    var projectId: String

    @Value("firebase.emulator", default: false)
    var useEmulator: Bool
}
```

### Where values come from

This package does not read the environment and does not merge sources. It generates calls against
the `ConfigReader` you hand it, so that reader's provider chain alone decides which source wins.
The one exception is `load()` on an ``EnvGroup(scope:)`` type, which builds its own reader over the
process environment and consults nothing else.

### When values are read

Every value is resolved once, inside `init(config:)`, and copied into a stored property. Changing
an environment variable afterwards does not affect an instance that already exists; construct a
new one to re-read.

### What happens to a bad value

A key that is absent resolves to its declared default. So does a key whose value cannot be
converted to the property's type: `SERVER_PORT=abc` yields the default rather than an error.
Nothing is thrown and nothing is logged, so a misspelled value in a deployment environment looks
exactly like an unset one.

### Secrets

Values are resolved without being marked secret. Any `AccessReporter` attached to the reader
therefore records them in cleartext — including the file reporter swift-configuration installs on
its own when the `CONFIG_ACCESS_LOG_FILE` environment variable is set. Read credentials directly
through swift-configuration's `isSecret:` parameter instead of declaring them with ``Value(_:default:)``.

### Importing

Code that constructs a reader, or that calls the generated `load()`, must import both modules.
Importing `Env` alone does not bring `EnvironmentVariablesProvider` into scope:

```swift
import Configuration
import Env
```

## Topics

### Declaring configuration

- ``Env(scope:)``
- ``Value(_:default:)``

### Composing configuration

- ``EnvGroup(scope:)``
- ``EnvConfigurable``

### Guides

- <doc:GettingStarted>
- <doc:ScopedConfiguration>
