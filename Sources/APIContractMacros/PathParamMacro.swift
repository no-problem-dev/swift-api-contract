import SwiftSyntax
import SwiftSyntaxMacros

/// Implements `@PathParam`. A marker only: `@Endpoint` reads the attribute off the property and
/// generates everything, so this expansion produces nothing.
public struct PathParamMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(VariableDeclSyntax.self) else {
            throw PathParamMacroError.onlyApplicableToProperty
        }

        return []
    }
}

// MARK: - Errors

enum PathParamMacroError: Error, CustomStringConvertible {
    case onlyApplicableToProperty

    var description: String {
        switch self {
        case .onlyApplicableToProperty:
            return "@PathParam can only be applied to properties"
        }
    }
}
