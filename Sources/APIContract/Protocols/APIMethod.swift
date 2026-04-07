/// HTTPメソッド
public enum APIMethod: String, Sendable, Codable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}

/// 認証方式
///
/// エンドポイントグループがどの認証スキームを使用するかを宣言する。
/// トークン値の取得は `AuthTokenProvider`（APIClient側）が担当し、
/// `AuthScheme` はトークンのHTTPリクエストへの適用方法を定義する。
public enum AuthScheme: Sendable, Equatable {
    /// 認証不要
    case none

    /// Bearer トークン（Authorization: Bearer <token>）
    case bearer

    /// API Key ヘッダー（例: x-api-key: <token>）
    case apiKey(headerName: String)

    /// クエリパラメータ（例: ?key=<token>）
    case queryParam(name: String)
}

extension AuthScheme {
    /// 後方互換: Bearer トークン認証のエイリアス
    ///
    /// 旧バージョン (1.0.x) の `.required` ケースとの互換を保つために提供される。
    /// 新規コードでは `.bearer` を直接使用すること。
    public static let required: AuthScheme = .bearer
}
