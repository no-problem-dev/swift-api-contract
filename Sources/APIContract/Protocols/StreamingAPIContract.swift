import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// ストリーミングレスポンスを返すAPI契約
///
/// 通常の`APIContract`がリクエスト-レスポンス型なのに対し、
/// `StreamingAPIContract`はリクエスト-ストリーム型の契約を表現します。
///
/// ## 使用例
/// ```swift
/// @StreamingEndpoint(.post, path: "stream")
/// public struct StartStream {
///     @Body public var request: SearchRequest
///     public typealias Event = SearchEvent  // ストリームで送信されるイベント型
/// }
/// ```
///
/// ## 設計思想
/// - `Event`型がストリームで送信されるイベントを型安全に宣言
/// - 通常のAPIContractと同様のパス解決・認証要件を持つ
/// - クライアント/サーバー両方で同一の契約を共有
public protocol StreamingAPIContract: Sendable {
    /// APIグループ
    associatedtype Group: APIContractGroup = NoGroup

    /// リクエスト入力型
    associatedtype Input: APIInput = EmptyInput

    /// ストリームで送信されるイベント型
    ///
    /// サーバーからクライアントへストリーミングされる個々のイベントの型。
    /// SSEの場合、各`data:`フィールドにJSONエンコードされて送信される。
    associatedtype Event: Codable & Sendable

    /// エラー型
    associatedtype Failure: APIContractError = NoContractError

    /// HTTPメソッド
    static var method: APIMethod { get }

    /// サブパス（グループのbasePathからの相対パス）
    static var subPath: String { get }

    /// 認証要件
    static var auth: AuthRequirement { get }

    /// 入力からパスを解決する
    static func resolvePath(with input: Input) -> String
}

// MARK: - Default Implementations

extension StreamingAPIContract {
    public static var auth: AuthRequirement { Group.auth }

    /// 完全なパステンプレート（グループのbasePath + subPath）
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

// MARK: - Request Building

extension StreamingAPIContract where Input == Self, Self: APIInput {
    /// URLRequestを構築
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

        return request
    }
}

// MARK: - Streaming Execution

/// ストリーミングAPI実行プロトコル
///
/// `APIExecutable`がリクエスト-レスポンス型なのに対し、
/// `StreamingAPIExecutable`はストリーミングレスポンスを返す。
public protocol StreamingAPIExecutable: Sendable {
    /// ストリーミングエンドポイントを実行
    ///
    /// - Parameter contract: 実行するストリーミング契約
    /// - Returns: イベントのAsyncThrowingStream
    func execute<E: StreamingAPIContract>(
        _ contract: E
    ) -> AsyncThrowingStream<E.Event, Error>
        where E.Input == E, E: APIInput
}

// MARK: - Convenience Execution

extension StreamingAPIContract where Input == Self, Self: APIInput {
    /// 指定したexecutorでストリーミングを開始
    public func stream<Executor: StreamingAPIExecutable>(
        using executor: Executor
    ) -> AsyncThrowingStream<Event, Error> {
        executor.execute(self)
    }
}
