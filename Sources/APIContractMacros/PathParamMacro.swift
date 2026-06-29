import SwiftSyntax
import SwiftSyntaxMacros

/// パスパラメータをマークするマクロ
///
/// `@Endpoint` マクロがプロパティをパスパラメータとして認識するためのマーカー。
/// 単体では何も生成しない。
public struct PathParamMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // プロパティにのみ適用可能
        guard declaration.is(VariableDeclSyntax.self) else {
            throw PathParamMacroError.onlyApplicableToProperty
        }

        // マーカーマクロなので何も生成しない
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
