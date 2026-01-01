import Foundation

/// サービス実行時のコンテキスト
///
/// 認証状態に応じて異なるコンテキストが提供されます。
public enum ServiceContext: Sendable {
    /// 認証不要のリクエスト
    case anonymous

    /// 認証済みリクエスト
    case authenticated(userId: String)

    /// ユーザーIDを取得（認証済みの場合のみ）
    public var userId: String? {
        switch self {
        case .anonymous: return nil
        case .authenticated(let userId): return userId
        }
    }

    /// 認証済みであることを要求し、userIdを返す
    /// - Throws: HTTPError.unauthorized if not authenticated
    public func requireUserId() throws -> String {
        guard let userId = userId else {
            throw HTTPError.unauthorized
        }
        return userId
    }
}

/// APIグループのサービス基底プロトコル
///
/// `@APIGroup` マクロが各APIグループに対応する具体的なサービスプロトコルを生成します。
/// 生成されるプロトコルはこの `APIService` を継承します。
///
/// ## 生成されるコード例
/// ```swift
/// @APIGroup(path: "/v1/activities", auth: .required)
/// public enum ActivitiesAPI { ... }
///
/// // ↓ マクロが自動生成
/// public protocol ActivitiesAPIService: APIService where Group == ActivitiesAPI {
///     func handle(_ input: ActivitiesAPI.List, context: ServiceContext) async throws -> [WorkoutActivity]
///     func handle(_ input: ActivitiesAPI.Get, context: ServiceContext) async throws -> WorkoutActivity
///     // ...
/// }
/// ```
public protocol APIService: Sendable {
    /// 対応するAPIグループ型
    associatedtype Group: APIContractGroup
}

/// 型消去されたエンドポイントを処理するためのプロトコル
///
/// サーバーフレームワーク統合時に、任意のエンドポイントをディスパッチするために使用します。
public protocol AnyEndpointDispatcher: Sendable {
    /// 型消去されたエンドポイントをディスパッチ
    func dispatchAny(_ input: any APIInput, context: ServiceContext) async throws -> any Sendable
}
