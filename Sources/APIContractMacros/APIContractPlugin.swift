import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct APIContractPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        APIGroupMacro.self,
        EndpointMacro.self,
        PathParamMacro.self,
        QueryParamMacro.self,
        BodyMacro.self,
    ]
}
