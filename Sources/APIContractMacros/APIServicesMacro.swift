import SwiftSyntax
import SwiftSyntaxMacros

/// 複数のAPIサービスをグループ化するマクロ
///
/// structに付与して、`registerAll` メソッドを自動生成します。
/// 各プロパティの型から `Service.Group.registerAll()` を呼び出すコードを生成します。
public struct APIServicesMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // structにのみ適用可能
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw APIServicesMacroError.onlyApplicableToStruct
        }

        // stored propertiesを収集
        let properties = collectStoredProperties(from: structDecl)

        if properties.isEmpty {
            throw APIServicesMacroError.noPropertiesFound
        }

        // registerAllメソッドを生成
        return [generateRegisterAllMethod(properties: properties)]
    }

    // MARK: - Private Helpers

    /// stored propertiesを収集
    private static func collectStoredProperties(from structDecl: StructDeclSyntax) -> [ServicePropertyInfo] {
        var properties: [ServicePropertyInfo] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            // let または var で宣言されたstored propertyのみ対象
            for binding in varDecl.bindings {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                      let typeAnnotation = binding.typeAnnotation else {
                    continue
                }

                // computed propertyは除外（accessorがあればcomputed）
                if binding.accessorBlock != nil {
                    continue
                }

                let propertyName = identifier.identifier.text
                let typeName = typeAnnotation.type.trimmedDescription

                properties.append(ServicePropertyInfo(name: propertyName, typeName: typeName))
            }
        }

        return properties
    }

    /// registerAllメソッドを生成
    private static func generateRegisterAllMethod(properties: [ServicePropertyInfo]) -> DeclSyntax {
        let registrations = properties.map { property in
            "\(property.typeName).Group.registerAll(routes.mount(\(property.name)))"
        }.joined(separator: "\n        ")

        return DeclSyntax(stringLiteral: """
        public func registerAll<R: Routes>(_ routes: R) {
                \(registrations)
            }
        """)
    }
}

// MARK: - Supporting Types

private struct ServicePropertyInfo {
    let name: String
    let typeName: String
}

// MARK: - Errors

enum APIServicesMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct
    case noPropertiesFound

    var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@APIServices can only be applied to structs"
        case .noPropertiesFound:
            return "@APIServices requires at least one stored property"
        }
    }
}
