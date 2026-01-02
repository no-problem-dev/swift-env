import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - EnvGroupMacro

/// `@EnvGroup`マクロの実装
///
/// このマクロは構造体に付与され、以下を生成します:
/// - `init(config: ConfigReader)` イニシャライザ
/// - `static func load() -> Self` ファクトリメソッド
/// - `EnvConfigurable` プロトコル準拠
public struct EnvGroupMacro {}

// MARK: - MemberMacro

extension EnvGroupMacro: MemberMacro {
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
        let properties = collectProperties(from: structDecl)

        guard !properties.isEmpty else {
            return []
        }

        var members: [DeclSyntax] = []

        // initを生成
        members.append(generateInit(properties: properties, scope: scope))

        // load()を生成
        members.append(generateLoad())

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
    private static func collectProperties(from structDecl: StructDeclSyntax) -> [GroupPropertyInfo] {
        var properties: [GroupPropertyInfo] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            // 計算プロパティは除外
            guard isStoredProperty(varDecl) else {
                continue
            }

            // プロパティ名と型を取得
            guard let binding = varDecl.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = binding.typeAnnotation else {
                continue
            }

            let propertyName = pattern.identifier.text
            let typeName = typeAnnotation.type.description.trimmingCharacters(in: .whitespaces)

            properties.append(GroupPropertyInfo(
                name: propertyName,
                typeName: typeName
            ))
        }

        return properties
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

    /// initを生成
    private static func generateInit(properties: [GroupPropertyInfo], scope: String?) -> DeclSyntax {
        var lines: [String] = []

        lines.append("public init(config: ConfigReader) {")

        // scopeがある場合はscopedReaderを作成
        if let scope = scope {
            lines.append("    let scopedConfig = config.scoped(to: \"\(scope)\")")
        }

        let configVar = scope != nil ? "scopedConfig" : "config"

        for prop in properties {
            lines.append("    self.\(prop.name) = \(prop.typeName)(config: \(configVar))")
        }

        lines.append("}")

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    /// load()を生成
    private static func generateLoad() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
            public static func load() -> Self {
                let reader = ConfigReader(provider: EnvironmentVariablesProvider())
                return Self(config: reader)
            }
            """)
    }
}

// MARK: - ExtensionMacro

extension EnvGroupMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let ext: DeclSyntax = """
            extension \(type.trimmed): EnvConfigurable {}
            """

        guard let extensionDecl = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDecl]
    }
}

// MARK: - Supporting Types

/// EnvGroupプロパティ情報
struct GroupPropertyInfo {
    let name: String
    let typeName: String
}
