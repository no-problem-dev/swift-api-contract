import SwiftSyntax
import SwiftSyntaxMacros

/// HTTPヘッダーをマークするマクロ
///
/// `@Endpoint` マクロがプロパティを HTTPヘッダーとして認識するためのマーカー。
/// 単体では何も生成しない。
public struct HeaderMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // プロパティにのみ適用可能
        guard declaration.is(VariableDeclSyntax.self) else {
            throw HeaderMacroError.onlyApplicableToProperty
        }

        // マーカーマクロなので何も生成しない
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
