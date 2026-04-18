import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// ストリーミングレスポンスを返すAPI契約
public protocol StreamingAPIContract: Sendable {
    associatedtype Group: APIContractGroup = NoGroup
    associatedtype Input: APIInput = EmptyInput
    associatedtype Event: Codable & Sendable
    associatedtype Failure: APIContractError = NoContractError

    static var method: APIMethod { get }
    static var subPath: String { get }
    static var auth: AuthScheme { get }

    /// エンドポイント固有のHTTPヘッダー
    var additionalHeaders: [String: String] { get }

    static func resolvePath(with input: Input) -> String
}

// MARK: - Default Implementations

extension StreamingAPIContract {
    public static var auth: AuthScheme { Group.auth }

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
    public func buildRequest(
        baseURL: URL,
        encoder: JSONEncoder = .apiDefault
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

        // SSE用のヘッダー
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        if request.httpBody != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // グループ共通ヘッダー適用
        for (key, value) in Group.commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // エンドポイント固有ヘッダー適用
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

// MARK: - Streaming Execution

public protocol StreamingAPIExecutable: Sendable {
    func execute<E: StreamingAPIContract>(
        _ contract: E
    ) -> AsyncThrowingStream<E.Event, Error>
        where E.Input == E, E: APIInput
}

// MARK: - Convenience Execution

extension StreamingAPIContract where Input == Self, Self: APIInput {
    public func stream<Executor: StreamingAPIExecutable>(
        using executor: Executor
    ) -> AsyncThrowingStream<Event, Error> {
        executor.execute(self)
    }
}
