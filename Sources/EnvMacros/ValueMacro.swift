import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - ValueMacro

/// `@Value`マクロの実装
///
/// このマクロはプロパティに付与され、環境変数のキーとデフォルト値を
/// `@Env`マクロに伝達します。このマクロ自体はコードを生成しません。
public struct ValueMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // @Valueはマーカーとして機能し、コード生成は行わない
        // 実際の処理は@EnvMacroが行う
        return []
    }
}
