/// The HTTP method an endpoint is called with. The raw value is what goes on the wire.
public enum APIMethod: String, Sendable, Codable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}

/// Where a credential goes in the request — not where it comes from.
///
/// A group declares the scheme; obtaining the token is the client's job. Nothing in this package
/// applies the scheme either: the client reads it and decides what to attach.
public enum AuthScheme: Sendable, Equatable {
    /// Public endpoints. Has to be stated, because the group default is `.bearer`.
    case none

    /// `Authorization: Bearer <token>`.
    case bearer

    /// A dedicated header carrying the key, such as `x-api-key`.
    case apiKey(headerName: String)

    /// The credential travels in the URL, such as `?key=…`, where it ends up in server logs.
    case queryParam(name: String)
}

extension AuthScheme {
    /// Older spelling of `.bearer`, kept so 1.0.x call sites still compile.
    ///
    /// Prefer `.bearer`, which says what actually happens to the request.
    public static let required: AuthScheme = .bearer
}
