import SwiftSyntax

/// Reads a `[String]` literal such as `scopes: ["a", "b"]`.
///
/// Only plain string-literal elements are taken; an interpolated or referenced value is skipped
/// without a diagnostic, so the scopes end up narrower than the source suggests.
func parseStringArrayLiteral(from expr: ExprSyntax) -> [String] {
    guard let arrayExpr = expr.as(ArrayExprSyntax.self) else { return [] }
    var result: [String] = []
    for element in arrayExpr.elements {
        if let stringLiteral = element.expression.as(StringLiteralExprSyntax.self),
           let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
            result.append(segment.content.text)
        }
    }
    return result
}

/// Renders a `[String]` back as Swift source, such as `["a", "b"]`, for use in an expansion.
func stringArraySource(_ scopes: [String]) -> String {
    "[" + scopes.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
}
