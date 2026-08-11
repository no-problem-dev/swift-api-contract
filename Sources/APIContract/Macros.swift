/// Declares an enum as a group of endpoints sharing a base path, auth scheme, headers and scopes.
///
/// Expansion conforms the enum to `APIContractGroup`, adds the group's static configuration,
/// and emits a peer protocol named `<EnumName>Service` carrying one `handle(_:context:)`
/// requirement per endpoint. The server implements that protocol; the generated
/// `registerAll(_:)` wires every endpoint of the group to it in one call.
///
/// Constraints worth knowing before use:
/// - Applies to an `enum` only.
/// - `endpoints` and `registerAll(_:)` are built from the `@Endpoint` structs written directly
///   in the enum body. `@StreamingEndpoint` members are not collected, and are registered
///   separately through a `StreamingRouteRegistrar`.
/// - `path`, `headers` and `scopes` are read from the source text at compile time, so they must
///   be written as literals. A value computed elsewhere is read as empty without a diagnostic.
///
/// - Parameters:
///   - path: Base path shared by the group, such as `"/v1/users"`. Each endpoint's sub-path is appended to it.
///   - auth: Auth scheme for every endpoint in the group. The expression is copied into the expansion verbatim.
///   - headers: Headers attached to every request in the group, such as an API version header.
///             An endpoint's own `@Header` wins on a key collision.
///   - scopes: OAuth scopes inherited by endpoints that do not declare their own.
///
/// ## Example
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

/// Turns a struct into one HTTP endpoint: its properties become the request, its `Output` the response.
///
/// Expansion conforms the struct to `APIContract` and `APIInput`, then generates
/// `pathParameters`, `queryParameters`, `additionalHeaders`, `encodeBody(using:)`, a memberwise
/// `init`, and the `decode(...)` the server uses to rebuild the value from a raw request.
/// Declare the response as `typealias Output`, or `EmptyOutput` when there is no response body.
///
/// Constraints worth knowing before use:
/// - Applies to a `struct` only.
/// - A stored property without a type annotation is skipped entirely, so it never reaches the
///   generated `init` or the wire.
/// - A property carrying no marker attribute is treated as a query parameter.
/// - The group is taken from the enclosing `@APIGroup` enum by lexical nesting. A struct written
///   outside a group falls back to `NoGroup`, whose base path is empty.
/// - Header properties are left out of `decode(...)`: on the server they arrive from the
///   transport, not from the reconstructed input.
///
/// - Parameters:
///   - method: HTTP method for the request.
///   - path: Sub-path appended to the group's base path. Placeholders are written `:name` or `{name}`.
///   - scopes: OAuth scopes this endpoint needs. Left empty, the group's scopes are inherited.
///
/// ## Example
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

/// Fills the `:name` or `{name}` placeholder of the endpoint's path with this property's value.
///
/// The property name is the placeholder key, so `@PathParam var userId: String` fills `:userId`.
/// There is no way to give the key a different name — rename the property instead.
///
/// The value is turned into a path segment by type: `String` as-is, numeric types and `Bool`
/// through `String(_:)`, `Date` as ISO8601. Anything else is assumed to be `RawRepresentable`
/// and converted with `.rawValue`, which is a compile error when it is not.
///
/// A path parameter left out of the request path is not caught at compile time: the placeholder
/// simply survives into the URL. On the server, a missing non-optional path parameter throws
/// `DecodingError.dataCorrupted`.
///
/// ## Example
/// ```swift
/// @Endpoint(.get, path: ":userId")
/// struct GetUser {
///     @PathParam var userId: String
///     typealias Output = User
/// }
/// ```
@attached(peer)
public macro PathParam() = #externalMacro(module: "APIContractMacros", type: "PathParamMacro")

/// Sends this property as a URL query item.
///
/// This is also what an unannotated property becomes, so the attribute is worth writing for the
/// reader even when it changes nothing. An optional property is dropped from the URL when `nil`,
/// which is how an omitted filter is expressed; a non-optional one is always sent.
///
/// Values are converted the same way as path parameters: `String` as-is, numeric types and `Bool`
/// through `String(_:)`, `Date` as ISO8601, and anything else through `.rawValue`.
///
/// - Parameter name: Key to use on the wire. Defaults to the property name, so pass this when the
///                   API expects something Swift would not spell that way, such as `snake_case`.
///
/// ## Example
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

/// Sends this property as the request body, encoded by whichever encoder the client injects.
///
/// The property type must be `Encodable`; the concrete encoder is not fixed by the endpoint, so
/// a client can swap JSON implementations without touching API definitions. Building a request
/// sets `Content-Type: application/json` whenever a body is present.
///
/// Only one body per endpoint is meaningful. Declaring a second `@Body` property is not
/// diagnosed — the extra one is silently left out of the request.
///
/// An optional body is allowed: `nil` sends no body, and on the server a missing body decodes
/// back to `nil` rather than throwing.
///
/// ## Example
/// ```swift
/// @Endpoint(.post)
/// struct CreateUser {
///     @Body var body: CreateUserRequest
///     typealias Output = User
/// }
/// ```
@attached(peer)
public macro Body() = #externalMacro(module: "APIContractMacros", type: "BodyMacro")

/// Attaches this property to the request as an HTTP header, per call rather than per group.
///
/// Use it for headers that vary between requests to the same endpoint — a feature flag, an
/// idempotency key — and put constant ones on the group instead. An optional property is omitted
/// when `nil`, and these headers are applied after the group's, so they win on a key collision.
///
/// Header properties never appear in the server-side `decode(...)`, because the server reads
/// headers from the transport.
///
/// - Parameter name: Header field name. Defaults to the property name, which is rarely what an
///                   HTTP header looks like, so this is usually worth passing.
///
/// ## Example
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

/// Registers every API group a server exposes in one call, from a struct holding its services.
///
/// Expansion walks the struct's stored properties and generates
/// `registerAll<R: Routes>(_ routes: R)`, which mounts each service and registers its group's
/// endpoints. The struct must declare at least one stored property, otherwise expansion fails.
///
/// The generated body names `Routes` and its `mount(_:)` method, neither of which this package
/// defines. The server layer using this macro has to supply both.
@attached(member, names: named(registerAll))
public macro APIServices() = #externalMacro(module: "APIContractMacros", type: "APIServicesMacro")

/// Turns a struct into an endpoint whose response arrives as a sequence of events rather than one value.
///
/// Everything `@Endpoint` generates is generated here too, except that the response is declared
/// as `typealias Event` and the struct conforms to `StreamingAPIContract`. Building a request
/// adds the Server-Sent Events headers (`Accept: text/event-stream`, `Cache-Control: no-cache`).
///
/// A streaming endpoint is not picked up by its group's `registerAll(_:)`; register it through a
/// `StreamingRouteRegistrar` instead.
///
/// - Parameters:
///   - method: HTTP method for the request, usually `.post` or `.get`.
///   - path: Sub-path appended to the group's base path.
///   - scopes: OAuth scopes this endpoint needs. Left empty, the group's scopes are inherited.
///
/// ## Example
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
