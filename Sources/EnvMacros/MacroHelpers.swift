import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Shared Macro Helpers

/// Reads the `scope:` argument off `@Env` or `@EnvGroup`, or `nil` when it was omitted.
///
/// Only the first segment of the literal is read, so an interpolated scope silently truncates to
/// its literal prefix.
func extractScope(from node: AttributeSyntax) -> String? {
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

/// Reports whether the declaration is a stored property rather than a computed one.
///
/// Detection is by the presence of a `get` accessor, so a property with only `willSet`/`didSet`
/// is correctly treated as stored.
func isStoredProperty(_ varDecl: VariableDeclSyntax) -> Bool {
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
