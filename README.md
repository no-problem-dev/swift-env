# swift-env

Swiftマクロによる環境変数設定の宣言的アクセス。Apple [swift-configuration](https://github.com/apple/swift-configuration) をラップし、ボイラープレートを削減します。

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![macOS 15+](https://img.shields.io/badge/macOS-15+-purple.svg)
![iOS 18+](https://img.shields.io/badge/iOS-18+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 特徴

- **宣言的**: `@Env` と `@Value` マクロで設定を宣言するだけ
- **型安全**: String, Int, Double, Bool をサポート
- **DI対応**: `init(config: ConfigReader)` で依存性注入
- **スコープ対応**: `@Env(scope: "prefix")` でキープレフィックスを指定
- **ゼロランタイムオーバーヘッド**: コンパイル時コード生成

## クイックスタート

```swift
import Env

@Env
struct GCPConfig {
    @Value("gcp.project.id", default: "my-project")
    var projectId: String

    @Value("firebase.emulator", default: false)
    var useEmulator: Bool
}

// 使用例
let config = ConfigReader(provider: EnvironmentVariablesProvider())
let gcp = GCPConfig(config: config)
print(gcp.projectId)  // 環境変数 GCP_PROJECT_ID または "my-project"
```

## インストール

### Swift Package Manager

`Package.swift` に以下を追加：

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-env.git", from: "1.0.0")
]
```

ターゲットに追加：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Env", package: "swift-env")
    ]
)
```

## マクロ詳細

### `@Env`

構造体に付与し、以下を自動生成します：

- `Keys` enum: ConfigKey型の静的プロパティ
- `Defaults` enum: デフォルト値の静的プロパティ
- `init(config: ConfigReader)`: 初期化メソッド
- `Sendable` プロトコル準拠

```swift
@Env
struct ServerConfig {
    @Value("server.port", default: 8080)
    var port: Int
}

// ↓ 展開結果
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

extension ServerConfig: Sendable {}
```

### `@Env(scope:)`

スコープを指定すると、初期化時に `config.scoped(to:)` を呼び出します：

```swift
@Env(scope: "emulator")
struct EmulatorConfig {
    @Value("firestore.host", default: "localhost")
    var firestoreHost: String

    @Value("firestore.port", default: 8090)
    var firestorePort: Int
}

// 使用時は root config を渡す（スコープは内部で処理）
let emulator = EmulatorConfig(config: config)
// EMULATOR_FIRESTORE_HOST, EMULATOR_FIRESTORE_PORT を読み込み
```

### `@Value`

プロパティに付与し、環境変数キーとデフォルト値を指定します：

```swift
@Value("key.name", default: defaultValue)
var propertyName: Type
```

**サポート型**:
- `String`: `config.string(forKey:default:)`
- `Int`: `config.int(forKey:default:)`
- `Double`: `config.double(forKey:default:)`
- `Bool`: `config.bool(forKey:default:)`

## 環境変数のマッピング

キーは以下のルールで環境変数名に変換されます（swift-configuration準拠）：

| キー | 環境変数名 |
|------|-----------|
| `gcp.project.id` | `GCP_PROJECT_ID` |
| `server.port` | `SERVER_PORT` |
| `feature.enabled` | `FEATURE_ENABLED` |

スコープ付きの場合はプレフィックスが付与されます：

| スコープ | キー | 環境変数名 |
|---------|------|-----------|
| `emulator` | `firestore.host` | `EMULATOR_FIRESTORE_HOST` |

## 高度な使用例

### 複数設定の組み合わせ

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

// ファクトリパターン
enum AppConfig {
    static func makeReader() -> ConfigReader {
        ConfigReader(provider: EnvironmentVariablesProvider())
    }
}

// 依存性注入
let config = AppConfig.makeReader()
let gcp = GCPConfig(config: config)
let emulator = EmulatorConfig(config: config)
```

## 依存関係

| パッケージ | 用途 |
|-----------|------|
| [swift-configuration](https://github.com/apple/swift-configuration) | 環境変数読み込み |
| [swift-syntax](https://github.com/swiftlang/swift-syntax) | マクロ実装 |

## ドキュメント

詳細なAPIドキュメントは [GitHub Pages](https://no-problem-dev.github.io/swift-env/documentation/env/) で確認できます。

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照してください。
