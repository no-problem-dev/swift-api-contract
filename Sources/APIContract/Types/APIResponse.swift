import Foundation

/// A decoded response with the status and headers still attached.
///
/// What `executeWithResponse(_:)` returns. Reach for it when the body alone is not enough —
/// rate-limit budgets, pagination cursors and ETags all live in the headers.
public struct APIResponse<Output: Sendable>: Sendable {
    public let output: Output
    public let statusCode: Int
    public let headers: [String: String]

    public init(output: Output, statusCode: Int, headers: [String: String]) {
        self.output = output
        self.statusCode = statusCode
        self.headers = headers
    }

    /// Looks up a header without caring about capitalisation, which servers are inconsistent about.
    ///
    /// Subscripting `headers` directly is the reason `x-ratelimit-remaining` sometimes reads as
    /// absent; use this instead.
    public func header(_ name: String) -> String? {
        let lowered = name.lowercased()
        return headers.first { $0.key.lowercased() == lowered }?.value
    }
}
