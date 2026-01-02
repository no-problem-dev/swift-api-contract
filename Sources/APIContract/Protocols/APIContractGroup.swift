/// APIエンドポイントのグループを表すプロトコル
///
/// `@APIGroup`マクロで定義されたenumが準拠します。
public protocol APIContractGroup: Sendable {
    static var basePath: String { get }
    static var auth: AuthRequirement { get }
    static var endpoints: [EndpointDescriptor] { get }
}

/// グループに属さないエンドポイント用のデフォルトグループ
public enum NoGroup: APIContractGroup {
    public static let basePath: String = ""
    public static let auth: AuthRequirement = .required
    public static let endpoints: [EndpointDescriptor] = []
}

/// エンドポイントのメタ情報
public struct EndpointDescriptor: Sendable {
    public let name: String
    public let method: APIMethod
    public let subPath: String

    public var fullPath: String {
        if subPath.isEmpty { return "" }
        if subPath.hasPrefix("/") { return subPath }
        return "/\(subPath)"
    }

    public init(name: String, method: APIMethod, subPath: String) {
        self.name = name
        self.method = method
        self.subPath = subPath
    }
}
