import Foundation

/// APIエンドポイントのグループを定義するプロトコル
///
/// `@APIGroup` マクロで定義した enum が自動的に準拠する。
public protocol APIContractGroup: Sendable {
    /// グループ内全エンドポイントに共通するURLパスプレフィックス（例: `/v1/users`）。
    /// 各エンドポイントの `subPath` と結合して最終的なリクエストパスになる。
    static var basePath: String { get }

    /// グループ内全エンドポイントで使用する認証方式。
    /// `@APIGroup(auth:)` の引数から自動設定され、デフォルトは `.bearer`。
    static var auth: AuthScheme { get }

    /// グループに属する全エンドポイントのメタ情報一覧。
    /// `@APIGroup` マクロが各 `@Endpoint` を走査して自動生成する。
    static var endpoints: [EndpointDescriptor] { get }

    /// グループ内エンドポイントが必要とする OAuth スコープのデフォルト
    ///
    /// 各エンドポイントが独自に `requiredScopes` を指定しない場合に継承される。
    static var requiredScopes: [String] { get }

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
    public static var requiredScopes: [String] { [] }

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

    /// このエンドポイントが必要とする OAuth スコープ（空ならグループ既定を継承）。
    public let requiredScopes: [String]

    public var fullPath: String {
        if subPath.isEmpty { return "" }
        if subPath.hasPrefix("/") { return subPath }
        return "/\(subPath)"
    }

    public init(name: String, method: APIMethod, subPath: String, requiredScopes: [String] = []) {
        self.name = name
        self.method = method
        self.subPath = subPath
        self.requiredScopes = requiredScopes
    }
}
