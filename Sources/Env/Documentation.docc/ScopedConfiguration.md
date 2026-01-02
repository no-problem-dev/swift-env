# スコープ付き設定

キープレフィックスを持つ設定グループの定義方法を学びます。

## 概要

関連する設定をグループ化する場合、`@Env(scope:)` を使用して
キープレフィックスを指定できます。

## スコープの使い方

### スコープ付き設定の定義

```swift
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

### 環境変数との対応

`scope: "emulator"` を指定すると、以下のように環境変数名が生成されます：

| キー | 環境変数名 |
|---|---|
| `firestore.host` | `EMULATOR_FIRESTORE_HOST` |
| `firestore.port` | `EMULATOR_FIRESTORE_PORT` |
| `auth.host` | `EMULATOR_AUTH_HOST` |
| `auth.port` | `EMULATOR_AUTH_PORT` |

### 使用方法

```swift
let config = ConfigReader(provider: EnvironmentVariablesProvider())

// root config を渡す（スコープは内部で処理される）
let emulator = EmulatorConfig(config: config)

print("Firestore: \(emulator.firestoreHost):\(emulator.firestorePort)")
print("Auth: \(emulator.authHost):\(emulator.authPort)")
```

## 展開されるコード

`@Env(scope: "emulator")` は以下のようなコードを生成します：

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

extension EmulatorConfig: Sendable {}
```

## 複数設定の組み合わせ

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

// 使用例
let config = ConfigReader(provider: EnvironmentVariablesProvider())
let gcp = GCPConfig(config: config)
let emulator = EmulatorConfig(config: config)

if gcp.useEmulator {
    print("Emulator: \(emulator.firestoreHost):\(emulator.firestorePort)")
} else {
    print("Production: \(gcp.projectId)")
}
```
