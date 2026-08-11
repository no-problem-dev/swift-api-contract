import Foundation

/// Who the caller is, handed to every endpoint handler alongside its input.
///
/// The two cases are the whole model: a request either carries a verified identity or it does not.
/// Anything richer belongs in the service, not here.
public enum ServiceContext: Sendable {
    case anonymous
    case authenticated(userId: String)

    public var userId: String? {
        switch self {
        case .anonymous: return nil
        case .authenticated(let userId): return userId
        }
    }

    /// Returns the caller's id, or throws `HTTPError.unauthorized` when there is none.
    ///
    /// The first line of a handler that has no anonymous behaviour, so the 401 is not something
    /// each handler has to remember to write.
    public func requireUserId() throws -> String {
        guard let userId = userId else {
            throw HTTPError.unauthorized
        }
        return userId
    }
}

/// Ties a server implementation to the group it serves.
///
/// The per-endpoint `handle(_:context:)` requirements are not here — `@APIGroup` emits them on a
/// generated `<GroupName>Service` protocol that refines this one, which is what a service should
/// actually conform to.
public protocol APIService: Sendable {
    associatedtype Group: APIContractGroup
}

/// Dispatch without the endpoint's static type, for routing tables that cannot be generic.
public protocol AnyEndpointDispatcher: Sendable {
    func dispatchAny(_ input: any APIInput, context: ServiceContext) async throws -> any Sendable
}
