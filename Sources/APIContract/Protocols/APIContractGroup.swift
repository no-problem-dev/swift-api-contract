/// APIエンドポイントのグループを表すプロトコル
///
/// `@APIGroup`マクロで定義されたenumが準拠します。
/// グループ内のエンドポイントは、このグループの`basePath`を継承します。
///
/// ## 例
/// ```swift
/// @APIGroup(path: "/v1/users", auth: .required)
/// public enum UsersAPI {
///     // このグループ内のエンドポイントは /v1/users をベースパスとして使用
/// }
/// ```
public protocol APIContractGroup: Sendable {
    /// ベースパス（例: "/v1/users"）
    static var basePath: String { get }

    /// 認証要件
    static var auth: AuthRequirement { get }

    /// グループ内の全エンドポイント情報
    /// マクロが自動生成します
    static var endpoints: [EndpointDescriptor] { get }
}

/// グループに属さないエンドポイント用のデフォルトグループ
public enum NoGroup: APIContractGroup {
    public static let basePath: String = ""
    public static let auth: AuthRequirement = .required
    public static let endpoints: [EndpointDescriptor] = []
}

// MARK: - Endpoint Descriptor

/// エンドポイントの型消去されたメタ情報
///
/// サーバーフレームワーク統合時のルーティング自動生成に使用します。
public struct EndpointDescriptor: Sendable {
    /// エンドポイント名（例: "List", "Get", "Create"）
    public let name: String

    /// HTTPメソッド
    public let method: APIMethod

    /// サブパス（グループのbasePathからの相対パス）
    public let subPath: String

    /// フルパステンプレート
    public var fullPath: String {
        if subPath.isEmpty {
            return ""
        }
        if subPath.hasPrefix("/") {
            return subPath
        }
        return "/\(subPath)"
    }

    public init(name: String, method: APIMethod, subPath: String) {
        self.name = name
        self.method = method
        self.subPath = subPath
    }
}
