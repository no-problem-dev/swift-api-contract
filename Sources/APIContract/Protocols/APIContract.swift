import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// API契約を定義するプロトコル
public protocol APIContract: Sendable {
    associatedtype Group: APIContractGroup = NoGroup
    associatedtype Input: APIInput = EmptyInput
    associatedtype Output: Decodable & Sendable
    associatedtype Failure: APIContractError = NoContractError

    static var method: APIMethod { get }
    static var subPath: String { get }
    static var auth: AuthRequirement { get }
}

extension APIContract {
    public static var auth: AuthRequirement { Group.auth }

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
        }
        return path
    }
}

extension APIContract where Input == Self, Self: APIInput {
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

        if request.httpBody != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
    public static var apiDefault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

public enum ContractBuildError: Error, LocalizedError {
    case invalidURL(path: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "Invalid URL path: \(path)"
        }
    }
}
