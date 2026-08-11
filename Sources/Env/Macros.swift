import Configuration

// MARK: - EnvConfigurable Protocol

/// A configuration type whose values are all resolved once, at initialization, and never re-read.
///
/// `@Env` and `@EnvGroup` add this conformance automatically. `@EnvGroup` relies on it to
/// initialize each of its children from the same reader.
///
/// Because every value is copied into a stored property during `init(config:)`, changing an
/// environment variable after initialization has no effect on an already-created instance.
/// Re-read configuration by constructing a new instance.
public protocol EnvConfigurable: Sendable {
    /// Resolves every declared value from the given reader and stores it.
    ///
    /// - Parameter config: The reader to pull values from. Its provider chain alone decides where
    ///   values come from and which source wins; this package neither merges nor orders sources.
    init(config: ConfigReader)
}

// MARK: - @Env Macro

/// Turns a struct into a configuration type that resolves each annotated property once, falling
/// back to the declared default.
///
/// Attach to a struct whose stored properties carry `@Value`. The macro generates:
/// - `init(config: ConfigReader)`, which resolves every property in declaration order
/// - a private `Keys` enum holding the `ConfigKey` for each property
/// - a private `Defaults` enum holding the fallback value for each property
/// - conformance to `EnvConfigurable` (and therefore `Sendable`)
///
/// Properties without `@Value` are ignored, as are computed properties. A struct with no `@Value`
/// property generates no initializer at all, which fails to compile because the conformance still
/// requires one.
///
/// ## Resolution behavior
///
/// A key that is absent resolves to the declared default. So does a key whose value cannot be
/// converted to the property's type — `SERVER_PORT=abc` yields the default, not an error. Nothing
/// is logged and nothing is thrown, so a typo in a deployment environment is indistinguishable
/// from an unset variable.
///
/// ## Secrets
///
/// Values are resolved without marking them secret, so an `AccessReporter` attached to the reader
/// records them in cleartext. swift-configuration installs such a reporter automatically when the
/// `CONFIG_ACCESS_LOG_FILE` environment variable is set. Do not route credentials through this
/// macro in an environment where that variable may be set.
///
/// ## Example
///
/// ```swift
/// import Configuration
/// import Env
///
/// @Env
/// struct GCPConfig {
///     @Value("gcp.project.id", default: "my-project")
///     var projectId: String
///
///     @Value("firebase.emulator", default: false)
///     var useEmulator: Bool
/// }
///
/// let config = ConfigReader(provider: EnvironmentVariablesProvider())
/// let gcp = GCPConfig(config: config)
/// print(gcp.projectId)  // GCP_PROJECT_ID, or "my-project" if unset
/// ```
///
/// - Parameter scope: A prefix prepended to every key in this struct, so `firestore.host` under
///   scope `emulator` reads `EMULATOR_FIRESTORE_HOST`. Callers still pass the unscoped reader;
///   the generated initializer applies the scope itself. Omit to read at the root.
@attached(member, names: named(Keys), named(Defaults), named(init))
@attached(extension, conformances: EnvConfigurable)
public macro Env(
    scope: String? = nil
) = #externalMacro(module: "EnvMacros", type: "EnvMacro")

// MARK: - @Value Macro

/// Declares which configuration key backs a property, and what it falls back to.
///
/// Attach to a stored property of an `@Env` struct. The macro generates no code on its own; it
/// carries the key and default that `@Env` reads when it builds the initializer.
///
/// ## Key naming
///
/// Keys are written dot-separated and mapped to environment variable names by
/// swift-configuration's `EnvironmentVariablesProvider`, which uppercases each segment and joins
/// them with underscores:
///
/// - `gcp.project.id` → `GCP_PROJECT_ID`
/// - `firebase.emulator` → `FIREBASE_EMULATOR`
/// - `server.port` → `SERVER_PORT`
///
/// A different provider maps the same key differently; the key, not the variable name, is what
/// this macro declares.
///
/// ## Supported types
///
/// `String`, `Int`, `Double`, and `Bool` map to the reader's matching accessor. A
/// `RawRepresentable` type with a `String` raw value is stored as its raw string and restored via
/// `init(rawValue:)`, falling back to the default when the stored string matches no case. Any
/// other type falls through to the string accessor and fails to compile with a type mismatch
/// rather than a diagnostic naming the unsupported type.
///
/// For every supported type, a value that fails to convert resolves to the default silently.
///
/// ## Example
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
///   - key: The dot-separated configuration key. Must be a string literal; the macro reads it at
///     compile time and cannot see an interpolated or computed value.
///   - default: The value used when the key is absent or its value cannot be converted.
@attached(peer)
public macro Value<T>(_ key: String, default: T) = #externalMacro(module: "EnvMacros", type: "ValueMacro")

// MARK: - @EnvGroup Macro

/// Assembles several configuration structs into one, and adds a factory that reads the process
/// environment.
///
/// Attach to a struct whose stored properties are themselves `@Env` or `@EnvGroup` types. The
/// macro generates:
/// - `init(config: ConfigReader)`, which initializes every child from the same reader
/// - `static func load() -> Self`, which builds its own reader over the process environment
/// - conformance to `EnvConfigurable`
///
/// Every stored property is treated as a child regardless of its type, so a property that is not
/// `EnvConfigurable` fails to compile inside the generated initializer.
///
/// ## Choosing between `load()` and `init(config:)`
///
/// `load()` always reads the process environment and ignores any other source, which makes it
/// unsuitable for tests and for applications that layer in a file or a remote provider. Pass an
/// explicit reader to `init(config:)` in those cases.
///
/// Code calling `load()` must `import Configuration`; the generated body names
/// `EnvironmentVariablesProvider`, which importing this module alone does not bring into scope.
///
/// ## Example
///
/// ```swift
/// import Configuration
/// import Env
///
/// @EnvGroup
/// public struct AppConfig {
///     let gcp: GCPConfig
///     let emulator: EmulatorConfig
/// }
///
/// let app = AppConfig.load()
/// print(app.gcp.projectId)
/// ```
///
/// - Parameter scope: A prefix prepended to every child's keys, so a child of
///   `@EnvGroup(scope: "database")` reads `DATABASE_*`. Omit to read at the root.
@attached(member, names: named(init), named(load))
@attached(extension, conformances: EnvConfigurable)
public macro EnvGroup(
    scope: String? = nil
) = #externalMacro(module: "EnvMacros", type: "EnvGroupMacro")
