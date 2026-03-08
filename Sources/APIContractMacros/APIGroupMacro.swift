import SwiftSyntax
import SwiftSyntaxMacros

/// APIグループを定義するマクロ
public struct APIGroupMacro: MemberMacro, ExtensionMacro, PeerMacro {

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw APIGroupMacroError.onlyApplicableToEnum
        }

        let arguments = try parseArguments(from: node)
        let endpointInfos = collectEndpoints(from: enumDecl)

        var members: [DeclSyntax] = []

        // static let basePath: String
        members.append("public static let basePath: String = \"\(raw: arguments.path)\"")

        // static let auth: AuthScheme
        members.append("public static let auth: AuthScheme = \(raw: arguments.authExpression)")

        // static let commonHeaders: [String: String]
        if arguments.headers.isEmpty {
            members.append("public static let commonHeaders: [String: String] = [:]")
        } else {
            let headerEntries = arguments.headers.map { key, value in
                "\"\(key)\": \"\(value)\""
            }.joined(separator: ", ")
            members.append(DeclSyntax(stringLiteral: "public static let commonHeaders: [String: String] = [\(headerEntries)]"))
        }

        // static let endpoints: [EndpointDescriptor]
        members.append(generateEndpointsProperty(for: endpointInfos))

        // static func registerAll
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
        guard declaration.is(EnumDeclSyntax.self) else {
            return []
        }

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
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }

        let enumName = enumDecl.name.text
        let endpointInfos = collectEndpoints(from: enumDecl)

        return [generateServiceProtocol(enumName: enumName, endpoints: endpointInfos)]
    }

    // MARK: - Private Helpers

    private static func parseArguments(from node: AttributeSyntax) throws -> APIGroupArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw APIGroupMacroError.invalidArguments
        }

        var path: String = ""
        var authExpression: String = ".bearer"
        var headers: [(String, String)] = []

        for argument in arguments {
            switch argument.label?.text {
            case "path":
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    path = segment.content.text
                }
            case "auth":
                // AuthScheme の式をそのまま文字列として保持
                authExpression = argument.expression.trimmedDescription
            case "headers":
                headers = parseDictionaryLiteral(from: argument.expression)
            default:
                continue
            }
        }

        return APIGroupArguments(path: path, authExpression: authExpression, headers: headers)
    }

    /// [String: String] リテラルをパース
    private static func parseDictionaryLiteral(from expr: ExprSyntax) -> [(String, String)] {
        guard let dictExpr = expr.as(DictionaryExprSyntax.self) else {
            return []
        }

        guard case .elements(let elements) = dictExpr.content else {
            return []
        }

        var result: [(String, String)] = []
        for element in elements {
            if let keyLiteral = element.key.as(StringLiteralExprSyntax.self),
               let keySegment = keyLiteral.segments.first?.as(StringSegmentSyntax.self),
               let valueLiteral = element.value.as(StringLiteralExprSyntax.self),
               let valueSegment = valueLiteral.segments.first?.as(StringSegmentSyntax.self) {
                result.append((keySegment.content.text, valueSegment.content.text))
            }
        }
        return result
    }

    /// enum内の@Endpoint付きstructを収集
    private static func collectEndpoints(from enumDecl: EnumDeclSyntax) -> [EndpointInfo] {
        var endpoints: [EndpointInfo] = []

        for member in enumDecl.memberBlock.members {
            guard let structDecl = member.decl.as(StructDeclSyntax.self) else {
                continue
            }

            for attribute in structDecl.attributes {
                guard let attr = attribute.as(AttributeSyntax.self),
                      let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
                      identifier.name.text == "Endpoint" else {
                    continue
                }

                let (method, path) = parseEndpointArguments(from: attr)
                let name = structDecl.name.text
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

    private static func parseEndpointArguments(from attr: AttributeSyntax) -> (method: String, path: String) {
        var method = "get"
        var path = ""

        guard let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
            return (method, path)
        }

        for argument in arguments {
            if argument.label == nil {
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

        let registrations = endpoints.enumerated().map { (index, endpoint) in
            let prefix = index == 0 ? "routes" : ""
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
    let authExpression: String
    let headers: [(String, String)]
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
