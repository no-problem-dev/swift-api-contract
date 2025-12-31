import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

/// エンドポイントを定義するマクロ
///
/// structに付与して、`APIContract` と `APIInput` への準拠を自動生成します。
public struct EndpointMacro: MemberMacro, ExtensionMacro {

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // structにのみ適用可能
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw EndpointMacroError.onlyApplicableToStruct
        }

        // マクロ引数を解析
        let arguments = try parseArguments(from: node)

        // プロパティ情報を収集
        let properties = try collectProperties(from: structDecl)

        // 親enumを検出してGroupとして使用
        let parentEnumName = findParentEnumName(in: context)

        var members: [DeclSyntax] = []

        // typealias Input = Self
        members.append("public typealias Input = Self")

        // typealias Group = ParentEnumName (親enumが見つかった場合のみ)
        if let groupName = parentEnumName {
            members.append("public typealias Group = \(raw: groupName)")
        }

        // static let method: HTTPMethod
        members.append("public static let method: HTTPMethod = .\(raw: arguments.method)")

        // static let subPath: String
        members.append("public static let subPath: String = \"\(raw: arguments.path)\"")

        // var pathParameters: [String: String]
        let pathParamProperties = properties.filter { $0.kind == .pathParam }
        if pathParamProperties.isEmpty {
            members.append("public var pathParameters: [String: String] { [:] }")
        } else {
            let pathParamEntries = pathParamProperties.map { prop in
                "\"\(prop.name)\": \(prop.name)"
            }.joined(separator: ", ")
            members.append("public var pathParameters: [String: String] { [\(raw: pathParamEntries)] }")
        }

        // var queryParameters: [String: String]?
        let queryParamProperties = properties.filter { $0.kind == .queryParam }
        members.append(generateQueryParametersProperty(for: queryParamProperties))

        // func encodeBody(using encoder: JSONEncoder) throws -> Data?
        let bodyProperty = properties.first { $0.kind == .body }
        members.append(generateEncodeBodyMethod(for: bodyProperty))

        // init
        members.append(generateInitializer(for: properties))

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
        // structでない場合は空の配列を返す（エラーはMemberMacroで報告済み）
        guard declaration.is(StructDeclSyntax.self) else {
            return []
        }

        let extensionDecl: DeclSyntax = """
        extension \(type.trimmed): APIContract, APIInput {}
        """

        guard let extensionDeclSyntax = extensionDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDeclSyntax]
    }

    // MARK: - Private Helpers

    /// レキシカルコンテキストから親enumの名前を検出
    private static func findParentEnumName(in context: some MacroExpansionContext) -> String? {
        for lexicalContext in context.lexicalContext {
            // enumを探す
            if let enumDecl = lexicalContext.as(EnumDeclSyntax.self) {
                return enumDecl.name.text
            }
        }
        return nil
    }

    private static func parseArguments(from node: AttributeSyntax) throws -> EndpointArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw EndpointMacroError.invalidArguments
        }

        var method: String = "get"
        var path: String = ""

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

        return EndpointArguments(method: method, path: path)
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

            // typealiasは除外
            if pattern.identifier.text == "Output" || pattern.identifier.text == "Input" {
                continue
            }

            let name = pattern.identifier.text
            let typeName = typeAnnotation.type.trimmedDescription
            let isOptional = typeAnnotation.type.is(OptionalTypeSyntax.self)
            let kind = determinePropertyKind(from: varDecl)
            let queryName = extractQueryParamName(from: varDecl) ?? name
            let defaultValue = binding.initializer?.value.trimmedDescription

            properties.append(PropertyInfo(
                name: name,
                typeName: typeName,
                isOptional: isOptional,
                kind: kind,
                queryName: queryName,
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
            default:
                continue
            }
        }

        // デフォルトはクエリパラメータ
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
            // RawRepresentable (enum) と仮定
            return "\(prop.name).rawValue"
        }
    }

    private static func generateEncodeBodyMethod(for bodyProperty: PropertyInfo?) -> DeclSyntax {
        guard let prop = bodyProperty else {
            return """
            public func encodeBody(using encoder: JSONEncoder) throws -> Data? { nil }
            """
        }

        return """
        public func encodeBody(using encoder: JSONEncoder) throws -> Data? {
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
}

// MARK: - Supporting Types

private struct EndpointArguments {
    let method: String
    let path: String
}

struct PropertyInfo {
    let name: String
    let typeName: String
    let isOptional: Bool
    let kind: PropertyKind
    let queryName: String
    let defaultValue: String?
}

enum PropertyKind {
    case pathParam
    case queryParam
    case body
}

// MARK: - Errors

enum EndpointMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct
    case invalidArguments

    var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@Endpoint can only be applied to structs"
        case .invalidArguments:
            return "@Endpoint requires a valid HTTPMethod argument"
        }
    }
}
