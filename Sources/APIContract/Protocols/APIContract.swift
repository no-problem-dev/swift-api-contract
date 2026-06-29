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
    static var auth: AuthScheme { get }

    /// このエンドポイントが必要とする OAuth スコープ
    ///
    /// `@Endpoint(..., scopes:)` で指定したスコープ。未指定なら所属グループの
    /// `requiredScopes` を継承する。スコープ対応のトークンプロバイダ
    /// (`ScopedAuthTokenProvider`) を使う APIClient が、トークン取得時にこの値を渡す。
    static var requiredScopes: [String] { get }

    /// エンドポイント固有のHTTPヘッダー
    ///
    /// リクエストごとに動的に付与するヘッダー。
    /// 例: `anthropic-beta: structured-outputs-2025-11-13`（条件付き）
    var additionalHeaders: [String: String] { get }

    /// 入力からパスを解決する
    ///
    /// デフォルト実装は`pathTemplate`のパスパラメータを置換する。
    /// カスタム実装でオーバーライド可能。
    static func resolvePath(with input: Input) -> String
}

extension APIContract {
    public static var auth: AuthScheme { Group.auth }

    /// デフォルトはグループの `requiredScopes` を継承する。
    public static var requiredScopes: [String] { Group.requiredScopes }

    public var additionalHeaders: [String: String] { [:] }

    /// グループの `basePath` とエンドポイントの `subPath` を結合した完全パステンプレート
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
    /// エンドポイントの定義から `URLRequest` を構築する
    ///
    /// パスパラメータの置換、クエリパラメータの付与、ボディのエンコード、
    /// グループ共通ヘッダーとエンドポイント固有ヘッダーを適用する。
    ///
    /// - Parameters:
    ///   - baseURL: API のベース URL
    ///   - encoder: ボディのエンコードに使用するエンコーダ。デフォルトは ISO8601 日付形式の `JSONEncoder`
    /// - Throws: `ContractBuildError.invalidURL` パスが無効な URL を形成する場合
    public func buildRequest(
        baseURL: URL,
        encoder: any APIBodyEncoder = JSONEncoder.apiDefault
    ) throws -> URLRequest {
        let path = Self.resolvePath(with: self)
        // 空パス時の末尾スラッシュ付与を回避(APIClientImpl と同じ理由)。
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

        // グループ共通ヘッダー適用
        for (key, value) in Group.commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // エンドポイント固有ヘッダー適用（グループヘッダーより優先）
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
    /// ISO8601 日付形式を使用するデフォルト設定の `JSONEncoder`
    public static var apiDefault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

/// `buildRequest` が無効な URL を構築しようとしたときに throw されるエラー
public enum ContractBuildError: Error, LocalizedError {
    /// 指定されたパスが有効な URL を形成しない
    case invalidURL(path: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "Invalid URL path: \(path)"
        }
    }
}
