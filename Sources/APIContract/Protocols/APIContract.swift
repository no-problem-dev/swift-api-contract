import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// One request/response endpoint, described once and shared by the client and the server.
///
/// Conformance is written by `@Endpoint` rather than by hand: the macro fills in the associated
/// types and the request-building members. Conforming manually is possible but means reproducing
/// everything the macro generates.
///
/// The associated types have defaults, so an endpoint only states what differs from them — an
/// endpoint outside a group keeps `NoGroup`, one without parameters keeps `EmptyInput`.
public protocol APIContract: Sendable {
    associatedtype Group: APIContractGroup = NoGroup
    associatedtype Input: APIInput = EmptyInput
    associatedtype Output: Decodable & Sendable
    associatedtype Failure: APIContractError = NoContractError

    static var method: APIMethod { get }
    static var subPath: String { get }
    static var auth: AuthScheme { get }

    /// OAuth scopes a token must carry for this endpoint to be callable.
    ///
    /// Set from `@Endpoint(scopes:)`, or inherited from the group when that argument is left out.
    /// A scope-aware client passes this on when it acquires a token, so an endpoint that
    /// under-declares its scopes fails at the API rather than at compile time.
    static var requiredScopes: [String] { get }

    /// Headers that vary per call, added on top of the group's common headers.
    ///
    /// Generated from the endpoint's `@Header` properties. These are applied last, so a key
    /// declared here replaces the group's value for the same key.
    var additionalHeaders: [String: String] { get }

    /// Builds the request path for a given input.
    ///
    /// The default substitutes path parameters into the template, which covers every endpoint the
    /// macro generates. Implement it only for a path the placeholder syntax cannot express; it is
    /// a protocol requirement rather than an extension member so that generic call sites reach the
    /// custom version.
    static func resolvePath(with input: Input) -> String
}

extension APIContract {
    public static var auth: AuthScheme { Group.auth }

    /// Inherits the group's scopes when the endpoint does not declare its own.
    public static var requiredScopes: [String] { Group.requiredScopes }

    public var additionalHeaders: [String: String] { [:] }

    /// The group's base path joined with this endpoint's sub-path, placeholders still unsubstituted.
    ///
    /// Either half may be empty, and the join never doubles or drops the separator between them.
    public static var pathTemplate: String {
        let base = Group.basePath
        if subPath.isEmpty { return base }
        if base.isEmpty { return subPath }
        if subPath.hasPrefix("/") { return base + subPath }
        return "\(base)/\(subPath)"
    }

    public static func resolvePath(with input: Input) -> String {
        var path = pathTemplate
        for (key, value) in input.pathParameters {
            path = path.replacingOccurrences(of: ":\(key)", with: value)
            path = path.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return path
    }
}

extension APIContract where Input == Self, Self: APIInput {
    /// Assembles the `URLRequest` this endpoint describes: path, query, body and headers.
    ///
    /// Everything an endpoint declares is applied here, in one place, so a client only has to
    /// send the result. `Content-Type: application/json` is set whenever a body was produced,
    /// independently of which encoder produced it.
    ///
    /// - Parameters:
    ///   - baseURL: Root the path is appended to. Pass the host, not a URL already carrying the path.
    ///   - encoder: Encoder for the request body. The default encodes dates as ISO8601, which is
    ///              what the server-side decoding in this package expects.
    /// - Throws: `ContractBuildError.invalidURL` when the resolved path cannot form a URL —
    ///           most often an unsubstituted placeholder or a raw character in a parameter value.
    public func buildRequest(
        baseURL: URL,
        encoder: any APIBodyEncoder = JSONEncoder.apiDefault
    ) throws -> URLRequest {
        let path = Self.resolvePath(with: self)
        // appendingPathComponent("") still appends a trailing slash, which some servers 404 on.
        let requestURL = path.isEmpty ? baseURL : baseURL.appendingPathComponent(path)
        guard var urlComponents = URLComponents(
            url: requestURL,
            resolvingAgainstBaseURL: true
        ) else {
            throw ContractBuildError.invalidURL(path: path)
        }

        if let query = queryParameters, !query.isEmpty {
            urlComponents.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = urlComponents.url else {
            throw ContractBuildError.invalidURL(path: path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = Self.method.rawValue
        request.httpBody = try encodeBody(using: encoder)

        if request.httpBody != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        for (key, value) in Group.commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Applied after the group's, so an endpoint header overrides a group header on the same key.
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

extension APIContract where Input == Self, Self: APIInput {
    public func execute<Executor: APIExecutable>(using executor: Executor) async throws -> Output {
        try await executor.execute(self)
    }
}

extension APIContract where Input == Self, Self: APIInput, Output == EmptyOutput {
    public func execute<Executor: APIExecutable>(using executor: Executor) async throws {
        try await executor.execute(self)
    }
}

extension JSONEncoder {
    /// The encoder `buildRequest` uses when the caller does not supply one: JSON with ISO8601 dates.
    ///
    /// It matches the date format the generated server-side decoding parses, so replacing it means
    /// changing both ends.
    public static var apiDefault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

/// A request could not be built, which is a mistake in the endpoint definition rather than a network failure.
public enum ContractBuildError: Error, LocalizedError {
    /// The resolved path does not form a URL — typically a placeholder that was never substituted.
    case invalidURL(path: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "Invalid URL path: \(path)"
        }
    }
}
