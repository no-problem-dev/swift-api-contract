import Foundation

/// 空の入力型（パラメータなしのエンドポイント用）
///
/// エンドポイントがパスパラメータ、クエリパラメータ、ボディを
/// 一切必要としない場合に使用します。
///
/// ## 例
/// ```swift
/// @Endpoint(.get)
/// struct Health {
///     typealias Input = EmptyInput
///     typealias Output = HealthStatus
/// }
/// ```
public struct EmptyInput: APIInput, Codable {
    public init() {}

    public static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: JSONDecoder
    ) throws -> Self {
        Self()
    }
}

/// 空の出力型（レスポンスボディがないエンドポイント用）
///
/// DELETEリクエストなど、成功時にレスポンスボディを返さない
/// エンドポイントに使用します。
///
/// ## 例
/// ```swift
/// @Endpoint(.delete, path: ":userId")
/// struct Delete {
///     @PathParam var userId: String
///     typealias Output = EmptyOutput
/// }
/// ```
public struct EmptyOutput: Decodable, Sendable, Equatable {
    public init() {}

    public init(from decoder: Decoder) throws {
        // 空のJSONオブジェクト {} または空レスポンスを許容
    }
}
