// MARK: - API Contract Macros

/// APIグループを定義するマクロ
///
/// enumに付与して、関連するエンドポイントをグループ化します。
/// ベースパスと認証要件を指定できます。
/// また、対応するHandlerプロトコルも自動生成されます。
///
/// ## 使用例
/// ```swift
/// @APIGroup(path: "/v1/users", auth: .required)
/// public enum UsersAPI {
///     @Endpoint(.get)
///     struct List { ... }
///
///     @Endpoint(.post)
///     struct Create { ... }
/// }
/// ```
///
/// ## 生成されるコード
/// ```swift
/// public enum UsersAPI {
///     public static let basePath = "/v1/users"
///     public static let auth: AuthRequirement = .required
///     public static let endpoints: [EndpointDescriptor] = [...]
/// }
///
/// public protocol UsersAPIHandler: APIGroupHandler where Group == UsersAPI {
///     func handle(_ input: UsersAPI.List, context: HandlerContext) async throws -> [User]
///     func handle(_ input: UsersAPI.Create, context: HandlerContext) async throws -> User
/// }
/// ```
@attached(member, names: named(basePath), named(auth), named(endpoints))
@attached(extension, conformances: APIContractGroup)
@attached(peer, names: suffixed(Handler))
public macro APIGroup(
    path: String,
    auth: AuthRequirement = .required
) = #externalMacro(module: "APIContractMacros", type: "APIGroupMacro")

/// エンドポイントを定義するマクロ
///
/// structに付与して、APIエンドポイントを定義します。
/// `APIContract` と `APIInput` プロトコルへの準拠を自動生成します。
///
/// ## 使用例
/// ```swift
/// @APIGroup(path: "/v1/users", auth: .required)
/// enum UsersAPI {
///     @Endpoint(.get, path: ":userId")
///     struct Get {
///         @PathParam var userId: String
///         typealias Output = User
///     }
///
///     @Endpoint(.get)  // path省略で親グループのパスをそのまま使用
///     struct List {
///         @QueryParam var limit: Int?
///         typealias Output = [User]
///     }
/// }
/// ```
///
/// ## 生成されるコード
/// - `APIContract` 準拠（`Group`はレキシカルコンテキストから自動検出）
/// - `APIInput` 準拠
/// - `method`, `subPath` 静的プロパティ
/// - `pathParameters`, `queryParameters` 計算プロパティ
/// - `encodeBody(using:)` メソッド
/// - `init` イニシャライザ
@attached(extension, conformances: APIContract, APIInput)
@attached(member, names:
    named(Input),
    named(Group),
    named(method),
    named(subPath),
    named(pathParameters),
    named(queryParameters),
    named(encodeBody),
    named(init),
    named(decode)
)
public macro Endpoint(
    _ method: APIMethod,
    path: String = ""
) = #externalMacro(module: "APIContractMacros", type: "EndpointMacro")

/// パスパラメータをマークするマクロ
///
/// プロパティに付与して、パスパラメータとして使用することを示します。
/// パステンプレート内の `:paramName` を置換するために使用されます。
///
/// ## 使用例
/// ```swift
/// @Endpoint(.get, path: ":userId/posts/:postId")
/// struct GetPost {
///     @PathParam var userId: String
///     @PathParam var postId: String
///     typealias Output = Post
/// }
/// ```
///
/// プロパティ名がそのままパスパラメータ名として使用されます。
@attached(peer)
public macro PathParam() = #externalMacro(module: "APIContractMacros", type: "PathParamMacro")

/// クエリパラメータをマークするマクロ
///
/// プロパティに付与して、クエリパラメータとして使用することを示します。
/// URLのクエリ文字列として付与されます。
///
/// ## 使用例
/// ```swift
/// @Endpoint(.get)
/// struct ListUsers {
///     @QueryParam var limit: Int?
///     @QueryParam var offset: Int?
///     @QueryParam(name: "sort_by") var sortBy: String?
///     typealias Output = [User]
/// }
/// ```
///
/// - Parameter name: カスタムパラメータ名（省略時はプロパティ名を使用）
@attached(peer)
public macro QueryParam(
    name: String? = nil
) = #externalMacro(module: "APIContractMacros", type: "QueryParamMacro")

/// リクエストボディをマークするマクロ
///
/// プロパティに付与して、リクエストボディとして使用することを示します。
/// POST/PUT/PATCH リクエストのボディとして送信されます。
///
/// ## 使用例
/// ```swift
/// @Endpoint(.post)
/// struct CreateUser {
///     @Body var input: CreateUserInput
///     typealias Output = User
/// }
/// ```
///
/// `@Body` は1つのエンドポイントに1つだけ指定できます。
@attached(peer)
public macro Body() = #externalMacro(module: "APIContractMacros", type: "BodyMacro")
