import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(APIContractMacros)
import APIContractMacros

nonisolated(unsafe) let testMacros: [String: Macro.Type] = [
    "APIGroup": APIGroupMacro.self,
    "Endpoint": EndpointMacro.self,
    "PathParam": PathParamMacro.self,
    "QueryParam": QueryParamMacro.self,
    "Body": BodyMacro.self,
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

                public func encodeBody(using encoder: JSONEncoder) throws -> Data? {
                    nil
                }

                public init() {
                }

                public static func decode(
                    pathParameters: [String: String],
                    queryParameters: [String: String],
                    body: Data?,
                    decoder: JSONDecoder
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

                public func encodeBody(using encoder: JSONEncoder) throws -> Data? {
                    nil
                }

                public init(userId: String) {
                    self.userId = userId
                }

                public static func decode(
                    pathParameters: [String: String],
                    queryParameters: [String: String],
                    body: Data?,
                    decoder: JSONDecoder
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

                public func encodeBody(using encoder: JSONEncoder) throws -> Data? {
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
                    decoder: JSONDecoder
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

                public func encodeBody(using encoder: JSONEncoder) throws -> Data? {
                    try encoder.encode(input)
                }

                public init(input: CreateUserInput) {
                    self.input = input
                }

                public static func decode(
                    pathParameters: [String: String],
                    queryParameters: [String: String],
                    body: Data?,
                    decoder: JSONDecoder
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

    // MARK: - APIGroup Tests

    func testAPIGroup() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIGroup(path: "/v1/users", auth: .required)
            enum UsersAPI {
            }
            """,
            expandedSource: """
            enum UsersAPI {

                public static let basePath: String = "/v1/users"

                public static let auth: AuthRequirement = .required

                public static let endpoints: [EndpointDescriptor] = []
            }

            public protocol UsersAPIHandler: APIGroupHandler where Group == UsersAPI {
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

    func testAPIGroupWithOptionalAuth() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @APIGroup(path: "/v1/public", auth: .optional)
            enum PublicAPI {
            }
            """,
            expandedSource: """
            enum PublicAPI {

                public static let basePath: String = "/v1/public"

                public static let auth: AuthRequirement = .optional

                public static let endpoints: [EndpointDescriptor] = []
            }

            public protocol PublicAPIHandler: APIGroupHandler where Group == PublicAPI {
            }

            extension PublicAPI: APIContractGroup {
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
        // When an @Endpoint is inside an enum with @APIGroup,
        // it should detect the parent enum and generate typealias Group
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

                    public func encodeBody(using encoder: JSONEncoder) throws -> Data? {
                        nil
                    }

                    public init(userId: String) {
                        self.userId = userId
                    }

                    public static func decode(
                        pathParameters: [String: String],
                        queryParameters: [String: String],
                        body: Data?,
                        decoder: JSONDecoder
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
