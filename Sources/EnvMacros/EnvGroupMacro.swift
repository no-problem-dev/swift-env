import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - EnvGroupMacro

/// Implements `@EnvGroup`, generating an initializer that forwards one reader to every child and
/// a `load()` factory that builds a reader over the process environment.
public struct EnvGroupMacro {}

// MARK: - MemberMacro

extension EnvGroupMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.requiresStruct
        }

        let scope = extractScope(from: node)

        let properties = collectProperties(from: structDecl)

        // An empty struct generates neither member, while the extension macro still adds the
        // conformance that requires the initializer.
        guard !properties.isEmpty else {
            return []
        }

        var members: [DeclSyntax] = []

        members.append(generateInit(properties: properties, scope: scope))

        members.append(generateLoad())

        return members
    }

    // MARK: - Private Helpers

    /// Collects every stored property as a child.
    ///
    /// Nothing checks that the property's type is `EnvConfigurable`; a type that is not one fails
    /// to compile inside the generated initializer instead of being diagnosed here.
    private static func collectProperties(from structDecl: StructDeclSyntax) -> [GroupPropertyInfo] {
        var properties: [GroupPropertyInfo] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            guard isStoredProperty(varDecl) else {
                continue
            }

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

    private static func generateInit(properties: [GroupPropertyInfo], scope: String?) -> DeclSyntax {
        var lines: [String] = []

        lines.append("public init(config: ConfigReader) {")

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

    /// Emits `load()`, which reads the process environment and nothing else.
    ///
    /// The body names `EnvironmentVariablesProvider`, so calling code must `import Configuration`
    /// even though it only imported this package's public module.
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

/// One child of an `@EnvGroup`, reduced to the strings the generated initializer is built from.
struct GroupPropertyInfo {
    let name: String
    let typeName: String
}
