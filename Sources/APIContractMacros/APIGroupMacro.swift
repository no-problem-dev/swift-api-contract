import SwiftSyntax
import SwiftSyntaxMacros

/// APIグループを定義するマクロ
///
/// enumに付与して、関連するエンドポイントをグループ化します。
/// `APIContractGroup`プロトコルへの準拠と、`basePath`・`auth`プロパティを自動生成します。
public struct APIGroupMacro: MemberMacro, ExtensionMacro {

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // enumにのみ適用可能
        guard declaration.is(EnumDeclSyntax.self) else {
            throw APIGroupMacroError.onlyApplicableToEnum
        }

        // マクロ引数を解析
        let arguments = try parseArguments(from: node)

        var members: [DeclSyntax] = []

        // static let basePath: String
        members.append("public static let basePath: String = \"\(raw: arguments.path)\"")

        // static let auth: AuthRequirement
        members.append("public static let auth: AuthRequirement = .\(raw: arguments.auth)")

        return members
    }

    // MARK: - ExtensionMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // enumでない場合は空の配列を返す（エラーはMemberMacroで報告済み）
        guard declaration.is(EnumDeclSyntax.self) else {
            return []
        }

        let extensionDecl: DeclSyntax = """
        extension \(type.trimmed): APIContractGroup {}
        """

        guard let extensionDeclSyntax = extensionDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDeclSyntax]
    }

    // MARK: - Private Helpers

    private static func parseArguments(from node: AttributeSyntax) throws -> APIGroupArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw APIGroupMacroError.invalidArguments
        }

        var path: String = ""
        var auth: String = "required"

        for argument in arguments {
            switch argument.label?.text {
            case "path":
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    path = segment.content.text
                }
            case "auth":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    auth = memberAccess.declName.baseName.text
                }
            default:
                continue
            }
        }

        return APIGroupArguments(path: path, auth: auth)
    }
}

// MARK: - Supporting Types

private struct APIGroupArguments {
    let path: String
    let auth: String
}

// MARK: - Errors

enum APIGroupMacroError: Error, CustomStringConvertible {
    case onlyApplicableToEnum
    case invalidArguments

    var description: String {
        switch self {
        case .onlyApplicableToEnum:
            return "@APIGroup can only be applied to enums"
        case .invalidArguments:
            return "@APIGroup requires 'path' argument"
        }
    }
}
