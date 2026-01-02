import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - EnvMacro

/// `@Env`マクロの実装
///
/// このマクロは構造体に付与され、以下を生成します:
/// - `Keys` enum（ConfigKey型の静的プロパティ）
/// - `Defaults` enum（デフォルト値の静的プロパティ）
/// - `init(config: ConfigReader)` イニシャライザ
/// - `Sendable` プロトコル準拠
public struct EnvMacro {}

// MARK: - MemberMacro

extension EnvMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 構造体であることを確認
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.requiresStruct
        }

        // scopeを取得
        let scope = extractScope(from: node)

        // プロパティ情報を収集
        let properties = try collectProperties(from: structDecl)

        guard !properties.isEmpty else {
            return []
        }

        var members: [DeclSyntax] = []

        // Keys enumを生成
        members.append(generateKeysEnum(properties: properties))

        // Defaults enumを生成
        members.append(generateDefaultsEnum(properties: properties))

        // initを生成
        members.append(generateInit(properties: properties, scope: scope))

        return members
    }

    // MARK: - Private Helpers

    /// マクロ属性からscopeを抽出
    private static func extractScope(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        for arg in arguments {
            if arg.label?.text == "scope",
               let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
               let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                return segment.content.text
            }
        }

        return nil
    }

    /// 構造体のプロパティ情報を収集
    private static func collectProperties(from structDecl: StructDeclSyntax) throws -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            // 計算プロパティは除外
            guard isStoredProperty(varDecl) else {
                continue
            }

            // @Value属性を探す
            guard let valueInfo = extractValueInfo(from: varDecl) else {
                continue
            }

            // プロパティ名を取得
            guard let binding = varDecl.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }

            let propertyName = pattern.identifier.text

            // 型を取得
            guard let typeAnnotation = binding.typeAnnotation else {
                continue
            }

            let typeName = typeAnnotation.type.description.trimmingCharacters(in: .whitespaces)

            properties.append(PropertyInfo(
                name: propertyName,
                key: valueInfo.key,
                defaultValue: valueInfo.defaultValue,
                typeName: typeName
            ))
        }

        return properties
    }

    /// @Value属性からキーとデフォルト値を抽出
    private static func extractValueInfo(from varDecl: VariableDeclSyntax) -> (key: String, defaultValue: String)? {
        for attribute in varDecl.attributes {
            guard let attr = attribute.as(AttributeSyntax.self),
                  let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
                  identifier.name.text == "Value" else {
                continue
            }

            guard let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
                continue
            }

            var key: String?
            var defaultValue: String?

            for (index, arg) in arguments.enumerated() {
                if index == 0, arg.label == nil {
                    // 最初の引数（ラベルなし）= key
                    if let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
                       let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                        key = segment.content.text
                    }
                } else if arg.label?.text == "default" {
                    // default引数
                    defaultValue = arg.expression.description.trimmingCharacters(in: .whitespaces)
                }
            }

            if let key = key, let defaultValue = defaultValue {
                return (key, defaultValue)
            }
        }

        return nil
    }

    /// 保存プロパティかどうかを判定
    private static func isStoredProperty(_ varDecl: VariableDeclSyntax) -> Bool {
        guard let binding = varDecl.bindings.first else {
            return false
        }

        if let accessorBlock = binding.accessorBlock {
            if case .accessors(let accessors) = accessorBlock.accessors {
                for accessor in accessors {
                    if accessor.accessorSpecifier.tokenKind == .keyword(.get) {
                        return false
                    }
                }
            }
        }

        return true
    }

    /// Keys enumを生成
    private static func generateKeysEnum(properties: [PropertyInfo]) -> DeclSyntax {
        var lines: [String] = []
        lines.append("private enum Keys {")

        for prop in properties {
            lines.append("    static let \(prop.name): ConfigKey = \"\(prop.key)\"")
        }

        lines.append("}")

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    /// Defaults enumを生成
    private static func generateDefaultsEnum(properties: [PropertyInfo]) -> DeclSyntax {
        var lines: [String] = []
        lines.append("private enum Defaults {")

        for prop in properties {
            lines.append("    static let \(prop.name) = \(prop.defaultValue)")
        }

        lines.append("}")

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    /// initを生成
    private static func generateInit(properties: [PropertyInfo], scope: String?) -> DeclSyntax {
        var lines: [String] = []

        lines.append("public init(config: ConfigReader) {")

        // scopeがある場合はscopedReaderを作成
        if let scope = scope {
            lines.append("    let scopedConfig = config.scoped(to: \"\(scope)\")")
        }

        let configVar = scope != nil ? "scopedConfig" : "config"

        for prop in properties {
            let methodName = getConfigMethodName(for: prop.typeName)
            lines.append("    self.\(prop.name) = \(configVar).\(methodName)(forKey: Keys.\(prop.name), default: Defaults.\(prop.name))")
        }

        lines.append("}")

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    /// 型に応じたConfigReaderメソッド名を取得
    private static func getConfigMethodName(for typeName: String) -> String {
        switch typeName {
        case "String":
            return "string"
        case "Int":
            return "int"
        case "Double":
            return "double"
        case "Bool":
            return "bool"
        default:
            // 未対応の型はstringにフォールバック
            return "string"
        }
    }
}

// MARK: - ExtensionMacro

extension EnvMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let ext: DeclSyntax = """
            extension \(type.trimmed): Sendable {}
            """

        guard let extensionDecl = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDecl]
    }
}

// MARK: - Supporting Types

/// プロパティ情報
struct PropertyInfo {
    let name: String
    let key: String
    let defaultValue: String
    let typeName: String
}
