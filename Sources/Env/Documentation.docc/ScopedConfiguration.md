# Scoped Configuration

Group related keys behind a shared prefix.

## Overview

A scope is a prefix applied to every key in a struct. It keeps related settings together without
repeating the prefix on each `@Value`, and it lets the same struct be read twice under different
prefixes.

## Declaring a scoped struct

```swift
import Configuration
import Env

@Env(scope: "emulator")
struct EmulatorConfig {
    @Value("firestore.host", default: "localhost")
    var firestoreHost: String

    @Value("firestore.port", default: 8090)
    var firestorePort: Int

    @Value("auth.host", default: "localhost")
    var authHost: String

    @Value("auth.port", default: 9099)
    var authPort: Int
}
```

The scope is prepended before the provider maps the key to a variable name:

| Key | Environment variable |
|---|---|
| `firestore.host` | `EMULATOR_FIRESTORE_HOST` |
| `firestore.port` | `EMULATOR_FIRESTORE_PORT` |
| `auth.host` | `EMULATOR_AUTH_HOST` |
| `auth.port` | `EMULATOR_AUTH_PORT` |

## Reading it

```swift
let config = ConfigReader(provider: EnvironmentVariablesProvider())
let emulator = EmulatorConfig(config: config)
```

Pass the unscoped reader. The generated initializer calls `scoped(to:)` itself, so scoping the
reader before handing it over applies the prefix twice.

## What the macro generates

```swift
struct EmulatorConfig {
    var firestoreHost: String
    var firestorePort: Int
    var authHost: String
    var authPort: Int

    private enum Keys {
        static let firestoreHost: ConfigKey = "firestore.host"
        static let firestorePort: ConfigKey = "firestore.port"
        static let authHost: ConfigKey = "auth.host"
        static let authPort: ConfigKey = "auth.port"
    }

    private enum Defaults {
        static let firestoreHost = "localhost"
        static let firestorePort = 8090
        static let authHost = "localhost"
        static let authPort = 9099
    }

    public init(config: ConfigReader) {
        let scopedConfig = config.scoped(to: "emulator")
        self.firestoreHost = scopedConfig.string(forKey: Keys.firestoreHost, default: Defaults.firestoreHost)
        self.firestorePort = scopedConfig.int(forKey: Keys.firestorePort, default: Defaults.firestorePort)
        self.authHost = scopedConfig.string(forKey: Keys.authHost, default: Defaults.authHost)
        self.authPort = scopedConfig.int(forKey: Keys.authPort, default: Defaults.authPort)
    }
}

extension EmulatorConfig: EnvConfigurable {}
```

Note that `Keys` stores the unscoped key. The prefix is applied by the reader at read time, not
baked into the key table.

## Scoping a whole group

``EnvGroup(scope:)`` takes the same argument and passes the scoped reader to every child, so each
child's keys nest under the group's prefix:

```swift
@Env(scope: "primary")
struct PrimaryDBConfig {
    @Value("host", default: "localhost")
    var host: String
}

@EnvGroup(scope: "database")
struct DatabaseConfig {
    let primary: PrimaryDBConfig
}
```

`host` is read as `DATABASE_PRIMARY_HOST`: the group contributes `database`, the child contributes
`primary`. A child declared without its own scope contributes nothing, so its `host` would be read
as `DATABASE_HOST`.
