import SwiftSyntax
import SwiftSyntaxMacros

/// APIグループを定義するマクロ
///
/// enumに付与して、関連するエンドポイントをグループ化します。
/// `APIContractGroup`プロトコルへの準拠と、`basePath`・`auth`・`endpoints`プロパティを自動生成します。
/// また、対応するServiceプロトコルを自動生成します。
public struct APIGroupMacro: MemberMacro, ExtensionMacro, PeerMacro {

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // enumにのみ適用可能
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw APIGroupMacroError.onlyApplicableToEnum
        }

        // マクロ引数を解析
        let arguments = try parseArguments(from: node)

        // @Endpoint付きstructを収集
        let endpointInfos = collectEndpoints(from: enumDecl)

        var members: [DeclSyntax] = []

        // static let basePath: String
        members.append("public static let basePath: String = \"\(raw: arguments.path)\"")

        // static let auth: AuthRequirement
        members.append("public static let auth: AuthRequirement = .\(raw: arguments.auth)")

        // static let endpoints: [EndpointDescriptor]
        members.append(generateEndpointsProperty(for: endpointInfos))

        // static func registerAll - 全エンドポイントを一括登録
        let enumName = enumDecl.name.text
        members.append(generateRegisterAllMethod(enumName: enumName, endpoints: endpointInfos))

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

        // APIContractGroup準拠の extension
        let conformanceDecl: DeclSyntax = """
        extension \(type.trimmed): APIContractGroup {}
        """

        guard let extensionDeclSyntax = conformanceDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDeclSyntax]
    }

    // MARK: - PeerMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // enumにのみ適用可能
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }

        let enumName = enumDecl.name.text

        // @Endpoint付きstructを収集
        let endpointInfos = collectEndpoints(from: enumDecl)

        // Serviceプロトコルを生成（PeerMacroで生成可能）
        return [generateServiceProtocol(enumName: enumName, endpoints: endpointInfos)]
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

    /// enum内の@Endpoint付きstructを収集
    private static func collectEndpoints(from enumDecl: EnumDeclSyntax) -> [EndpointInfo] {
        var endpoints: [EndpointInfo] = []

        for member in enumDecl.memberBlock.members {
            guard let structDecl = member.decl.as(StructDeclSyntax.self) else {
                continue
            }

            // @Endpoint属性を探す
            for attribute in structDecl.attributes {
                guard let attr = attribute.as(AttributeSyntax.self),
                      let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
                      identifier.name.text == "Endpoint" else {
                    continue
                }

                // @Endpoint引数を解析
                let (method, path) = parseEndpointArguments(from: attr)
                let name = structDecl.name.text

                // Output型を取得
                let outputType = findOutputType(from: structDecl)

                endpoints.append(EndpointInfo(
                    name: name,
                    method: method,
                    path: path,
                    outputType: outputType
                ))
                break
            }
        }

        return endpoints
    }

    /// @Endpoint属性からmethodとpathを抽出
    private static func parseEndpointArguments(from attr: AttributeSyntax) -> (method: String, path: String) {
        var method = "get"
        var path = ""

        guard let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
            return (method, path)
        }

        for argument in arguments {
            if argument.label == nil {
                // 最初の引数（method）
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    method = memberAccess.declName.baseName.text
                }
            } else if argument.label?.text == "path" {
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    path = segment.content.text
                }
            }
        }

        return (method, path)
    }

    /// struct内のOutput typealiasを探す
    private static func findOutputType(from structDecl: StructDeclSyntax) -> String {
        for member in structDecl.memberBlock.members {
            guard let typealiasDecl = member.decl.as(TypeAliasDeclSyntax.self),
                  typealiasDecl.name.text == "Output" else {
                continue
            }
            return typealiasDecl.initializer.value.trimmedDescription
        }
        return "Void"
    }

    /// endpoints静的プロパティを生成
    private static func generateEndpointsProperty(for endpoints: [EndpointInfo]) -> DeclSyntax {
        if endpoints.isEmpty {
            return "public static let endpoints: [EndpointDescriptor] = []"
        }

        let descriptors = endpoints.map { endpoint in
            """
            EndpointDescriptor(name: "\(endpoint.name)", method: .\(endpoint.method), subPath: "\(endpoint.path)")
            """
        }.joined(separator: ",\n        ")

        return DeclSyntax(stringLiteral: """
        public static let endpoints: [EndpointDescriptor] = [
                \(descriptors)
            ]
        """)
    }

    /// Serviceプロトコルを生成
    private static func generateServiceProtocol(enumName: String, endpoints: [EndpointInfo]) -> DeclSyntax {
        let serviceProtocolName = "\(enumName)Service"

        if endpoints.isEmpty {
            return DeclSyntax(stringLiteral: """
            public protocol \(serviceProtocolName): APIService where Group == \(enumName) {
            }
            """)
        }

        let handleMethods = endpoints.map { endpoint in
            let returnType = endpoint.outputType == "Void" || endpoint.outputType == "EmptyOutput"
                ? ""
                : " -> \(endpoint.outputType)"
            return "    func handle(_ input: \(enumName).\(endpoint.name), context: ServiceContext) async throws\(returnType)"
        }.joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        public protocol \(serviceProtocolName): APIService where Group == \(enumName) {
        \(handleMethods)
        }
        """)
    }

    /// registerAll static メソッドを生成
    private static func generateRegisterAllMethod(enumName: String, endpoints: [EndpointInfo]) -> DeclSyntax {
        let serviceProtocolName = "\(enumName)Service"

        if endpoints.isEmpty {
            return DeclSyntax(stringLiteral: """
            @discardableResult
                public static func registerAll<R: APIRouteRegistrar>(_ routes: R) -> R where R.Group == \(enumName), R.Service: \(serviceProtocolName) {
                    return routes
                }
            """)
        }

        // 各エンドポイントの登録コードを生成
        let registrations = endpoints.enumerated().map { (index, endpoint) in
            let isFirst = index == 0
            let prefix = isFirst ? "routes" : ""
            return """
            \(prefix).register(\(enumName).\(endpoint.name).self) { input, ctx in
                        try await routes.service.handle(input, context: ctx)
                    }
            """
        }.joined(separator: "\n            ")

        return DeclSyntax(stringLiteral: """
        @discardableResult
            public static func registerAll<R: APIRouteRegistrar>(_ routes: R) -> R where R.Group == \(enumName), R.Service: \(serviceProtocolName) {
                \(registrations)
                return routes
            }
        """)
    }
}

// MARK: - Supporting Types

private struct APIGroupArguments {
    let path: String
    let auth: String
}

private struct EndpointInfo {
    let name: String
    let method: String
    let path: String
    let outputType: String
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
