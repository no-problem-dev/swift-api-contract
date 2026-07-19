import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(APIContractMacros)
import APIContractMacros
#endif

final class StreamingEndpointMacroTests: XCTestCase {

    // MARK: - Basic Expansion Tests

    func testSimpleStreamingEndpoint() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @StreamingEndpoint(.get, path: "/v1/events")
            struct StreamEvents {
                typealias Event = ServerEvent
            }
            """,
            expandedSource: """
            struct StreamEvents {
                typealias Event = ServerEvent

                public typealias Input = Self

                public static let method: APIMethod = .get

                public static let subPath: String = "/v1/events"

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

            extension StreamEvents: StreamingAPIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStreamingEndpointWithBody() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @StreamingEndpoint(.post, path: "messages")
            struct StreamMessages {
                @Body var request: MessageRequest
                typealias Event = MessageDelta
            }
            """,
            expandedSource: """
            struct StreamMessages {
                var request: MessageRequest
                typealias Event = MessageDelta

                public typealias Input = Self

                public static let method: APIMethod = .post

                public static let subPath: String = "messages"

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
                    try encoder.encode(request)
                }

                public init(request: MessageRequest) {
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

            extension StreamMessages: StreamingAPIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStreamingEndpointWithQueryParams() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @StreamingEndpoint(.get, path: "/v1/events")
            struct StreamEvents {
                @QueryParam var channel: String?
                typealias Event = ServerEvent
            }
            """,
            expandedSource: """
            struct StreamEvents {
                var channel: String?
                typealias Event = ServerEvent

                public typealias Input = Self

                public static let method: APIMethod = .get

                public static let subPath: String = "/v1/events"

                public var pathParameters: [String: String] {
                    [:]
                }

                public var queryParameters: [String: String]? {
                    var params: [String: String] = [:]
                    if let channel {
                        params["channel"] = channel
                    }
                    return params.isEmpty ? nil : params
                }

                public var additionalHeaders: [String: String] {
                    [:]
                }

                public func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? {
                    nil
                }

                public init(channel: String? = nil) {
                    self.channel = channel
                }

                public static func decode(
                    pathParameters: [String: String],
                    queryParameters: [String: String],
                    body: Data?,
                    decoder: any APIBodyDecoder
                ) throws -> Self {
                    let channel = queryParameters["channel"]
                    return Self(channel: channel)
                }
            }

            extension StreamEvents: StreamingAPIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStreamingEndpointInsideAPIGroup() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            enum MessagesAPI {
                @StreamingEndpoint(.post, path: "stream")
                struct Stream {
                    @Body var request: MessageRequest
                    typealias Event = MessageDelta
                }
            }
            """,
            expandedSource: """
            enum MessagesAPI {
                struct Stream {
                    var request: MessageRequest
                    typealias Event = MessageDelta

                    public typealias Input = Self

                    public typealias Group = MessagesAPI

                    public static let method: APIMethod = .post

                    public static let subPath: String = "stream"

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
                        try encoder.encode(request)
                    }

                    public init(request: MessageRequest) {
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
            }

            extension MessagesAPI.Stream: StreamingAPIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStreamingEndpointWithScopes() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @StreamingEndpoint(.get, path: "/v1/events", scopes: ["events.read"])
            struct StreamEvents {
                typealias Event = ServerEvent
            }
            """,
            expandedSource: """
            struct StreamEvents {
                typealias Event = ServerEvent

                public typealias Input = Self

                public static let method: APIMethod = .get

                public static let subPath: String = "/v1/events"

                public static let requiredScopes: [String] = ["events.read"]

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

            extension StreamEvents: StreamingAPIContract, APIInput {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Diagnostics Tests

    func testStreamingEndpointOnNonStruct() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @StreamingEndpoint(.get, path: "/v1/events")
            class NotAStruct {
            }
            """,
            expandedSource: """
            class NotAStruct {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@StreamingEndpoint can only be applied to structs", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStreamingEndpointWithoutArguments() throws {
        #if canImport(APIContractMacros)
        assertMacroExpansion(
            """
            @StreamingEndpoint
            struct StreamEvents {
                typealias Event = ServerEvent
            }
            """,
            expandedSource: """
            struct StreamEvents {
                typealias Event = ServerEvent
            }

            extension StreamEvents: StreamingAPIContract, APIInput {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@StreamingEndpoint requires a valid APIMethod argument", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
