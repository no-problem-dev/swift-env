import Foundation

/// マクロ展開時のエラー
enum MacroError: Error, CustomStringConvertible {
    case requiresStruct
    case missingValueAttribute
    case invalidValueArguments
    case unsupportedType(String)
    case message(String)

    var description: String {
        switch self {
        case .requiresStruct:
            return "@Env can only be applied to struct declarations"
        case .missingValueAttribute:
            return "Properties in @Env struct must have @Value attribute"
        case .invalidValueArguments:
            return "@Value requires key and default arguments: @Value(\"key\", default: value)"
        case .unsupportedType(let type):
            return "Unsupported type '\(type)'. Supported types: String, Int, Double, Bool"
        case .message(let message):
            return message
        }
    }
}
