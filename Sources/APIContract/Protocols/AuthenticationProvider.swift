import Foundation

/// Turns a bearer token into the user id a `ServiceContext` carries.
///
/// The server side of authentication reduced to its one decision. Throw `AuthenticationError`
/// rather than returning a sentinel id, so a rejected token cannot be mistaken for a valid one.
public protocol AuthenticationProvider: Sendable {
    func verifyToken(_ token: String) async throws -> String
}

/// Why a token was refused. Every case is a 401 — the distinction is for the logs, not the status line.
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
