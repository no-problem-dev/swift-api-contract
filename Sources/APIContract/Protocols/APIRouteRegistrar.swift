import Foundation

/// The adapter a server framework provides so generated registration code can mount routes on it.
///
/// One conformance per framework is enough: `registerAll(_:)` on a group calls `register(_:handler:)`
/// once per endpoint, and the framework decides what a route actually is. The two overloads exist
/// because an endpoint returning `EmptyOutput` has nothing to encode.
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
