import Foundation

/// A failure raised during macro expansion and surfaced to the caller as a compiler error.
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
