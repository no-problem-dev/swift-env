import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(EnvMacros)
import EnvMacros

// swiftlint:disable:next identifier_name
nonisolated(unsafe) let testMacros: [String: Macro.Type] = [
    "Env": EnvMacro.self,
    "Value": ValueMacro.self,
]
#endif

final class EnvMacrosTests: XCTestCase {

    // MARK: - Basic Tests

    func testEnvBasicStringProperty() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env
            struct TestConfig {
                @Value("test.key", default: "default-value")
                var testKey: String
            }
            """,
            expandedSource: """
            struct TestConfig {
                var testKey: String

                private enum Keys {
                    static let testKey: ConfigKey = "test.key"
                }

                private enum Defaults {
                    static let testKey = "default-value"
                }

                public init(config: ConfigReader) {
                    self.testKey = config.string(forKey: Keys.testKey, default: Defaults.testKey)
                }
            }

            extension TestConfig: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testEnvIntProperty() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env
            struct ServerConfig {
                @Value("server.port", default: 8080)
                var port: Int
            }
            """,
            expandedSource: """
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

            extension ServerConfig: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testEnvBoolProperty() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env
            struct FeatureFlags {
                @Value("feature.enabled", default: false)
                var isEnabled: Bool
            }
            """,
            expandedSource: """
            struct FeatureFlags {
                var isEnabled: Bool

                private enum Keys {
                    static let isEnabled: ConfigKey = "feature.enabled"
                }

                private enum Defaults {
                    static let isEnabled = false
                }

                public init(config: ConfigReader) {
                    self.isEnabled = config.bool(forKey: Keys.isEnabled, default: Defaults.isEnabled)
                }
            }

            extension FeatureFlags: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testEnvDoubleProperty() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env
            struct GameBalance {
                @Value("game.rate", default: 0.05)
                var rate: Double
            }
            """,
            expandedSource: """
            struct GameBalance {
                var rate: Double

                private enum Keys {
                    static let rate: ConfigKey = "game.rate"
                }

                private enum Defaults {
                    static let rate = 0.05
                }

                public init(config: ConfigReader) {
                    self.rate = config.double(forKey: Keys.rate, default: Defaults.rate)
                }
            }

            extension GameBalance: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Multiple Properties Tests

    func testEnvMultipleProperties() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env
            struct GCPConfig {
                @Value("gcp.project.id", default: "my-project")
                var projectId: String

                @Value("firebase.emulator", default: false)
                var useEmulator: Bool
            }
            """,
            expandedSource: """
            struct GCPConfig {
                var projectId: String
                var useEmulator: Bool

                private enum Keys {
                    static let projectId: ConfigKey = "gcp.project.id"
                    static let useEmulator: ConfigKey = "firebase.emulator"
                }

                private enum Defaults {
                    static let projectId = "my-project"
                    static let useEmulator = false
                }

                public init(config: ConfigReader) {
                    self.projectId = config.string(forKey: Keys.projectId, default: Defaults.projectId)
                    self.useEmulator = config.bool(forKey: Keys.useEmulator, default: Defaults.useEmulator)
                }
            }

            extension GCPConfig: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Scope Tests

    func testEnvWithScope() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env(scope: "emulator")
            struct EmulatorConfig {
                @Value("firestore.host", default: "localhost")
                var firestoreHost: String

                @Value("firestore.port", default: 8090)
                var firestorePort: Int
            }
            """,
            expandedSource: """
            struct EmulatorConfig {
                var firestoreHost: String
                var firestorePort: Int

                private enum Keys {
                    static let firestoreHost: ConfigKey = "firestore.host"
                    static let firestorePort: ConfigKey = "firestore.port"
                }

                private enum Defaults {
                    static let firestoreHost = "localhost"
                    static let firestorePort = 8090
                }

                public init(config: ConfigReader) {
                    let scopedConfig = config.scoped(to: "emulator")
                    self.firestoreHost = scopedConfig.string(forKey: Keys.firestoreHost, default: Defaults.firestoreHost)
                    self.firestorePort = scopedConfig.int(forKey: Keys.firestorePort, default: Defaults.firestorePort)
                }
            }

            extension EmulatorConfig: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Real-World Use Cases

    func testEnvRealWorldGCPConfig() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env
            struct GCPConfig {
                @Value("gcp.project.id", default: "stockle-app")
                var projectId: String

                @Value("firebase.emulator", default: false)
                var useEmulator: Bool
            }
            """,
            expandedSource: """
            struct GCPConfig {
                var projectId: String
                var useEmulator: Bool

                private enum Keys {
                    static let projectId: ConfigKey = "gcp.project.id"
                    static let useEmulator: ConfigKey = "firebase.emulator"
                }

                private enum Defaults {
                    static let projectId = "stockle-app"
                    static let useEmulator = false
                }

                public init(config: ConfigReader) {
                    self.projectId = config.string(forKey: Keys.projectId, default: Defaults.projectId)
                    self.useEmulator = config.bool(forKey: Keys.useEmulator, default: Defaults.useEmulator)
                }
            }

            extension GCPConfig: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testEnvRealWorldGameBalance() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env
            struct GameBalanceConfig {
                @Value("muscle.gain.rate", default: 10.0)
                var muscleGainRate: Double

                @Value("muscle.decay.rate", default: 0.005)
                var muscleDecayRate: Double

                @Value("genetic.limit", default: 20000)
                var geneticLimit: Int
            }
            """,
            expandedSource: """
            struct GameBalanceConfig {
                var muscleGainRate: Double
                var muscleDecayRate: Double
                var geneticLimit: Int

                private enum Keys {
                    static let muscleGainRate: ConfigKey = "muscle.gain.rate"
                    static let muscleDecayRate: ConfigKey = "muscle.decay.rate"
                    static let geneticLimit: ConfigKey = "genetic.limit"
                }

                private enum Defaults {
                    static let muscleGainRate = 10.0
                    static let muscleDecayRate = 0.005
                    static let geneticLimit = 20000
                }

                public init(config: ConfigReader) {
                    self.muscleGainRate = config.double(forKey: Keys.muscleGainRate, default: Defaults.muscleGainRate)
                    self.muscleDecayRate = config.double(forKey: Keys.muscleDecayRate, default: Defaults.muscleDecayRate)
                    self.geneticLimit = config.int(forKey: Keys.geneticLimit, default: Defaults.geneticLimit)
                }
            }

            extension GameBalanceConfig: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Edge Cases

    func testEnvEmptyStruct() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env
            struct EmptyConfig {
            }
            """,
            expandedSource: """
            struct EmptyConfig {
            }

            extension EmptyConfig: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testEnvSingleProperty() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env
            struct SingleConfig {
                @Value("single.key", default: "value")
                var singleKey: String
            }
            """,
            expandedSource: """
            struct SingleConfig {
                var singleKey: String

                private enum Keys {
                    static let singleKey: ConfigKey = "single.key"
                }

                private enum Defaults {
                    static let singleKey = "value"
                }

                public init(config: ConfigReader) {
                    self.singleKey = config.string(forKey: Keys.singleKey, default: Defaults.singleKey)
                }
            }

            extension SingleConfig: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - All Types Combined

    func testEnvAllTypes() throws {
        #if canImport(EnvMacros)
        assertMacroExpansion(
            """
            @Env
            struct AllTypesConfig {
                @Value("string.value", default: "hello")
                var stringValue: String

                @Value("int.value", default: 42)
                var intValue: Int

                @Value("double.value", default: 3.14)
                var doubleValue: Double

                @Value("bool.value", default: true)
                var boolValue: Bool
            }
            """,
            expandedSource: """
            struct AllTypesConfig {
                var stringValue: String
                var intValue: Int
                var doubleValue: Double
                var boolValue: Bool

                private enum Keys {
                    static let stringValue: ConfigKey = "string.value"
                    static let intValue: ConfigKey = "int.value"
                    static let doubleValue: ConfigKey = "double.value"
                    static let boolValue: ConfigKey = "bool.value"
                }

                private enum Defaults {
                    static let stringValue = "hello"
                    static let intValue = 42
                    static let doubleValue = 3.14
                    static let boolValue = true
                }

                public init(config: ConfigReader) {
                    self.stringValue = config.string(forKey: Keys.stringValue, default: Defaults.stringValue)
                    self.intValue = config.int(forKey: Keys.intValue, default: Defaults.intValue)
                    self.doubleValue = config.double(forKey: Keys.doubleValue, default: Defaults.doubleValue)
                    self.boolValue = config.bool(forKey: Keys.boolValue, default: Defaults.boolValue)
                }
            }

            extension AllTypesConfig: Sendable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
