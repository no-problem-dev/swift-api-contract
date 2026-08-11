import Foundation

/// What a client has to provide for endpoints to become callable.
///
/// Only `executeWithResponse(_:)` needs writing — the `execute(_:)` overloads are supplied by an
/// extension. Implementing it is where transport, retries and error mapping live; this package
/// deliberately ships no implementation.
public protocol APIExecutable: Sendable {
    /// Sends the request and returns the decoded output together with the status and headers.
    ///
    /// The one member to implement. Return the metadata even when it looks unused: rate-limit
    /// headers are only reachable through this overload.
    func executeWithResponse<E: APIContract>(_ contract: E) async throws -> APIResponse<E.Output>
        where E.Input == E, E: APIInput

    /// Sends the request and returns only the decoded output, discarding status and headers.
    func execute<E: APIContract>(_ contract: E) async throws -> E.Output
        where E.Input == E, E: APIInput

    /// Sends a request whose response carries no body, so there is nothing to return.
    func execute<E: APIContract>(_ contract: E) async throws
        where E.Input == E, E.Output == EmptyOutput, E: APIInput
}

extension APIExecutable {
    public func execute<E: APIContract>(_ contract: E) async throws -> E.Output
        where E.Input == E, E: APIInput
    {
        try await executeWithResponse(contract).output
    }

    public func execute<E: APIContract>(_ contract: E) async throws
        where E.Input == E, E.Output == EmptyOutput, E: APIInput
    {
        _ = try await executeWithResponse(contract)
    }
}
