import Foundation

/// Everything a set of related endpoints share: where they live, how they authenticate, how they fail.
///
/// Conformance comes from `@APIGroup` on an enum. The enum is a namespace, never instantiated —
/// its endpoints are nested types.
public protocol APIContractGroup: Sendable {
    /// Path prefix every endpoint in the group hangs off, such as `/v1/users`.
    ///
    /// Endpoint sub-paths are appended to it, so moving an API version is a one-line change here.
    static var basePath: String { get }

    /// How requests in this group prove who they are.
    ///
    /// Taken from `@APIGroup(auth:)`. Note the default is `.bearer`, not `.none`: a group that
    /// needs no auth has to say so.
    static var auth: AuthScheme { get }

    /// Every endpoint in the group, as data rather than as types.
    ///
    /// Written by the macro from the `@Endpoint` members. Useful for generating route tables or
    /// documentation; streaming endpoints are not listed here.
    static var endpoints: [EndpointDescriptor] { get }

    /// Scopes endpoints inherit unless they declare their own.
    static var requiredScopes: [String] { get }

    /// Headers added to every request in the group, such as an API version pin.
    ///
    /// An endpoint's `@Header` with the same key replaces the value from here.
    static var commonHeaders: [String: String] { get }

    /// Turns an error response body into a typed error, for APIs that do not use the default shape.
    ///
    /// Headers are passed in as well, so rate-limit metadata can be lifted out of a 429 while it
    /// is still available. Returning `nil` — the default — hands the response back to the client's
    /// own error handling, which is the right answer for any status this group does not recognise.
    static func decodeError(statusCode: Int, data: Data, headers: [String: String], decoder: any APIBodyDecoder) -> (any Error)?
}

extension APIContractGroup {
    public static var requiredScopes: [String] { [] }

    public static var commonHeaders: [String: String] { [:] }

    public static func decodeError(statusCode: Int, data: Data, headers: [String: String], decoder: any APIBodyDecoder) -> (any Error)? {
        nil
    }
}

/// The group an endpoint declared outside any `@APIGroup` enum falls back to.
///
/// Its base path is empty, so such an endpoint's path is its sub-path alone — worth checking when
/// a request arrives at the wrong URL.
public enum NoGroup: APIContractGroup {
    public static let basePath: String = ""
    public static let auth: AuthScheme = .bearer
    public static let endpoints: [EndpointDescriptor] = []
}

/// One endpoint reduced to data, for code that has to enumerate an API rather than call it.
public struct EndpointDescriptor: Sendable {
    public let name: String
    public let method: APIMethod
    public let subPath: String

    /// Scopes recorded for this endpoint. Empty means it inherits the group's, not that it needs none.
    public let requiredScopes: [String]

    public var fullPath: String {
        if subPath.isEmpty { return "" }
        if subPath.hasPrefix("/") { return subPath }
        return "/\(subPath)"
    }

    public init(name: String, method: APIMethod, subPath: String, requiredScopes: [String] = []) {
        self.name = name
        self.method = method
        self.subPath = subPath
        self.requiredScopes = requiredScopes
    }
}
