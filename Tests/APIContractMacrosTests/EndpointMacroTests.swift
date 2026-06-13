import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(APIContractMacros)
import APIContractMacros

let testMacros: [String: Macro.Type] = [
    "APIGroup": APIGroupMacro.self,
    "Endpoint": EndpointMacro.self,
    "StreamingEndpoint": StreamingEndpointMacro.self,
    "PathParam": PathParamMacro.self,
    "QueryParam": QueryParamMacro.self,
    "Body": BodyMacro.self,
    "Header": HeaderMacro.self,
]
#endif

final class EndpointMacroTests: XCTestCase {

    // MARK: - Basic Endpoint Tests

    func testSimpleGetEndpoint() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @Endpoint(.get, path: "/v1/users")
            struct ListUsers {
                typealias Output = [User]
            }
            """,
            expandedSource: """
            struct ListUsers {
                typealias Output = [User]

                public typealias Input = Self

                public static let method: APIMethod = .get

                public static let subPath: String = "/v1/users"

                public var pathParameters: [String: String] {
                    [:]
                }

                public var queryParameters: [String: String]? {
                    nil
                }

                public var additionalHeaders: [String: String] {
                    [:]
                }

                public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? {
                    nil
                }

                public init() {
                }

                public static func decode(
                    pathParameters: [String: String],
                    queryParameters: [String: String],
                    body: Data?,
                    decoder: any APIBodyDecoder
                ) throws -> Self {
                    Self()
                }
            }

            extension ListUsers: APIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testEndpointWithPathParam() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @Endpoint(.get, path: "/v1/users/:userId")
            struct GetUser {
                @PathParam var userId: String
                typealias Output = User
            }
            """,
            expandedSource: """
            struct GetUser {
                var userId: String
                typealias Output = User

                public typealias Input = Self

                public static let method: APIMethod = .get

                public static let subPath: String = "/v1/users/:userId"

                public var pathParameters: [String: String] {
                    ["userId": userId]
                }

                public var queryParameters: [String: String]? {
                    nil
                }

                public var additionalHeaders: [String: String] {
                    [:]
                }

                public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? {
                    nil
                }

                public init(userId: String) {
                    self.userId = userId
                }

                public static func decode(
                    pathParameters: [String: String],
                    queryParameters: [String: String],
                    body: Data?,
                    decoder: any APIBodyDecoder
                ) throws -> Self {
                    guard let userId = pathParameters["userId"] else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing path parameter: userId"))
                    }
                    return Self(userId: userId)
                }
            }

            extension GetUser: APIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testEndpointWithQueryParams() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @Endpoint(.get, path: "/v1/users")
            struct ListUsers {
                @QueryParam var limit: Int?
                @QueryParam var offset: Int?
                typealias Output = [User]
            }
            """,
            expandedSource: """
            struct ListUsers {
                var limit: Int?
                var offset: Int?
                typealias Output = [User]

                public typealias Input = Self

                public static let method: APIMethod = .get

                public static let subPath: String = "/v1/users"

                public var pathParameters: [String: String] {
                    [:]
                }

                public var queryParameters: [String: String]? {
                    var params: [String: String] = [:]
                    if let limit {
                        params["limit"] = String(limit)
                    }
                    if let offset {
                        params["offset"] = String(offset)
                    }
                    return params.isEmpty ? nil : params
                }

                public var additionalHeaders: [String: String] {
                    [:]
                }

                public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? {
                    nil
                }

                public init(limit: Int? = nil, offset: Int? = nil) {
                    self.limit = limit
                    self.offset = offset
                }

                public static func decode(
                    pathParameters: [String: String],
                    queryParameters: [String: String],
                    body: Data?,
                    decoder: any APIBodyDecoder
                ) throws -> Self {
                    let limit = queryParameters["limit"].flatMap {
                        Int($0)
                    }
                    let offset = queryParameters["offset"].flatMap {
                        Int($0)
                    }
                    return Self(limit: limit, offset: offset)
                }
            }

            extension ListUsers: APIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testEndpointWithBody() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @Endpoint(.post, path: "/v1/users")
            struct CreateUser {
                @Body var input: CreateUserInput
                typealias Output = User
            }
            """,
            expandedSource: """
            struct CreateUser {
                var input: CreateUserInput
                typealias Output = User

                public typealias Input = Self

                public static let method: APIMethod = .post

                public static let subPath: String = "/v1/users"

                public var pathParameters: [String: String] {
                    [:]
                }

                public var queryParameters: [String: String]? {
                    nil
                }

                public var additionalHeaders: [String: String] {
                    [:]
                }

                public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? {
                    try encoder.encode(input)
                }

                public init(input: CreateUserInput) {
                    self.input = input
                }

                public static func decode(
                    pathParameters: [String: String],
                    queryParameters: [String: String],
                    body: Data?,
                    decoder: any APIBodyDecoder
                ) throws -> Self {
                    guard let bodyData = body else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing request body"))
                    }
                    let input = try decoder.decode(CreateUserInput.self, from: bodyData)
                    return Self(input: input)
                }
            }

            extension CreateUser: APIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Header Tests

    func testEndpointWithHeader() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @Endpoint(.post)
            struct CreateMessage {
                @Header("anthropic-beta") var beta: String?
                @Body var request: MessageRequest
                typealias Output = MessageResponse
            }
            """,
            expandedSource: """
            struct CreateMessage {
                var beta: String?
                var request: MessageRequest
                typealias Output = MessageResponse

                public typealias Input = Self

                public static let method: APIMethod = .post

                public static let subPath: String = ""

                public var pathParameters: [String: String] {
                    [:]
                }

                public var queryParameters: [String: String]? {
                    nil
                }

                public var additionalHeaders: [String: String] {
                    var headers: [String: String] = [:]
                    if let beta {
                        headers["anthropic-beta"] = beta
                    }
                    return headers
                }

                public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? {
                    try encoder.encode(request)
                }

                public init(beta: String? = nil, request: MessageRequest) {
                    self.beta = beta
                    self.request = request
                }

                public static func decode(
                    pathParameters: [String: String],
                    queryParameters: [String: String],
                    body: Data?,
                    decoder: any APIBodyDecoder
                ) throws -> Self {
                    guard let bodyData = body else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing request body"))
                    }
                    let request = try decoder.decode(MessageRequest.self, from: bodyData)
                    return Self(request: request)
                }
            }

            extension CreateMessage: APIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - APIGroup Tests

    func testAPIGroup() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIGroup(path: "/v1/users", auth: .bearer)
            enum UsersAPI {
            }
            """,
            expandedSource: """
            enum UsersAPI {

                public static let basePath: String = "/v1/users"

                public static let auth: AuthScheme = .bearer

                public static let commonHeaders: [String: String] = [:]

                public static let requiredScopes: [String] = []

                public static let endpoints: [EndpointDescriptor] = []

                @discardableResult
                    public static func registerAll<R: APIRouteRegistrar>(_ routes: R) -> R where R.Group == UsersAPI, R.Service: UsersAPIService {
                        return routes
                    }
            }

            public protocol UsersAPIService: APIService where Group == UsersAPI {
            }

            extension UsersAPI: APIContractGroup {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAPIGroupWithAPIKeyAuth() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIGroup(path: "/v1/messages", auth: .apiKey(headerName: "x-api-key"), headers: ["anthropic-version": "2023-06-01"])
            enum AnthropicAPI {
            }
            """,
            expandedSource: """
            enum AnthropicAPI {

                public static let basePath: String = "/v1/messages"

                public static let auth: AuthScheme = .apiKey(headerName: "x-api-key")

                public static let commonHeaders: [String: String] = ["anthropic-version": "2023-06-01"]

                public static let requiredScopes: [String] = []

                public static let endpoints: [EndpointDescriptor] = []

                @discardableResult
                    public static func registerAll<R: APIRouteRegistrar>(_ routes: R) -> R where R.Group == AnthropicAPI, R.Service: AnthropicAPIService {
                        return routes
                    }
            }

            public protocol AnthropicAPIService: APIService where Group == AnthropicAPI {
            }

            extension AnthropicAPI: APIContractGroup {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Scope Tests

    func testEndpointWithScopes() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @Endpoint(.post, path: "/events", scopes: ["https://www.googleapis.com/auth/calendar"])
            struct CreateEvent {
                @Body var event: Event
                typealias Output = Event
            }
            """,
            expandedSource: """
            struct CreateEvent {
                var event: Event
                typealias Output = Event

                public typealias Input = Self

                public static let method: APIMethod = .post

                public static let subPath: String = "/events"

                public static let requiredScopes: [String] = ["https://www.googleapis.com/auth/calendar"]

                public var pathParameters: [String: String] {
                    [:]
                }

                public var queryParameters: [String: String]? {
                    nil
                }

                public var additionalHeaders: [String: String] {
                    [:]
                }

                public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? {
                    try encoder.encode(event)
                }

                public init(event: Event) {
                    self.event = event
                }

                public static func decode(
                    pathParameters: [String: String],
                    queryParameters: [String: String],
                    body: Data?,
                    decoder: any APIBodyDecoder
                ) throws -> Self {
                    guard let bodyData = body else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing request body"))
                    }
                    let event = try decoder.decode(Event.self, from: bodyData)
                    return Self(event: event)
                }
            }

            extension CreateEvent: APIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAPIGroupWithScopes() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIGroup(path: "/calendar/v3", scopes: ["https://www.googleapis.com/auth/calendar.readonly"])
            enum CalendarAPI {
            }
            """,
            expandedSource: """
            enum CalendarAPI {

                public static let basePath: String = "/calendar/v3"

                public static let auth: AuthScheme = .bearer

                public static let commonHeaders: [String: String] = [:]

                public static let requiredScopes: [String] = ["https://www.googleapis.com/auth/calendar.readonly"]

                public static let endpoints: [EndpointDescriptor] = []

                @discardableResult
                    public static func registerAll<R: APIRouteRegistrar>(_ routes: R) -> R where R.Group == CalendarAPI, R.Service: CalendarAPIService {
                        return routes
                    }
            }

            public protocol CalendarAPIService: APIService where Group == CalendarAPI {
            }

            extension CalendarAPI: APIContractGroup {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Nested Endpoint Tests

    func testEndpointInsideAPIGroup() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            enum UsersAPI {
                @Endpoint(.get, path: ":userId")
                struct Get {
                    @PathParam var userId: String
                    typealias Output = User
                }
            }
            """,
            expandedSource: """
            enum UsersAPI {
                struct Get {
                    var userId: String
                    typealias Output = User

                    public typealias Input = Self

                    public typealias Group = UsersAPI

                    public static let method: APIMethod = .get

                    public static let subPath: String = ":userId"

                    public var pathParameters: [String: String] {
                        ["userId": userId]
                    }

                    public var queryParameters: [String: String]? {
                        nil
                    }

                    public var additionalHeaders: [String: String] {
                        [:]
                    }

                    public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? {
                        nil
                    }

                    public init(userId: String) {
                        self.userId = userId
                    }

                    public static func decode(
                        pathParameters: [String: String],
                        queryParameters: [String: String],
                        body: Data?,
                        decoder: any APIBodyDecoder
                    ) throws -> Self {
                        guard let userId = pathParameters["userId"] else {
                            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing path parameter: userId"))
                        }
                        return Self(userId: userId)
                    }
                }
            }

            extension UsersAPI.Get: APIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Error Tests

    func testEndpointOnNonStruct() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @Endpoint(.get)
            class NotAStruct {
            }
            """,
            expandedSource: """
            class NotAStruct {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Endpoint can only be applied to structs", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAPIGroupOnNonEnum() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIGroup(path: "/v1/users")
            struct NotAnEnum {
            }
            """,
            expandedSource: """
            struct NotAnEnum {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@APIGroup can only be applied to enums", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
