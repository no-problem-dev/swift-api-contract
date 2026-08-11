import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An endpoint whose response is a sequence of events rather than a single decoded value.
///
/// The counterpart of `APIContract` for Server-Sent Events and similar transports; conformance
/// comes from `@StreamingEndpoint`. It is a separate protocol rather than a variant because the
/// response type is `Event` and there is no single output to return.
public protocol StreamingAPIContract: Sendable {
    associatedtype Group: APIContractGroup = NoGroup
    associatedtype Input: APIInput = EmptyInput
    associatedtype Event: Codable & Sendable
    associatedtype Failure: APIContractError = NoContractError

    static var method: APIMethod { get }
    static var subPath: String { get }
    static var auth: AuthScheme { get }

    /// Scopes a token must carry for this stream to open. Empty inherits the group's.
    static var requiredScopes: [String] { get }

    /// Per-call headers, applied after the group's common headers and overriding them on a shared key.
    var additionalHeaders: [String: String] { get }

    static func resolvePath(with input: Input) -> String
}

// MARK: - Default Implementations

extension StreamingAPIContract {
    public static var auth: AuthScheme { Group.auth }

    public static var requiredScopes: [String] { Group.requiredScopes }

    public var additionalHeaders: [String: String] { [:] }

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

// MARK: - Request Building

extension StreamingAPIContract where Input == Self, Self: APIInput {
    /// Assembles the `URLRequest` for the stream, including the Server-Sent Events headers.
    ///
    /// Same as the non-streaming version except for those headers, which are set before the
    /// group's, so a group that pins its own `Accept` wins.
    ///
    /// - Parameters:
    ///   - baseURL: Root the path is appended to.
    ///   - encoder: Encoder for the request body, defaulting to JSON with ISO8601 dates.
    /// - Throws: `ContractBuildError.invalidURL` when the resolved path cannot form a URL.
    public func buildRequest(
        baseURL: URL,
        encoder: any APIBodyEncoder = JSONEncoder.apiDefault
    ) throws -> URLRequest {
        let path = Self.resolvePath(with: self)
        guard var urlComponents = URLComponents(
            url: baseURL.appendingPathComponent(path),
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

        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        if request.httpBody != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        for (key, value) in Group.commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Applied last, so an endpoint header overrides a group header on the same key.
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

// MARK: - Streaming Execution

/// What a client provides so streaming endpoints become callable.
///
/// The streaming counterpart of `APIExecutable`. Note it does not throw up front: a failure to
/// open the stream surfaces when the returned sequence is first iterated.
public protocol StreamingAPIExecutable: Sendable {
    func execute<E: StreamingAPIContract>(
        _ contract: E
    ) -> AsyncThrowingStream<E.Event, Error>
        where E.Input == E, E: APIInput
}

// MARK: - Convenience Execution

extension StreamingAPIContract where Input == Self, Self: APIInput {
    /// Opens the stream, so a call reads from the endpoint value rather than from the client.
    ///
    /// Nothing is sent until iteration begins; abandoning the sequence cancels the request.
    public func stream<Executor: StreamingAPIExecutable>(
        using executor: Executor
    ) -> AsyncThrowingStream<Event, Error> {
        executor.execute(self)
    }
}
