import Foundation

/// API契約エラーを表すプロトコル
///
/// 各ドメインのエラー型がこのプロトコルに準拠することで、
/// クライアント・サーバー間で一貫したエラーハンドリングが可能になります。
///
/// ## 使用例
/// ```swift
/// enum ActivitiesAPIError: APIContractError {
///     case notFound(activityId: String)
///     case outsideMutablePeriod
///
///     var statusCode: Int {
///         switch self {
///         case .notFound: return 404
///         case .outsideMutablePeriod: return 403
///         }
///     }
///
///     var errorCode: String {
///         switch self {
///         case .notFound: return "ACTIVITY_NOT_FOUND"
///         case .outsideMutablePeriod: return "PERIOD_LOCKED"
///         }
///     }
///
///     var message: String {
///         switch self {
///         case .notFound(let id): return "Activity '\(id)' not found"
///         case .outsideMutablePeriod: return "Cannot modify activity outside mutable period"
///         }
///     }
/// }
/// ```
public protocol APIContractError: Error, Codable, Sendable {
    /// HTTPステータスコード
    var statusCode: Int { get }

    /// エラーコード（クライアント側での識別用）
    var errorCode: String { get }

    /// 人間可読なメッセージ
    var message: String { get }
}

// MARK: - Error Response

/// エラーレスポンスの共通JSON形式
///
/// サーバーからクライアントへのエラーレスポンスはこの形式で送信されます。
/// ```json
/// {
///   "errorCode": "ACTIVITY_NOT_FOUND",
///   "message": "Activity 'abc123' not found",
///   "details": { "activityId": "abc123" }
/// }
/// ```
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

// MARK: - APIContractError → ErrorResponse

extension APIContractError {
    /// ErrorResponseに変換
    public func toErrorResponse(details: [String: String]? = nil) -> ErrorResponse {
        ErrorResponse(errorCode: errorCode, message: message, details: details)
    }
}

// MARK: - Standard HTTP Errors

/// 標準HTTPエラー（ドメイン固有でない汎用エラー）
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

// MARK: - No Contract Error

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
