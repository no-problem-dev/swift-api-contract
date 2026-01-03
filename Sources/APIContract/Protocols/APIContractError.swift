import Foundation

/// API契約エラーを表すプロトコル
///
/// クライアント・サーバー間で一貫したエラーハンドリングを提供します。
public protocol APIContractError: Error, Codable, Sendable {
    var statusCode: Int { get }
    var errorCode: String { get }
    var message: String { get }
}

/// エラーレスポンスの共通JSON形式
public struct ErrorResponse: Codable, Sendable, Equatable {
    public let errorCode: String
    public let message: String
    public let details: [String: String]?

    public init(errorCode: String, message: String, details: [String: String]? = nil) {
        self.errorCode = errorCode
        self.message = message
        self.details = details
    }
}

extension APIContractError {
    public func toErrorResponse(details: [String: String]? = nil) -> ErrorResponse {
        ErrorResponse(errorCode: errorCode, message: message, details: details)
    }
}

/// 標準HTTPエラー
public enum HTTPError: APIContractError {
    case badRequest(String)
    case unauthorized
    case forbidden(String)
    case notFound(String)
    case conflict(String)
    case internalError(String)

    public var statusCode: Int {
        switch self {
        case .badRequest: return 400
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .conflict: return 409
        case .internalError: return 500
        }
    }

    public var errorCode: String {
        switch self {
        case .badRequest: return "BAD_REQUEST"
        case .unauthorized: return "UNAUTHORIZED"
        case .forbidden: return "FORBIDDEN"
        case .notFound: return "NOT_FOUND"
        case .conflict: return "CONFLICT"
        case .internalError: return "INTERNAL_ERROR"
        }
    }

    public var message: String {
        switch self {
        case .badRequest(let msg): return msg
        case .unauthorized: return "Authentication required"
        case .forbidden(let msg): return msg
        case .notFound(let msg): return msg
        case .conflict(let msg): return msg
        case .internalError(let msg): return msg
        }
    }
}

/// エラー定義がないエンドポイント用のデフォルトエラー型
public enum NoContractError: APIContractError {
    case unexpected(String)

    public var statusCode: Int { 500 }
    public var errorCode: String { "UNEXPECTED_ERROR" }
    public var message: String {
        switch self {
        case .unexpected(let msg): return msg
        }
    }
}
