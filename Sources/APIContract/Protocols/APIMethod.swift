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

/// 認証要件
public enum AuthRequirement: Sendable, Codable {
    case none
    case required
}
