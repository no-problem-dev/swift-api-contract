import Foundation

/// APIルート登録機能を提供するプロトコル
public protocol APIRouteRegistrar: Sendable {
    associatedtype Group: APIContractGroup
    associatedtype Service: APIService where Service.Group == Group

    var service: Service { get }

    @discardableResult
    func register<Endpoint: APIContract>(
        _ endpoint: Endpoint.Type,
        handler: @escaping @Sendable (Endpoint.Input, ServiceContext) async throws -> Endpoint.Output
    ) -> Self where Endpoint.Input == Endpoint, Endpoint: APIInput, Endpoint.Output: Encodable

    @discardableResult
    func register<Endpoint: APIContract>(
        _ endpoint: Endpoint.Type,
        handler: @escaping @Sendable (Endpoint.Input, ServiceContext) async throws -> Void
    ) -> Self where Endpoint.Input == Endpoint, Endpoint: APIInput, Endpoint.Output == EmptyOutput
}
