import Foundation

/// APIエンドポイントのグループを表すプロトコル
///
/// `@APIGroup`マクロで定義されたenumが準拠します。
public protocol APIContractGroup: Sendable {
    static var basePath: String { get }
    static var auth: AuthScheme { get }
    static var endpoints: [EndpointDescriptor] { get }

    /// グループ共通ヘッダー
    ///
    /// グループ内の全エンドポイントに自動的に付与されるHTTPヘッダー。
    /// 例: APIバージョンヘッダー（`anthropic-version: 2023-06-01`）
    static var commonHeaders: [String: String] { get }

    /// グループ固有のエラーデコード
    ///
    /// プロバイダー固有のエラーレスポンスJSON構造をデコードする。
    /// レスポンスヘッダーも受け取るため、レート制限情報の抽出等に活用できる。
    /// `nil` を返した場合、APIClient のデフォルトエラーハンドリングが使用される。
    static func decodeError(statusCode: Int, data: Data, headers: [String: String], decoder: any APIBodyDecoder) -> (any Error)?
}

extension APIContractGroup {
    public static var commonHeaders: [String: String] { [:] }

    public static func decodeError(statusCode: Int, data: Data, headers: [String: String], decoder: any APIBodyDecoder) -> (any Error)? {
        nil
    }
}

/// グループに属さないエンドポイント用のデフォルトグループ
public enum NoGroup: APIContractGroup {
    public static let basePath: String = ""
    public static let auth: AuthScheme = .bearer
    public static let endpoints: [EndpointDescriptor] = []
}

/// エンドポイントのメタ情報
public struct EndpointDescriptor: Sendable {
    public let name: String
    public let method: APIMethod
    public let subPath: String

    public var fullPath: String {
        if subPath.isEmpty { return "" }
        if subPath.hasPrefix("/") { return subPath }
        return "/\(subPath)"
    }

    public init(name: String, method: APIMethod, subPath: String) {
        self.name = name
        self.method = method
        self.subPath = subPath
    }
}
