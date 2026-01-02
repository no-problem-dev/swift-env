@_exported import Configuration

// MARK: - EnvConfigurable Protocol

/// 環境変数から初期化可能な型を表すプロトコル
///
/// `@Env` マクロを適用した構造体は自動的にこのプロトコルに準拠します。
/// `@EnvGroup` マクロはこのプロトコルを使用して、子の設定を初期化します。
///
/// ## 自動準拠
///
/// ```swift
/// @Env
/// struct GCPConfig {  // 自動的に EnvConfigurable に準拠
///     @Value("gcp.project.id", default: "my-project")
///     var projectId: String
/// }
/// ```
public protocol EnvConfigurable: Sendable {
    /// ConfigReader から設定を読み込んで初期化
    init(config: ConfigReader)
}

// MARK: - @Env Macro

/// 環境変数から型安全に値を読み取る構造体を定義するマクロ
///
/// このマクロを構造体に適用すると、以下が自動生成されます:
/// - `init(config: ConfigReader)` イニシャライザ
/// - 各プロパティのKeys enum（ConfigKey型）
/// - 各プロパティのDefaults enum
/// - `EnvConfigurable` プロトコル準拠（`Sendable` を含む）
///
/// ## 基本的な使用例
///
/// ```swift
/// @Env
/// struct GCPConfig {
///     @Value("gcp.project.id", default: "my-project")
///     var projectId: String
///
///     @Value("firebase.emulator", default: false)
///     var useEmulator: Bool
/// }
///
/// // 使用
/// let config = AppConfig.makeReader()
/// let gcp = GCPConfig(config: config)
/// print(gcp.projectId)  // 環境変数 GCP_PROJECT_ID または "my-project"
/// ```
///
/// ## スコープ付きの使用例
///
/// ```swift
/// @Env(scope: "emulator")
/// struct EmulatorConfig {
///     @Value("firestore.host", default: "localhost")
///     var firestoreHost: String
///
///     @Value("firestore.port", default: 8090)
///     var firestorePort: Int
/// }
///
/// // 使用（emulatorスコープが自動適用）
/// let config = AppConfig.makeReader()
/// let emulator = EmulatorConfig(config: config)
/// // 環境変数 EMULATOR_FIRESTORE_HOST, EMULATOR_FIRESTORE_PORT を読み取り
/// ```
///
/// - Parameter scope: 環境変数のスコープ（プレフィックス）。省略時はルートレベル
@attached(member, names: named(Keys), named(Defaults), named(init))
@attached(extension, conformances: EnvConfigurable)
public macro Env(
    scope: String? = nil
) = #externalMacro(module: "EnvMacros", type: "EnvMacro")

// MARK: - @Value Macro

/// 環境変数の値を定義するマクロ
///
/// `@Env`構造体内のプロパティに適用し、
/// 環境変数のキーとデフォルト値を指定します。
///
/// ## キー変換規則
///
/// Swift Configurationの命名規則に従い、
/// ドット区切りのキーはアンダースコア + 大文字に変換されます:
///
/// - `gcp.project.id` → `GCP_PROJECT_ID`
/// - `firebase.emulator` → `FIREBASE_EMULATOR`
/// - `server.port` → `SERVER_PORT`
///
/// ## 使用例
///
/// ```swift
/// @Env
/// struct ServerConfig {
///     /// サーバーポート（環境変数: SERVER_PORT）
///     @Value("server.port", default: 8080)
///     var port: Int
///
///     /// ホスト名（環境変数: SERVER_HOST）
///     @Value("server.host", default: "0.0.0.0")
///     var host: String
/// }
/// ```
///
/// ## 対応する型
///
/// - `String`
/// - `Int`
/// - `Double`
/// - `Bool`
/// - `RawRepresentable where RawValue == String` (enum)
///
/// ## Enum の使用例
///
/// ```swift
/// enum AppEnvironment: String {
///     case development, staging, production
/// }
///
/// @Env
/// struct AppConfig {
///     @Value("app.environment", default: .development)
///     var environment: AppEnvironment
/// }
/// ```
///
/// - Parameters:
///   - key: 環境変数のキー（ドット区切り形式）
///   - default: 環境変数が未設定の場合のデフォルト値
@attached(peer)
public macro Value<T>(_ key: String, default: T) = #externalMacro(module: "EnvMacros", type: "ValueMacro")

// MARK: - @EnvGroup Macro

/// 複数の `@Env` 構造体をグループ化するマクロ
///
/// このマクロを構造体に適用すると、以下が自動生成されます:
/// - `init(config: ConfigReader)` イニシャライザ
/// - `static func load() -> Self` ファクトリメソッド
/// - `EnvConfigurable` プロトコル準拠
///
/// ## 基本的な使用例
///
/// ```swift
/// @EnvGroup
/// public struct AppConfig {
///     let gcp: GCPConfig
///     let emulator: EmulatorConfig
///     let server: ServerConfig
/// }
///
/// // 使用
/// let config = AppConfig.load()
/// print(config.gcp.projectId)
/// ```
///
/// ## スコープ付きの使用例
///
/// ```swift
/// @EnvGroup(scope: "database")
/// struct DatabaseConfig {
///     let primary: PrimaryDBConfig   // DATABASE_PRIMARY_* を読む
///     let replica: ReplicaDBConfig   // DATABASE_REPLICA_* を読む
/// }
/// ```
///
/// ## ネストした使用例
///
/// ```swift
/// @EnvGroup
/// public struct AppConfig {
///     let gcp: GCPConfig
///     let database: DatabaseConfig  // ネストされた EnvGroup
/// }
/// ```
///
/// - Parameter scope: 環境変数のスコープ（プレフィックス）。省略時はルートレベル
@attached(member, names: named(init), named(load))
@attached(extension, conformances: EnvConfigurable)
public macro EnvGroup(
    scope: String? = nil
) = #externalMacro(module: "EnvMacros", type: "EnvGroupMacro")
