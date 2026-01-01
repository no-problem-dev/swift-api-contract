import Foundation

/// 認証プロバイダープロトコル
///
/// トークンを検証してユーザーIDを返す責務を持ちます。
/// Firebase Auth, Auth0, JWTなど様々な認証システムに対応できます。
///
/// ## 実装例
/// ```swift
/// struct FirebaseAuthProvider: AuthenticationProvider {
///     let authClient: AuthClient
///
///     func verifyToken(_ token: String) async throws -> String {
///         let verified = try await authClient.verifyToken(token)
///         return verified.uid
///     }
/// }
/// ```
public protocol AuthenticationProvider: Sendable {
    /// トークンを検証してユーザーIDを返す
    ///
    /// - Parameter token: Bearerトークン（"Bearer "プレフィックスは除去済み）
    /// - Returns: 認証済みユーザーID
    /// - Throws: 認証失敗時は`AuthenticationError`またはカスタムエラー
    func verifyToken(_ token: String) async throws -> String
}

/// 認証エラー
public enum AuthenticationError: APIContractError {
    /// トークンが不正または期限切れ
    case invalidToken(String)
    /// トークンが提供されていない
    case missingToken
    /// その他の認証エラー
    case authenticationFailed(String)

    public var statusCode: Int { 401 }

    public var errorCode: String {
        switch self {
        case .invalidToken: return "INVALID_TOKEN"
        case .missingToken: return "MISSING_TOKEN"
        case .authenticationFailed: return "AUTH_FAILED"
        }
    }

    public var message: String {
        switch self {
        case .invalidToken(let reason): return "Invalid token: \(reason)"
        case .missingToken: return "Authentication token is required"
        case .authenticationFailed(let reason): return "Authentication failed: \(reason)"
        }
    }
}
