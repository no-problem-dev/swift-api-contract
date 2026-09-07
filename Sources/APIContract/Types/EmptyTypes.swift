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
/// returns nothing, so the call site has no value to discard.
///
/// It has no fields, so any JSON payload decodes into it. A response carrying no bytes at all
/// is a different thing, and it never reaches `init(from:)`: a parser reads the payload before
/// any `Decodable` type is asked for a value, and on zero bytes it fails at the end of the
/// input. No output type can make a bodiless response decode, this one included. Recognising
/// that a response has no body, and skipping the decode instead, is the client's job.
public struct EmptyOutput: Decodable, Sendable, Equatable {
    public init() {}

    public init(from decoder: Decoder) throws {}
}
