import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - EnvMacro

/// Implements `@Env`, generating the key table, the default table, and the initializer that
/// resolves every `@Value` property from a reader.
public struct EnvMacro {}

// MARK: - MemberMacro

extension EnvMacro: MemberMacro {
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

        let properties = try collectProperties(from: structDecl)

        // No `@Value` property means no initializer, while the extension macro still adds the
        // conformance that requires one. The caller sees an unsatisfied-conformance error.
        guard !properties.isEmpty else {
            return []
        }

        var members: [DeclSyntax] = []

        members.append(generateKeysEnum(properties: properties))

        members.append(generateDefaultsEnum(properties: properties))

        members.append(generateInit(properties: properties, scope: scope))

        return members
    }

    // MARK: - Private Helpers

    /// Collects one entry per stored property carrying `@Value`, skipping every other member.
    private static func collectProperties(from structDecl: StructDeclSyntax) throws -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            guard isStoredProperty(varDecl) else {
                continue
            }

            guard let valueInfo = extractValueInfo(from: varDecl) else {
                continue
            }

            guard let binding = varDecl.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }

            let propertyName = pattern.identifier.text

            // A property without an explicit type annotation is skipped rather than diagnosed,
            // so `@Value("k", default: 1) var n = 0` silently drops out of the generated code.
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

    /// Reads the key and default out of a `@Value` attribute, if the property carries one.
    ///
    /// Both must be present for the property to be usable; a partially written attribute yields
    /// `nil` and the property is skipped.
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
                    // Only the first segment is read, so an interpolated key silently truncates
                    // to its literal prefix.
                    if let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
                       let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                        key = segment.content.text
                    }
                } else if arg.label?.text == "default" {
                    defaultValue = arg.expression.description.trimmingCharacters(in: .whitespaces)
                }
            }

            if let key = key, let defaultValue = defaultValue {
                return (key, defaultValue)
            }
        }

        return nil
    }

    private static func generateKeysEnum(properties: [PropertyInfo]) -> DeclSyntax {
        var lines: [String] = []
        lines.append("private enum Keys {")

        for prop in properties {
            lines.append("    static let \(prop.name): ConfigKey = \"\(prop.key)\"")
        }

        lines.append("}")

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    private static func generateDefaultsEnum(properties: [PropertyInfo]) -> DeclSyntax {
        var lines: [String] = []
        lines.append("private enum Defaults {")

        for prop in properties {
            // A shorthand enum case carries no type of its own, so the annotation is required for
            // the constant to type-check. A qualified `TypeName.case` already infers correctly.
            if prop.defaultValue.hasPrefix(".") {
                lines.append("    static let \(prop.name): \(prop.typeName) = \(prop.defaultValue)")
            } else {
                lines.append("    static let \(prop.name) = \(prop.defaultValue)")
            }
        }

        lines.append("}")

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    private static func generateInit(properties: [PropertyInfo], scope: String?) -> DeclSyntax {
        var lines: [String] = []

        lines.append("public init(config: ConfigReader) {")

        if let scope = scope {
            lines.append("    let scopedConfig = config.scoped(to: \"\(scope)\")")
        }

        let configVar = scope != nil ? "scopedConfig" : "config"

        for prop in properties {
            let assignment = generatePropertyAssignment(prop: prop, configVar: configVar)
            lines.append("    \(assignment)")
        }

        lines.append("}")

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    /// Emits the read for one property.
    ///
    /// Every branch uses the reader's `default:` overload, which returns the default when the key
    /// is missing *or* when its value cannot be converted. Nothing here can surface a malformed
    /// value to the caller, and no branch marks the read as secret.
    private static func generatePropertyAssignment(prop: PropertyInfo, configVar: String) -> String {
        if let methodName = getPrimitiveMethodName(for: prop.typeName) {
            return "self.\(prop.name) = \(configVar).\(methodName)(forKey: Keys.\(prop.name), default: Defaults.\(prop.name))"
        }

        // Recognised by the shape of the default (`.development` or `AppEnvironment.development`),
        // not by the property's type, so a non-enum type with a leading-dot default lands here.
        if isEnumDefaultValue(prop.defaultValue, typeName: prop.typeName) {
            // Round-trips through the raw string; an unrecognised case falls back to the default.
            return "self.\(prop.name) = \(prop.typeName)(rawValue: \(configVar).string(forKey: Keys.\(prop.name), default: Defaults.\(prop.name).rawValue)) ?? Defaults.\(prop.name)"
        }

        // Unsupported types reach here and emit a `String` read, which fails to compile at the
        // assignment rather than reporting the unsupported type.
        return "self.\(prop.name) = \(configVar).string(forKey: Keys.\(prop.name), default: Defaults.\(prop.name))"
    }

    /// Reports whether the default looks like an enum case, in either shorthand or qualified form.
    private static func isEnumDefaultValue(_ defaultValue: String, typeName: String) -> Bool {
        if defaultValue.hasPrefix(".") {
            return true
        }
        if defaultValue.hasPrefix("\(typeName).") {
            return true
        }
        return false
    }

    /// Maps a type name to the reader accessor that reads it, or `nil` when there is no direct one.
    private static func getPrimitiveMethodName(for typeName: String) -> String? {
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
            return nil
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
            extension \(type.trimmed): EnvConfigurable {}
            """

        guard let extensionDecl = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDecl]
    }
}

// MARK: - Supporting Types

/// One `@Value` property, reduced to the four strings the generated code is built from.
struct PropertyInfo {
    let name: String
    let key: String
    let defaultValue: String
    /// Source text of the type annotation, matched literally against the supported type names.
    let typeName: String
}
