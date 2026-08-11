import Foundation

/// The request half of an endpoint, split into the three places a value can travel: path, query, body.
///
/// `@Endpoint` makes the endpoint struct itself conform, which is why an endpoint value is both
/// the description of a call and its arguments.
public protocol APIInput: Sendable, Encodable {
    /// Values substituted into `:name` and `{name}` placeholders, keyed by placeholder name.
    var pathParameters: [String: String] { get }

    /// Query items to append, or `nil` when there are none — an empty dictionary would still
    /// produce a trailing `?`.
    var queryParameters: [String: String]? { get }

    /// Serialises the request body, or returns `nil` for endpoints that send none.
    func encodeBody(using encoder: any APIBodyEncoder) throws -> Data?

    /// Rebuilds the input on the server from the parts a router hands over.
    ///
    /// The mirror image of the client-side encoding, which is what keeps one endpoint definition
    /// honest at both ends. Throws `DecodingError.dataCorrupted` when a required parameter is
    /// absent or cannot be parsed into its declared type.
    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: any APIBodyDecoder
    ) throws -> Self
}

extension APIInput {
    public var pathParameters: [String: String] { [:] }
    public var queryParameters: [String: String]? { nil }
    public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }
}

extension APIInput {
    /// Renders a date the way generated path and query encoding does: full ISO8601 with a time.
    public static func encodeDate(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    /// Renders just the calendar date, for APIs that reject a time component.
    ///
    /// Not used by the generated code — a `Date` property always encodes with its time — so call
    /// this explicitly when the API wants `2026-08-11`.
    public static func encodeDateOnly(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }
}
