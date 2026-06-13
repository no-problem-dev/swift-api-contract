import SwiftSyntax

/// `scopes: ["a", "b"]` のような `[String]` 配列リテラルをパースする。
/// 文字列リテラル要素のみ対象（補間や変数参照は無視）。
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

/// `[String]` の Swift ソースリテラル表現を生成する（例: `["a", "b"]`）。
func stringArraySource(_ scopes: [String]) -> String {
    "[" + scopes.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
}
