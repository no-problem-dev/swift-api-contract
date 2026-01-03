import Foundation

/// 認証プロバイダープロトコル
///
/// トークンを検証してユーザーIDを返します。
public protocol AuthenticationProvider: Sendable {
    func verifyToken(_ token: String) async throws -> String
}

/// 認証エラー
public enum AuthenticationError: APIContractError {
    case invalidToken(String)
    case missingToken
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
