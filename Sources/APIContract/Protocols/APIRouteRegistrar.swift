import Foundation

/// API ルート登録機能を提供するプロトコル
///
/// サーバーフレームワーク（swift-api-server等）の `APIRoutes` がこのプロトコルに準拠し、
/// マクロが生成する `registerAll()` メソッドのターゲットとなります。
///
/// ## 使用例
/// ```swift
/// FormulaAPI.registerAll(server.routes.mount(formulaService))
/// ```
public protocol APIRouteRegistrar: Sendable {
    /// 対応する API グループ
    associatedtype Group: APIContractGroup

    /// サービス型
    associatedtype Service: APIService where Service.Group == Group

    /// サービスインスタンス
    var service: Service { get }

    /// エンドポイントを登録（通常の Output を返すエンドポイント用）
    @discardableResult
    func register<Endpoint: APIContract>(
        _ endpoint: Endpoint.Type,
        handler: @escaping @Sendable (Endpoint.Input, ServiceContext) async throws -> Endpoint.Output
    ) -> Self where Endpoint.Input == Endpoint, Endpoint: APIInput, Endpoint.Output: Encodable

    /// エンドポイントを登録（EmptyOutput を返すエンドポイント用）
    @discardableResult
    func register<Endpoint: APIContract>(
        _ endpoint: Endpoint.Type,
        handler: @escaping @Sendable (Endpoint.Input, ServiceContext) async throws -> Void
    ) -> Self where Endpoint.Input == Endpoint, Endpoint: APIInput, Endpoint.Output == EmptyOutput
}
