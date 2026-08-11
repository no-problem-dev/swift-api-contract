import SwiftSyntax
import SwiftSyntaxMacros

/// Implements `@Body`. A marker only: `@Endpoint` reads the attribute off the property and
/// generates everything, so this expansion produces nothing.
public struct BodyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(VariableDeclSyntax.self) else {
            throw BodyMacroError.onlyApplicableToProperty
        }

        return []
    }
}

// MARK: - Errors

enum BodyMacroError: Error, CustomStringConvertible {
    case onlyApplicableToProperty

    var description: String {
        switch self {
        case .onlyApplicableToProperty:
            return "@Body can only be applied to properties"
        }
    }
}
