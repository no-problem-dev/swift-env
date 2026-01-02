# ``Env``

Swiftマクロによる環境変数設定の宣言的アクセス。

## 概要

Envは、Apple [swift-configuration](https://github.com/apple/swift-configuration) をラップし、
`@Env` と `@Value` マクロによってボイラープレートを大幅に削減します。

従来の手動実装：

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

マクロを使用した宣言的実装：

```swift
@Env
struct GCPConfig {
    @Value("gcp.project.id", default: "my-project")
    var projectId: String

    @Value("firebase.emulator", default: false)
    var useEmulator: Bool
}
```

## Topics

### マクロ

- ``Env(_:)``
- ``Value(_:default:)``

### 使用例

- <doc:GettingStarted>
- <doc:ScopedConfiguration>
