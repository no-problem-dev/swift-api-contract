/// HTTPメソッドを表す列挙型
public enum HTTPMethod: String, Sendable, Codable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}

/// 認証要件を表す列挙型
public enum AuthRequirement: Sendable, Codable {
    /// 認証不要（パブリックエンドポイント）
    case none
    /// 認証必須（プロテクテッドエンドポイント）
    case required
}
