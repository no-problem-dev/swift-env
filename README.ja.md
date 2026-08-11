[English](./README.md) | 日本語

# swift-env

Swift の環境変数設定を宣言的に扱う。プロパティにキーとデフォルト値を書けば、キー表・デフォルト表・
イニシャライザはマクロが生成する。

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20%7C%20Linux-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 概要

Apple の [swift-configuration](https://github.com/apple/swift-configuration) をラップし、設定構造体
から「キー・デフォルト値・代入」の三重の繰り返しを取り除く。

- **宣言的** — 構造体に `@Env`、プロパティに `@Value` を付けるだけ
- **型安全** — `String` / `Int` / `Double` / `Bool` と `RawRepresentable` な enum に対応
- **注入可能** — 生成される `init(config:)` がリーダーを受け取るので、テストは自前のものを渡せる
- **スコープ対応** — `@Env(scope:)` が構造体内の全キーにプレフィックスを付ける
- **コンパイル時生成** — 実行時のリフレクションは使わない

採用前に知っておくべき挙動が 2 つある。値が読まれるのは `init(config:)` の**一度だけ**で、生成済みの
インスタンスがあとからの環境変数の変更を見ることはない。そして値が未設定の場合も**変換できない場合も**、
どちらも**黙って**デフォルト値になる — `PORT=abc` はエラーではなくデフォルト値を返す。

また値は secret 扱いされずに読まれるため、`@Value` で宣言したものは swift-configuration の
アクセスレポーターによって平文で記録されうる。認証情報は swift-configuration から直接読むこと。

## 使い方

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
print(api.baseURL)  // API_BASE_URL、未設定ならデフォルト値
```

import は両方必要。`Env` がマクロを、`Configuration` が生成コードの参照するリーダーとプロバイダの型を
提供する。

## ドキュメント

[API リファレンスとガイド](https://no-problem-dev.github.io/swift-env/documentation/env/) — キーの
命名規則、スコープ付き設定、`@EnvGroup` による複数構造体の合成。

## インストール

`Package.swift` に追加する:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-env.git", from: "2.0.0")
]
```

ターゲットにプロダクトを追加する:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Env", package: "swift-env")
    ]
)
```

## ライセンス

MIT — [LICENSE](LICENSE) を参照。
