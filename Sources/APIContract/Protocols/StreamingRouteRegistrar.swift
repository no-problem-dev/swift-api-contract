import Foundation

/// The server-side adapter for streaming endpoints, which a group's `registerAll(_:)` does not cover.
///
/// `APIRouteRegistrar` handles request/response routes; streaming ones are registered here, one
/// call each, because the macro leaves them out of the generated bulk registration.
public protocol StreamingRouteRegistrar: Sendable {
    associatedtype Group: APIContractGroup
    associatedtype Service: APIService where Service.Group == Group

    var service: Service { get }

    /// Mounts one streaming endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint type to serve.
    ///   - handler: Produces the event stream for a request. It returns as soon as the stream
    ///              exists, so the work that fills it runs after the handler is done.
    @discardableResult
    func register<Endpoint: StreamingAPIContract>(
        _ endpoint: Endpoint.Type,
        handler: @escaping @Sendable (Endpoint.Input, ServiceContext) async throws -> AsyncStream<Endpoint.Event>
    ) -> Self where Endpoint.Input == Endpoint, Endpoint: APIInput
}
