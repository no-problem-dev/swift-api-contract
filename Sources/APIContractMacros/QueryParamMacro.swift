import SwiftSyntax
import SwiftSyntaxMacros

/// クエリパラメータをマークするマクロ
///
/// マーカーとして機能し、`@Endpoint` マクロがプロパティを
/// クエリパラメータとして認識するために使用されます。
public struct QueryParamMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // プロパティにのみ適用可能
        guard declaration.is(VariableDeclSyntax.self) else {
            throw QueryParamMacroError.onlyApplicableToProperty
        }

        // マーカーマクロなので何も生成しない
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
