/// APIグループを定義するマクロ
@attached(member, names: named(basePath), named(auth), named(endpoints), named(registerAll))
@attached(extension, conformances: APIContractGroup)
@attached(peer, names: suffixed(Service))
public macro APIGroup(
    path: String,
    auth: AuthRequirement = .required
) = #externalMacro(module: "APIContractMacros", type: "APIGroupMacro")

/// エンドポイントを定義するマクロ
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

/// 複数のAPIサービスをグループ化するマクロ
@attached(member, names: named(registerAll))
public macro APIServices() = #externalMacro(module: "APIContractMacros", type: "APIServicesMacro")
