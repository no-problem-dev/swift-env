import Foundation

/// マクロ展開時のエラー
enum MacroError: Error, CustomStringConvertible {
    case requiresStruct
    case message(String)

    var description: String {
        switch self {
        case .requiresStruct:
            return "@Env and @EnvGroup can only be applied to struct declarations"
        case .message(let message):
            return message
        }
    }
}
