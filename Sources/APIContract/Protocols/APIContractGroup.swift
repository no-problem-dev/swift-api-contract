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
}

/// グループに属さないエンドポイント用のデフォルトグループ
public enum NoGroup: APIContractGroup {
    public static let basePath: String = ""
    public static let auth: AuthRequirement = .required
}
