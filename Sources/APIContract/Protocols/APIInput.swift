import Foundation

/// APIリクエストの入力を表すプロトコル
///
/// パスパラメータ、クエリパラメータ、リクエストボディを統一的に扱います。
public protocol APIInput: Sendable, Encodable {
    /// パスパラメータ（`:paramName` を置換）
    var pathParameters: [String: String] { get }

    /// クエリパラメータ
    var queryParameters: [String: String]? { get }

    /// リクエストボディをエンコード
    func encodeBody(using encoder: JSONEncoder) throws -> Data?

    /// サーバーサイドでリクエストからInputをデコード
    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: JSONDecoder
    ) throws -> Self
}

extension APIInput {
    public var pathParameters: [String: String] { [:] }
    public var queryParameters: [String: String]? { nil }
    public func encodeBody(using encoder: JSONEncoder) throws -> Data? { nil }
}

extension APIInput {
    public static func encodeDate(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    public static func encodeDateOnly(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }
}
