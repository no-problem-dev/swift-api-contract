import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// API契約を表すプロトコル
///
/// エンドポイントのHTTPメソッド、パス、入出力型を型レベルで定義します。
/// これにより、クライアント（iOS）とサーバー（Backend）で同一の契約を共有し、
/// コンパイル時に整合性を検証できます。
///
/// ## 基本的な使用例
/// ```swift
/// @APIGroup(path: "/v1/users", auth: .required)
/// enum UsersAPI {
///     @Endpoint(.get)
///     struct List {
///         @QueryParam var limit: Int?
///         typealias Output = [User]
///     }
///
///     @Endpoint(.get, path: ":userId")
///     struct Get {
///         @PathParam var userId: String
///         typealias Output = User
///     }
/// }
/// ```
public protocol APIContract: Sendable {
    /// 所属するAPIグループ（デフォルト: NoGroup）
    associatedtype Group: APIContractGroup = NoGroup

    /// 入力型（パスパラメータ、クエリパラメータ、ボディを含む）
    associatedtype Input: APIInput = EmptyInput

    /// 出力型（レスポンス）
    associatedtype Output: Decodable & Sendable

    /// HTTPメソッド
    static var method: HTTPMethod { get }

    /// サブパス（グループのベースパスからの相対パス）
    ///
    /// 例: グループが"/v1/users"で、subPathが":userId"の場合、
    /// 完全なパスは"/v1/users/:userId"になります。
    static var subPath: String { get }

    /// 認証要件（デフォルトはグループの設定を継承）
    static var auth: AuthRequirement { get }
}

// MARK: - Default Implementations

extension APIContract {
    /// デフォルトではグループの認証設定を継承
    public static var auth: AuthRequirement { Group.auth }

    /// 完全なパステンプレート（グループのベースパス + サブパス）
    ///
    /// 例:
    /// - Group.basePath: "/v1/users"
    /// - subPath: ":userId"
    /// - pathTemplate: "/v1/users/:userId"
    public static var pathTemplate: String {
        let base = Group.basePath
        if subPath.isEmpty {
            return base
        }
        if base.isEmpty {
            return subPath
        }
        // サブパスが / で始まっていない場合は / を追加
        if subPath.hasPrefix("/") {
            return base + subPath
        }
        return "\(base)/\(subPath)"
    }

    /// パステンプレートにパスパラメータを適用してパスを構築
    ///
    /// - Parameter input: パスパラメータを含む入力
    /// - Returns: パスパラメータが適用されたパス文字列
    ///
    /// ## 例
    /// ```swift
    /// // pathTemplate: "/v1/users/:userId/posts/:postId"
    /// // input.pathParameters: ["userId": "123", "postId": "456"]
    /// // → "/v1/users/123/posts/456"
    /// ```
    public static func resolvePath(with input: Input) -> String {
        var path = pathTemplate
        for (key, value) in input.pathParameters {
            path = path.replacingOccurrences(of: ":\(key)", with: value)
        }
        return path
    }
}

// MARK: - Request Building (for iOS clients)

extension APIContract where Input == Self, Self: APIInput {
    /// URLRequestを構築する
    ///
    /// - Parameters:
    ///   - baseURL: APIのベースURL
    ///   - encoder: JSONEncoder（デフォルト: ISO8601日付フォーマット）
    /// - Returns: 構築されたURLRequest
    public func buildRequest(
        baseURL: URL,
        encoder: JSONEncoder = .apiDefault
    ) throws -> URLRequest {
        let path = Self.resolvePath(with: self)
        guard var urlComponents = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: true
        ) else {
            throw APIContractError.invalidURL(path: path)
        }

        if let query = queryParameters, !query.isEmpty {
            urlComponents.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = urlComponents.url else {
            throw APIContractError.invalidURL(path: path)
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

// MARK: - Execution (for iOS clients)

extension APIContract where Input == Self, Self: APIInput {
    /// APIExecutorを使用してこの契約を実行する
    ///
    /// ## 使用例
    /// ```swift
    /// let activities = try await ActivitiesAPI.List(limit: 20).execute(using: client)
    /// let activity = try await ActivitiesAPI.Get(activityId: "123").execute(using: client)
    /// ```
    ///
    /// - Parameter executor: API実行者（APIClientなど）
    /// - Returns: デコードされたレスポンス
    public func execute<Executor: APIExecutor>(using executor: Executor) async throws -> Output {
        try await executor.execute(self)
    }
}

extension APIContract where Input == Self, Self: APIInput, Output == EmptyOutput {
    /// レスポンスボディがないAPIContractを実行
    ///
    /// - Parameter executor: API実行者（APIClientなど）
    public func execute<Executor: APIExecutor>(using executor: Executor) async throws {
        try await executor.execute(self)
    }
}

// MARK: - JSONEncoder Extension

extension JSONEncoder {
    /// API用のデフォルトJSONEncoder
    public static var apiDefault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

// MARK: - Errors

/// APIContract関連のエラー
public enum APIContractError: Error, LocalizedError {
    case invalidURL(path: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "Invalid URL path: \(path)"
        }
    }
}
