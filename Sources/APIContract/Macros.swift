/// APIグループを定義するマクロ
///
/// 関連するエンドポイントを論理グループにまとめ、共通のベースパス・認証方式・
/// HTTPヘッダー・OAuth スコープを宣言します。
/// 付与した `enum` に `APIContractGroup` 準拠と `registerAll` メソッドを自動生成し、
/// 対応する `<EnumName>Service` プロトコルをピアとして生成します。
///
/// - Parameters:
///   - path: グループの基本パス（例: `"/v1/users"`）
///   - auth: 認証方式。デフォルトは `.bearer`
///   - headers: グループ内の全エンドポイントに自動付与する共通HTTPヘッダー
///   - scopes: グループ内エンドポイントが継承する OAuth スコープのデフォルト。
///             各エンドポイントが `@Endpoint(..., scopes:)` で独自指定した場合はそちらが優先される。
///
/// ## 使用例
/// ```swift
/// @APIGroup(path: "/v1/users", auth: .bearer)
/// enum UsersAPI {
///     @Endpoint(.get)
///     struct List {
///         typealias Output = [User]
///     }
/// }
/// ```
@attached(member, names: named(basePath), named(auth), named(commonHeaders), named(requiredScopes), named(endpoints), named(registerAll))
@attached(extension, conformances: APIContractGroup)
@attached(peer, names: suffixed(Service))
public macro APIGroup(
    path: String,
    auth: AuthScheme = .bearer,
    headers: [String: String] = [:],
    scopes: [String] = []
) = #externalMacro(module: "APIContractMacros", type: "APIGroupMacro")

/// エンドポイントを定義するマクロ
///
/// 付与した `struct` に `APIContract` と `APIInput` への準拠を自動生成します。
/// パスパラメータ（`@PathParam`）、クエリパラメータ（`@QueryParam`）、
/// リクエストボディ（`@Body`）、追加ヘッダー（`@Header`）の各プロパティを解析し、
/// `pathParameters`・`queryParameters`・`encodeBody`・`additionalHeaders`・`decode` の実装を生成します。
///
/// - Parameters:
///   - method: HTTPメソッド
///   - path: サブパス（デフォルト: `""`）。グループの `basePath` と結合されて最終パスになる。
///   - scopes: このエンドポイントが必要とする OAuth スコープ。空のときはグループの
///             `requiredScopes` を継承する。
///
/// ## 使用例
/// ```swift
/// @Endpoint(.get, path: ":userId")
/// struct GetUser {
///     @PathParam var userId: String
///     typealias Output = User
/// }
/// ```
@attached(extension, conformances: APIContract, APIInput)
@attached(member, names:
    named(Input),
    named(Group),
    named(method),
    named(subPath),
    named(requiredScopes),
    named(pathParameters),
    named(queryParameters),
    named(additionalHeaders),
    named(encodeBody),
    named(init),
    named(decode)
)
public macro Endpoint(
    _ method: APIMethod,
    path: String = "",
    scopes: [String] = []
) = #externalMacro(module: "APIContractMacros", type: "EndpointMacro")

/// パスパラメータをマークするマクロ
@attached(peer)
public macro PathParam() = #externalMacro(module: "APIContractMacros", type: "PathParamMacro")

/// クエリパラメータをマークするマクロ
@attached(peer)
public macro QueryParam(
    name: String? = nil
) = #externalMacro(module: "APIContractMacros", type: "QueryParamMacro")

/// リクエストボディをマークするマクロ
@attached(peer)
public macro Body() = #externalMacro(module: "APIContractMacros", type: "BodyMacro")

/// HTTPヘッダーをマークするマクロ
///
/// エンドポイントの特定リクエストに動的に付与するHTTPヘッダーを定義する。
/// Optional型の場合、nil のときはヘッダーに含まれない。
///
/// ## 使用例
/// ```swift
/// @Endpoint(.post)
/// struct CreateMessage {
///     @Header("anthropic-beta") var beta: String?
///     @Body var request: MessageRequest
///     typealias Output = MessageResponse
/// }
/// ```
@attached(peer)
public macro Header(
    _ name: String? = nil
) = #externalMacro(module: "APIContractMacros", type: "HeaderMacro")

/// 複数のAPIサービスを一括登録するマクロ
///
/// 付与した `struct` のストアドプロパティ（各 Service 型）を走査し、
/// `registerAll<R: Routes>(_ routes: R)` メソッドを自動生成します。
/// 各プロパティ型の `Group.registerAll(routes.mount(property))` を順に呼び出します。
@attached(member, names: named(registerAll))
public macro APIServices() = #externalMacro(module: "APIContractMacros", type: "APIServicesMacro")

/// ストリーミングエンドポイントを定義するマクロ
///
/// `@Endpoint` と同じく `struct` に付与しますが、`Output` の代わりに `Event` 型を使用し、
/// `StreamingAPIContract` と `APIInput` への準拠を自動生成します。
/// Server-Sent Events (SSE) など、複数イベントをストリームとして受け取るエンドポイントに使用します。
///
/// - Parameters:
///   - method: HTTPメソッド（通常 `.post` または `.get`）
///   - path: サブパス（デフォルト: `""`）
///   - scopes: OAuth スコープ（空のときはグループ既定を継承）
///
/// ## 使用例
/// ```swift
/// @StreamingEndpoint(.post, path: "messages")
/// struct StreamMessages {
///     @Body var request: MessageRequest
///     typealias Event = MessageDelta
/// }
/// ```
@attached(extension, conformances: StreamingAPIContract, APIInput)
@attached(member, names:
    named(Input),
    named(Group),
    named(method),
    named(subPath),
    named(requiredScopes),
    named(pathParameters),
    named(queryParameters),
    named(additionalHeaders),
    named(encodeBody),
    named(init),
    named(decode)
)
public macro StreamingEndpoint(
    _ method: APIMethod,
    path: String = "",
    scopes: [String] = []
) = #externalMacro(module: "APIContractMacros", type: "StreamingEndpointMacro")
