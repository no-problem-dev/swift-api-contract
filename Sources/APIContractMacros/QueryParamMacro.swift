import SwiftSyntax
import SwiftSyntaxMacros

/// Implements `@QueryParam`. A marker only: `@Endpoint` reads the attribute, including its
/// `name:` argument, and generates everything, so this expansion produces nothing.
public struct QueryParamMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(VariableDeclSyntax.self) else {
            throw QueryParamMacroError.onlyApplicableToProperty
        }

        return []
    }
}

// MARK: - Errors

enum QueryParamMacroError: Error, CustomStringConvertible {
    case onlyApplicableToProperty

    var description: String {
        switch self {
        case .onlyApplicableToProperty:
            return "@QueryParam can only be applied to properties"
        }
    }
}
