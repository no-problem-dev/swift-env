import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct EnvMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EnvMacro.self,
        ValueMacro.self,
        EnvGroupMacro.self,
    ]
}
