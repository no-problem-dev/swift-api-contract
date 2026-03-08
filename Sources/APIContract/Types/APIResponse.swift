import Foundation

/// レスポンスメタデータ付きのAPI応答
///
/// `executeWithResponse()` で使用し、レスポンスヘッダーやステータスコードへのアクセスを提供する。
/// レート制限情報の抽出など、メタデータが必要なユースケースに対応。
public struct APIResponse<Output: Sendable>: Sendable {
    public let output: Output
    public let statusCode: Int
    public let headers: [String: String]

    public init(output: Output, statusCode: Int, headers: [String: String]) {
        self.output = output
        self.statusCode = statusCode
        self.headers = headers
    }

    /// 指定名のヘッダー値を取得（大文字小文字を区別しない）
    public func header(_ name: String) -> String? {
        let lowered = name.lowercased()
        return headers.first { $0.key.lowercased() == lowered }?.value
    }
}
