import Foundation

/// ストリーミングAPIルート登録プロトコル
///
/// `APIRouteRegistrar`が通常のリクエスト-レスポンス型なのに対し、
/// `StreamingRouteRegistrar`はストリーミングエンドポイントを登録する。
public protocol StreamingRouteRegistrar: Sendable {
    associatedtype Group: APIContractGroup
    associatedtype Service: APIService where Service.Group == Group

    var service: Service { get }

    /// ストリーミングエンドポイントを登録
    ///
    /// ハンドラーはAsyncStreamを返し、イベントがストリーミングされる。
    ///
    /// - Parameters:
    ///   - endpoint: エンドポイント型
    ///   - handler: ストリームを返すハンドラー
    @discardableResult
    func register<Endpoint: StreamingAPIContract>(
        _ endpoint: Endpoint.Type,
        handler: @escaping @Sendable (Endpoint.Input, ServiceContext) async throws -> AsyncStream<Endpoint.Event>
    ) -> Self where Endpoint.Input == Endpoint, Endpoint: APIInput
}
