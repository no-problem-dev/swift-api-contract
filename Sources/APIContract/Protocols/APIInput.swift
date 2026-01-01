import Foundation

/// APIリクエストの入力を表すプロトコル
///
/// パスパラメータ、クエリパラメータ、リクエストボディを統一的に扱います。
/// クライアント側ではリクエスト構築に、サーバー側ではリクエスト解析に使用します。
///
/// ## 例
/// ```swift
/// struct GetUserInput: APIInput {
///     var userId: String
///
///     var pathParameters: [String: String] {
///         ["userId": userId]
///     }
/// }
/// ```
public protocol APIInput: Sendable, Encodable {
    // MARK: - Client-side Encoding

    /// パスパラメータを返す
    ///
    /// パステンプレート内の `:paramName` を置換するために使用されます。
    /// 例: `["userId": "123"]` → `/users/:userId` → `/users/123`
    var pathParameters: [String: String] { get }

    /// クエリパラメータを返す
    ///
    /// URLのクエリ文字列として付与されます。
    /// 例: `["limit": "20"]` → `?limit=20`
    var queryParameters: [String: String]? { get }

    /// リクエストボディをエンコードする
    ///
    /// POST/PUT/PATCH リクエストのボディとして送信されます。
    /// - Parameter encoder: 使用するJSONEncoder
    /// - Returns: エンコードされたData、またはボディがない場合はnil
    func encodeBody(using encoder: JSONEncoder) throws -> Data?

    // MARK: - Server-side Decoding

    /// サーバーサイドでリクエストからInputをデコード
    ///
    /// - Parameters:
    ///   - pathParameters: URLパスから抽出されたパラメータ
    ///   - queryParameters: URLクエリ文字列から抽出されたパラメータ
    ///   - body: リクエストボディのData（存在する場合）
    ///   - decoder: JSONDecoder
    /// - Returns: デコードされたInput
    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: JSONDecoder
    ) throws -> Self
}

// MARK: - Default Implementations

extension APIInput {
    public var pathParameters: [String: String] { [:] }
    public var queryParameters: [String: String]? { nil }
    public func encodeBody(using encoder: JSONEncoder) throws -> Data? { nil }
}

// MARK: - Query Parameter Encoding

extension APIInput {
    /// ISO8601形式で日付をクエリパラメータ用の文字列に変換
    public static func encodeDate(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    /// 日付のみ（時刻なし）をクエリパラメータ用の文字列に変換
    public static func encodeDateOnly(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }
}
