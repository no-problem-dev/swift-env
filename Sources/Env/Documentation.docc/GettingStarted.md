# Getting Started

Declare a configuration struct and read it.

## Overview

A configuration struct declares which key backs each property and what that property falls back
to. Everything else — the key table, the defaults, the initializer — is generated.

## Declaring a configuration struct

```swift
import Configuration
import Env

@Env
struct ServerConfig {
    @Value("server.port", default: 8080)
    var port: Int

    @Value("server.host", default: "localhost")
    var host: String
}
```

Both imports are needed. `Env` provides the macros; `Configuration` provides the reader and
provider types that the generated code names.

## Reading it

```swift
let config = ConfigReader(provider: EnvironmentVariablesProvider())
let server = ServerConfig(config: config)

print("Server: \(server.host):\(server.port)")
```

The reader you pass decides where values come from. `EnvironmentVariablesProvider` reads the
process environment; other providers read files or remote sources, and a reader built over several
providers resolves them in order. This package adds no precedence rules of its own.

Values are read once, here. An instance never observes a later change to the environment.

## Supported types

| Property type | Read with | Example default |
|---|---|---|
| `String` | `string(forKey:default:)` | `"localhost"` |
| `Int` | `int(forKey:default:)` | `8080` |
| `Double` | `double(forKey:default:)` | `0.05` |
| `Bool` | `bool(forKey:default:)` | `false` |
| `RawRepresentable` with a `String` raw value | the raw string, then `init(rawValue:)` | `.development` |

Any other type falls through to the string accessor and fails to compile at the assignment, rather
than reporting that the type is unsupported.

## Key naming

Keys are dot-separated. `EnvironmentVariablesProvider` uppercases each segment and joins them with
underscores:

| Key | Environment variable |
|---|---|
| `server.port` | `SERVER_PORT` |
| `gcp.project.id` | `GCP_PROJECT_ID` |
| `feature.enabled` | `FEATURE_ENABLED` |

The key is what you declare; a different provider maps it differently.

## When a value is missing or malformed

Both cases resolve to the declared default, silently. `SERVER_PORT=abc` produces `8080`, not an
error, and an enum whose stored string matches no case falls back the same way.

If a value must be present and valid, do not give it a default here. Read it directly through
swift-configuration's `requiredInt(forKey:)` or `requiredString(forKey:)`, which throw.

## Next steps

- <doc:ScopedConfiguration> groups related keys behind a shared prefix.
