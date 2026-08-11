import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - ValueMacro

/// Implements `@Value` as a marker that carries a key and a default for `@Env` to read.
///
/// Declared as a peer macro purely so the attribute is legal on a property; it deliberately
/// generates nothing, and applying it outside an `@Env` struct therefore has no effect at all.
public struct ValueMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
