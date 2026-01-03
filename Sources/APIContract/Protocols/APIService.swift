import Foundation

/// サービス実行時のコンテキスト
public enum ServiceContext: Sendable {
    case anonymous
    case authenticated(userId: String)

    public var userId: String? {
        switch self {
        case .anonymous: return nil
        case .authenticated(let userId): return userId
        }
    }

    public func requireUserId() throws -> String {
        guard let userId = userId else {
            throw HTTPError.unauthorized
        }
        return userId
    }
}

/// APIグループのサービス基底プロトコル
public protocol APIService: Sendable {
    associatedtype Group: APIContractGroup
}

/// 型消去されたエンドポイントを処理するためのプロトコル
public protocol AnyEndpointDispatcher: Sendable {
    func dispatchAny(_ input: any APIInput, context: ServiceContext) async throws -> any Sendable
}
