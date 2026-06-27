import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Shared Macro Helpers

/// マクロ属性から `scope:` 引数の値を抽出する
///
/// `@Env(scope: "prefix")` や `@EnvGroup(scope: "prefix")` で共通利用。
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

/// 計算プロパティを除いた保存プロパティかどうかを判定する
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
