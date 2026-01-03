import Foundation

/// 空の入力型
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

/// 空の出力型
public struct EmptyOutput: Decodable, Sendable, Equatable {
    public init() {}

    public init(from decoder: Decoder) throws {}
}
