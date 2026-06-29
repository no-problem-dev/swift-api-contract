import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

/// ストリーミングエンドポイントを定義するマクロ
///
/// struct に付与して `StreamingAPIContract` と `APIInput` への準拠を自動生成する。
/// `@Endpoint` との違いは `Output` の代わりに `Event` 型を使う点。
public struct StreamingEndpointMacro: MemberMacro, ExtensionMacro {

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw StreamingEndpointMacroError.onlyApplicableToStruct
        }

        let arguments = try parseArguments(from: node)
        let properties = try collectProperties(from: structDecl)
        let parentEnumName = findParentEnumName(in: context)

        var members: [DeclSyntax] = []

        members.append("public typealias Input = Self")

        if let groupName = parentEnumName {
            members.append("public typealias Group = \(raw: groupName)")
        }

        members.append("public static let method: APIMethod = .\(raw: arguments.method)")
        members.append("public static let subPath: String = \"\(raw: arguments.path)\"")

        // requiredScopes（スコープ指定があるときのみ。未指定ならグループ既定を継承）
        if !arguments.scopes.isEmpty {
            members.append("public static let requiredScopes: [String] = \(raw: stringArraySource(arguments.scopes))")
        }

        // pathParameters
        let pathParamProperties = properties.filter { $0.kind == .pathParam }
        if pathParamProperties.isEmpty {
            members.append("public var pathParameters: [String: String] { [:] }")
        } else {
            let pathParamEntries = pathParamProperties.map { prop in
                "\"\(prop.name)\": \(prop.name)"
            }.joined(separator: ", ")
            members.append("public var pathParameters: [String: String] { [\(raw: pathParamEntries)] }")
        }

        // queryParameters
        let queryParamProperties = properties.filter { $0.kind == .queryParam }
        members.append(generateQueryParametersProperty(for: queryParamProperties))

        // additionalHeaders
        let headerProperties = properties.filter { $0.kind == .header }
        members.append(generateAdditionalHeadersProperty(for: headerProperties))

        // encodeBody
        let bodyProperty = properties.first { $0.kind == .body }
        members.append(generateEncodeBodyMethod(for: bodyProperty))

        // init
        members.append(generateInitializer(for: properties))

        // decode (excludes header properties)
        let nonHeaderProperties = properties.filter { $0.kind != .header }
        members.append(generateDecodeMethod(for: nonHeaderProperties))

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
        guard declaration.is(StructDeclSyntax.self) else {
            return []
        }

        let extensionDecl: DeclSyntax = """
        extension \(type.trimmed): StreamingAPIContract, APIInput {}
        """

        guard let extensionDeclSyntax = extensionDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDeclSyntax]
    }

    // MARK: - Private Helpers

    private static func findParentEnumName(in context: some MacroExpansionContext) -> String? {
        for lexicalContext in context.lexicalContext {
            if let enumDecl = lexicalContext.as(EnumDeclSyntax.self) {
                return enumDecl.name.text
            }
        }
        return nil
    }

    private static func parseArguments(from node: AttributeSyntax) throws -> StreamingEndpointArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw StreamingEndpointMacroError.invalidArguments
        }

        var method: String = "get"
        var path: String = ""
        var scopes: [String] = []

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
            } else if argument.label?.text == "scopes" {
                scopes = parseStringArrayLiteral(from: argument.expression)
            }
        }

        return StreamingEndpointArguments(method: method, path: path, scopes: scopes)
    }

    private static func collectProperties(from structDecl: StructDeclSyntax) throws -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = binding.typeAnnotation else {
                continue
            }

            if pattern.identifier.text == "Event" || pattern.identifier.text == "Input" {
                continue
            }

            let name = pattern.identifier.text
            let typeName = typeAnnotation.type.trimmedDescription
            let isOptional = typeAnnotation.type.is(OptionalTypeSyntax.self)
            let kind = determinePropertyKind(from: varDecl)
            let queryName = extractQueryParamName(from: varDecl) ?? name
            let headerName = extractHeaderName(from: varDecl) ?? name
            let defaultValue = binding.initializer?.value.trimmedDescription

            properties.append(PropertyInfo(
                name: name,
                typeName: typeName,
                isOptional: isOptional,
                kind: kind,
                queryName: queryName,
                headerName: headerName,
                defaultValue: defaultValue
            ))
        }

        return properties
    }

    private static func determinePropertyKind(from varDecl: VariableDeclSyntax) -> PropertyKind {
        for attribute in varDecl.attributes {
            guard let attr = attribute.as(AttributeSyntax.self),
                  let identifier = attr.attributeName.as(IdentifierTypeSyntax.self) else {
                continue
            }

            switch identifier.name.text {
            case "PathParam":
                return .pathParam
            case "QueryParam":
                return .queryParam
            case "Body":
                return .body
            case "Header":
                return .header
            default:
                continue
            }
        }

        return .queryParam
    }

    private static func extractQueryParamName(from varDecl: VariableDeclSyntax) -> String? {
        for attribute in varDecl.attributes {
            guard let attr = attribute.as(AttributeSyntax.self),
                  let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
                  identifier.name.text == "QueryParam",
                  let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
                continue
            }

            for argument in arguments {
                if argument.label?.text == "name",
                   let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    return segment.content.text
                }
            }
        }

        return nil
    }

    private static func extractHeaderName(from varDecl: VariableDeclSyntax) -> String? {
        for attribute in varDecl.attributes {
            guard let attr = attribute.as(AttributeSyntax.self),
                  let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
                  identifier.name.text == "Header",
                  let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
                continue
            }

            for argument in arguments {
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    return segment.content.text
                }
            }
        }

        return nil
    }

    private static func generateQueryParametersProperty(for properties: [PropertyInfo]) -> DeclSyntax {
        if properties.isEmpty {
            return "public var queryParameters: [String: String]? { nil }"
        }

        var lines: [String] = []
        lines.append("public var queryParameters: [String: String]? {")
        lines.append("    var params: [String: String] = [:]")

        for prop in properties {
            let queryName = prop.queryName
            if prop.isOptional {
                lines.append("    if let \(prop.name) {")
                lines.append("        params[\"\(queryName)\"] = \(generateStringConversion(for: prop))")
                lines.append("    }")
            } else {
                lines.append("    params[\"\(queryName)\"] = \(generateStringConversion(for: prop))")
            }
        }

        lines.append("    return params.isEmpty ? nil : params")
        lines.append("}")

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    private static func generateAdditionalHeadersProperty(for properties: [PropertyInfo]) -> DeclSyntax {
        if properties.isEmpty {
            return "public var additionalHeaders: [String: String] { [:] }"
        }

        var lines: [String] = []
        lines.append("public var additionalHeaders: [String: String] {")
        lines.append("    var headers: [String: String] = [:]")

        for prop in properties {
            let headerName = prop.headerName
            if prop.isOptional {
                lines.append("    if let \(prop.name) {")
                lines.append("        headers[\"\(headerName)\"] = \(generateStringConversion(for: prop))")
                lines.append("    }")
            } else {
                lines.append("    headers[\"\(headerName)\"] = \(generateStringConversion(for: prop))")
            }
        }

        lines.append("    return headers")
        lines.append("}")

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    private static func generateStringConversion(for prop: PropertyInfo) -> String {
        let baseType = prop.typeName.replacingOccurrences(of: "?", with: "")

        switch baseType {
        case "String":
            return prop.name
        case "Int", "Int64", "Int32", "Int16", "Int8",
             "UInt", "UInt64", "UInt32", "UInt16", "UInt8",
             "Double", "Float", "Bool":
            return "String(\(prop.name))"
        case "Date":
            return "Self.encodeDate(\(prop.name))"
        default:
            return "\(prop.name).rawValue"
        }
    }

    private static func generateEncodeBodyMethod(for bodyProperty: PropertyInfo?) -> DeclSyntax {
        guard let prop = bodyProperty else {
            return """
            public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }
            """
        }

        return """
        public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? {
            try encoder.encode(\(raw: prop.name))
        }
        """
    }

    private static func generateInitializer(for properties: [PropertyInfo]) -> DeclSyntax {
        if properties.isEmpty {
            return """
            public init() {
            }
            """
        }

        let params = properties.map { prop -> String in
            if let defaultValue = prop.defaultValue {
                return "\(prop.name): \(prop.typeName) = \(defaultValue)"
            } else if prop.isOptional {
                return "\(prop.name): \(prop.typeName) = nil"
            } else {
                return "\(prop.name): \(prop.typeName)"
            }
        }.joined(separator: ", ")

        let assignments = properties.map { prop in
            "self.\(prop.name) = \(prop.name)"
        }.joined(separator: "\n    ")

        return DeclSyntax(stringLiteral: """
        public init(\(params)) {
            \(assignments)
        }
        """)
    }

    private static func generateDecodeMethod(for properties: [PropertyInfo]) -> DeclSyntax {
        if properties.isEmpty {
            return """
            public static func decode(
                pathParameters: [String: String],
                queryParameters: [String: String],
                body: Data?,
                decoder: any APIBodyDecoder
            ) throws -> Self {
                Self()
            }
            """
        }

        var lines: [String] = []
        lines.append("public static func decode(")
        lines.append("    pathParameters: [String: String],")
        lines.append("    queryParameters: [String: String],")
        lines.append("    body: Data?,")
        lines.append("    decoder: any APIBodyDecoder")
        lines.append(") throws -> Self {")

        for prop in properties {
            switch prop.kind {
            case .pathParam:
                lines.append(generatePathParamDecoding(for: prop))
            case .queryParam:
                lines.append(generateQueryParamDecoding(for: prop))
            case .body:
                lines.append(generateBodyDecoding(for: prop))
            case .header:
                break
            }
        }

        let initArgs = properties.map { "\($0.name): \($0.name)" }.joined(separator: ", ")
        lines.append("    return Self(\(initArgs))")
        lines.append("}")

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    private static func generatePathParamDecoding(for prop: PropertyInfo) -> String {
        let baseType = prop.typeName.replacingOccurrences(of: "?", with: "")

        if prop.isOptional {
            if baseType == "String" {
                return "    let \(prop.name) = pathParameters[\"\(prop.name)\"]"
            } else {
                return "    let \(prop.name) = pathParameters[\"\(prop.name)\"].flatMap { \(generateValueConversion(from: "$0", to: baseType)) }"
            }
        } else {
            if baseType == "String" {
                return """
                    guard let \(prop.name) = pathParameters["\(prop.name)"] else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing path parameter: \(prop.name)"))
                    }
                """
            } else {
                return """
                    guard let \(prop.name)String = pathParameters["\(prop.name)"],
                          let \(prop.name) = \(generateValueConversion(from: "\(prop.name)String", to: baseType)) else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing path parameter: \(prop.name)"))
                    }
                """
            }
        }
    }

    private static func generateQueryParamDecoding(for prop: PropertyInfo) -> String {
        let baseType = prop.typeName.replacingOccurrences(of: "?", with: "")

        if prop.isOptional {
            if baseType == "String" {
                return "    let \(prop.name) = queryParameters[\"\(prop.queryName)\"]"
            } else {
                return "    let \(prop.name) = queryParameters[\"\(prop.queryName)\"].flatMap { \(generateValueConversion(from: "$0", to: baseType)) }"
            }
        } else if let defaultValue = prop.defaultValue {
            if baseType == "String" {
                return "    let \(prop.name) = queryParameters[\"\(prop.queryName)\"] ?? \(defaultValue)"
            } else {
                return "    let \(prop.name) = queryParameters[\"\(prop.queryName)\"].flatMap { \(generateValueConversion(from: "$0", to: baseType)) } ?? \(defaultValue)"
            }
        } else {
            if baseType == "String" {
                return """
                    guard let \(prop.name) = queryParameters["\(prop.queryName)"] else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing query parameter: \(prop.queryName)"))
                    }
                """
            } else {
                return """
                    guard let \(prop.name)String = queryParameters["\(prop.queryName)"],
                          let \(prop.name) = \(generateValueConversion(from: "\(prop.name)String", to: baseType)) else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing query parameter: \(prop.queryName)"))
                    }
                """
            }
        }
    }

    private static func generateBodyDecoding(for prop: PropertyInfo) -> String {
        if prop.isOptional {
            return """
                let \(prop.name): \(prop.typeName)
                if let bodyData = body {
                    \(prop.name) = try decoder.decode(\(prop.typeName.replacingOccurrences(of: "?", with: "")).self, from: bodyData)
                } else {
                    \(prop.name) = nil
                }
            """
        } else {
            return """
                guard let bodyData = body else {
                    throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing request body"))
                }
                let \(prop.name) = try decoder.decode(\(prop.typeName).self, from: bodyData)
            """
        }
    }

    private static func generateValueConversion(from source: String, to typeName: String) -> String {
        switch typeName {
        case "String":
            return source
        case "Int":
            return "Int(\(source))"
        case "Int64":
            return "Int64(\(source))"
        case "Int32":
            return "Int32(\(source))"
        case "Double":
            return "Double(\(source))"
        case "Float":
            return "Float(\(source))"
        case "Bool":
            return "Bool(\(source))"
        case "Date":
            return "ISO8601DateFormatter().date(from: \(source))"
        default:
            return "\(typeName)(rawValue: \(source))"
        }
    }
}

// MARK: - Supporting Types

private struct StreamingEndpointArguments {
    let method: String
    let path: String
    let scopes: [String]
}

// MARK: - Errors

enum StreamingEndpointMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct
    case invalidArguments

    var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@StreamingEndpoint can only be applied to structs"
        case .invalidArguments:
            return "@StreamingEndpoint requires a valid APIMethod argument"
        }
    }
}
