import SwiftSyntax
import SwiftSyntaxMacros

/// リクエストボディをマークするマクロ
///
/// マーカーとして機能し、`@Endpoint` マクロがプロパティを
/// リクエストボディとして認識するために使用されます。
public struct BodyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // プロパティにのみ適用可能
        guard declaration.is(VariableDeclSyntax.self) else {
            throw BodyMacroError.onlyApplicableToProperty
        }

        // マーカーマクロなので何も生成しない
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
