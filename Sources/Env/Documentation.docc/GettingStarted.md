# はじめに

環境変数設定を宣言的に定義する方法を学びます。

## 概要

Envパッケージは、`@Env` と `@Value` マクロを使用して、
環境変数から設定を読み込む構造体を宣言的に定義できます。

## 基本的な使い方

### 1. 設定構造体の定義

```swift
import Env

@Env
struct ServerConfig {
    @Value("server.port", default: 8080)
    var port: Int

    @Value("server.host", default: "localhost")
    var host: String
}
```

### 2. 設定の読み込み

```swift
// ConfigReaderを作成（環境変数から読み込み）
let config = ConfigReader(provider: EnvironmentVariablesProvider())

// 設定構造体を初期化
let server = ServerConfig(config: config)

// プロパティにアクセス
print("サーバー: \(server.host):\(server.port)")
```

## サポートされる型

`@Value` マクロは以下の型をサポートします：

| 型 | ConfigReaderメソッド | 例 |
|---|---|---|
| `String` | `string(forKey:default:)` | `"default-value"` |
| `Int` | `int(forKey:default:)` | `8080` |
| `Double` | `double(forKey:default:)` | `0.05` |
| `Bool` | `bool(forKey:default:)` | `false` |

## 環境変数名のマッピング

キーはドット区切りで指定し、以下のルールで環境変数名に変換されます：

| キー | 環境変数名 |
|---|---|
| `server.port` | `SERVER_PORT` |
| `gcp.project.id` | `GCP_PROJECT_ID` |
| `feature.enabled` | `FEATURE_ENABLED` |

## 次のステップ

- <doc:ScopedConfiguration> でスコープ付き設定を学ぶ
