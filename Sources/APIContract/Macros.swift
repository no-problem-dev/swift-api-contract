/// APIグループを定義するマクロ
///
/// 関連するエンドポイントを論理グループにまとめ、共通のベースパス・認証方式・
/// HTTPヘッダー・OAuth スコープを宣言する。
/// 付与した `enum` に `APIContractGroup` 準拠と `registerAll` メソッドを自動生成し、
/// 対応する `<EnumName>Service` プロトコルをピアとして生成する。
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
/// 付与した `struct` に `APIContract` と `APIInput` への準拠を自動生成する。
/// パスパラメータ（`@PathParam`）、クエリパラメータ（`@QueryParam`）、
/// リクエストボディ（`@Body`）、追加ヘッダー（`@Header`）の各プロパティを解析し、
/// `pathParameters`・`queryParameters`・`encodeBody`・`additionalHeaders`・`decode` の実装を生成する。
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
///
/// `@Endpoint` の `path:` に含まれるプレースホルダー（`:プロパティ名`）と対応するプロパティに付与する。
/// マクロ展開時にプロパティ名がキーとして `pathParameters` ディクショナリに登録され、
/// 実行時にパステンプレートの該当箇所が実際の値に置換される。
///
/// ## 使用例
/// ```swift
/// @Endpoint(.get, path: ":userId")
/// struct GetUser {
///     @PathParam var userId: String
///     typealias Output = User
/// }
/// ```
@attached(peer)
public macro PathParam() = #externalMacro(module: "APIContractMacros", type: "PathParamMacro")

/// クエリパラメータをマークするマクロ
///
/// 付与したプロパティをURLクエリパラメータとして扱う。Optional 型の場合、値が `nil` のときは
/// クエリに含まれない。
///
/// - Parameters:
///   - name: クエリパラメータのキー名。省略するとプロパティ名がそのまま使われる。
///           Swift の命名規約（camelCase）とAPIのキー名（snake_case など）が異なる場合に指定する。
///
/// ## 使用例
/// ```swift
/// @Endpoint(.get)
/// struct SearchUsers {
///     @QueryParam var query: String
///     @QueryParam(name: "page_size") var pageSize: Int?
///     typealias Output = [User]
/// }
/// ```
@attached(peer)
public macro QueryParam(
    name: String? = nil
) = #externalMacro(module: "APIContractMacros", type: "QueryParamMacro")

/// リクエストボディをマークするマクロ
///
/// `Encodable` に準拠した型のプロパティに付与し、リクエストボディとしてJSON（または設定した
/// `APIBodyEncoder`）でエンコードすることを宣言する。1エンドポイントに付与できるのは1プロパティのみ。
///
/// ## 使用例
/// ```swift
/// @Endpoint(.post)
/// struct CreateUser {
///     @Body var body: CreateUserRequest
///     typealias Output = User
/// }
/// ```
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
/// `registerAll<R: Routes>(_ routes: R)` メソッドを自動生成する。
/// 各プロパティ型の `Group.registerAll(routes.mount(property))` を順に呼び出す。
@attached(member, names: named(registerAll))
public macro APIServices() = #externalMacro(module: "APIContractMacros", type: "APIServicesMacro")

/// ストリーミングエンドポイントを定義するマクロ
///
/// `@Endpoint` と同じく `struct` に付与するが、`Output` の代わりに `Event` 型を使用し、
/// `StreamingAPIContract` と `APIInput` への準拠を自動生成する。
/// Server-Sent Events (SSE) など、複数イベントをストリームとして受け取るエンドポイントに使う。
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
