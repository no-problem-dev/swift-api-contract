import SwiftSyntax
import SwiftSyntaxMacros

/// Implements `@Header`. A marker only: `@Endpoint` reads the attribute, including its header
/// name argument, and generates everything, so this expansion produces nothing.
public struct HeaderMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(VariableDeclSyntax.self) else {
            throw HeaderMacroError.onlyApplicableToProperty
        }

        return []
    }
}

// MARK: - Errors

enum HeaderMacroError: Error, CustomStringConvertible {
    case onlyApplicableToProperty

    var description: String {
        switch self {
        case .onlyApplicableToProperty:
            return "@Header can only be applied to properties"
        }
    }
}
