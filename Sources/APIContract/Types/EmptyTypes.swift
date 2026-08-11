import Foundation

/// The input of an endpoint that takes no parameters.
///
/// The default `Input`, so an endpoint only names something else when it has parameters.
public struct EmptyInput: APIInput, Codable {
    public init() {}

    public static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: any APIBodyDecoder
    ) throws -> Self {
        Self()
    }
}

/// The output of an endpoint that returns no body, such as a delete.
///
/// Declaring `typealias Output = EmptyOutput` also selects the `execute(_:)` overload that
/// returns nothing, so the call site has no value to discard. It decodes from any payload,
/// including an empty one.
public struct EmptyOutput: Decodable, Sendable, Equatable {
    public init() {}

    public init(from decoder: Decoder) throws {}
}
