# Changelog

このプロジェクトのすべての注目すべき変更はこのファイルに記録されます。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [未リリース]

<!-- 次のリリースに含める変更をここに追加 -->

## [1.0.1] - 2026-01-02

### 追加

- **`@EnvGroup` マクロ**: 複数の `@Env` 構造体を集約するファサード構造体を生成
  - `static func load()` メソッドを自動生成し、全ネスト設定を一括読み込み
  - ネストした `@Env` および `@EnvGroup` 構造体をサポート
  - 統一されたエントリーポイントでアプリケーション設定を簡潔に管理

### テスト

- EnvGroup マクロ展開テスト追加

## [1.0.0] - 2025-01-02

### 追加

- **`@Env` マクロ**: 構造体に付与して環境変数設定を自動生成
  - `Keys` enum（ConfigKey型の静的プロパティ）を自動生成
  - `Defaults` enum（デフォルト値の静的プロパティ）を自動生成
  - `init(config: ConfigReader)` イニシャライザを自動生成
  - `Sendable` プロトコル準拠を自動追加
  - `scope` パラメータでスコープ設定をサポート

- **`@Value` マクロ**: プロパティに付与して環境変数キーとデフォルト値を指定
  - String, Int, Double, Bool 型をサポート
  - 環境変数キーをドット区切りで指定（例: `"gcp.project.id"` → `GCP_PROJECT_ID`）

- **Apple swift-configuration 1.0 の再エクスポート**
  - `ConfigReader`, `ConfigKey`, `EnvironmentVariablesProvider` 等を利用可能

### テスト

- 11種類のマクロ展開テスト
  - 基本型テスト（String, Int, Double, Bool）
  - 複数プロパティテスト
  - スコープ付きテスト
  - エッジケーステスト

### ドキュメント

- README.md（日本語）
- RELEASE_PROCESS.md
- DocCドキュメント

[未リリース]: https://github.com/no-problem-dev/swift-env/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/no-problem-dev/swift-env/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/no-problem-dev/swift-env/releases/tag/v1.0.0

<!-- Release v1.0.0 prepared on 2026-01-02T03:18:58Z -->

<!-- Auto-generated on 2026-01-02T04:14:21Z by release workflow -->
