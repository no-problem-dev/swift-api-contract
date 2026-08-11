import XCTest
import Foundation
@testable import APIContract

// MARK: - Test Groups

enum TestGroup: APIContractGroup {
    static let basePath: String = "/v1"
    static let auth: AuthScheme = .bearer
    static let endpoints: [EndpointDescriptor] = []
}

enum EmptyGroup: APIContractGroup {
    static let basePath: String = ""
    static let auth: AuthScheme = .none
    static let endpoints: [EndpointDescriptor] = []
}

enum APIKeyGroup: APIContractGroup {
    static let basePath: String = "/v1/messages"
    static let auth: AuthScheme = .apiKey(headerName: "x-api-key")
    static let commonHeaders: [String: String] = ["anthropic-version": "2023-06-01"]
    static let endpoints: [EndpointDescriptor] = []
}

// MARK: - Test Contracts

struct GetUsersContract: APIContract, APIInput {
    typealias Group = TestGroup
    typealias Input = Self
    typealias Output = EmptyOutput

    static let method: APIMethod = .get
    static let subPath: String = "/users"

    var pathParameters: [String: String] { [:] }
    var queryParameters: [String: String]? { nil }

    func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }

    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: any APIBodyDecoder
    ) throws -> Self {
        Self()
    }
}

struct GetUserContract: APIContract, APIInput {
    typealias Group = TestGroup
    typealias Input = Self
    typealias Output = EmptyOutput

    static let method: APIMethod = .get
    static let subPath: String = "/users/:id"

    let userId: String

    var pathParameters: [String: String] { ["id": userId] }
    var queryParameters: [String: String]? { nil }

    func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }

    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: any APIBodyDecoder
    ) throws -> Self {
        Self(userId: pathParameters["id"] ?? "")
    }
}

struct CustomPathContract: APIContract, APIInput {
    typealias Group = NoGroup
    typealias Input = Self
    typealias Output = EmptyOutput

    static let method: APIMethod = .get
    static let subPath: String = ""

    let customPath: String

    var pathParameters: [String: String] { [:] }
    var queryParameters: [String: String]? { nil }

    func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }

    static func resolvePath(with input: Self) -> String {
        input.customPath
    }

    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: any APIBodyDecoder
    ) throws -> Self {
        fatalError("Client-only contract")
    }
}

struct NoGroupContract: APIContract, APIInput {
    typealias Group = NoGroup
    typealias Input = Self
    typealias Output = EmptyOutput

    static let method: APIMethod = .post
    static let subPath: String = "/api/data"

    var pathParameters: [String: String] { [:] }
    var queryParameters: [String: String]? { nil }

    func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }

    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: any APIBodyDecoder
    ) throws -> Self {
        Self()
    }
}

/// Endpoint carrying its own headers, used to check they override the group's.
struct HeaderContract: APIContract, APIInput {
    typealias Group = APIKeyGroup
    typealias Input = Self
    typealias Output = EmptyOutput

    static let method: APIMethod = .post
    static let subPath: String = ""

    let betaHeader: String?

    var pathParameters: [String: String] { [:] }
    var queryParameters: [String: String]? { nil }
    var additionalHeaders: [String: String] {
        var headers: [String: String] = [:]
        if let betaHeader {
            headers["anthropic-beta"] = betaHeader
        }
        return headers
    }

    func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }

    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: any APIBodyDecoder
    ) throws -> Self {
        Self(betaHeader: nil)
    }
}

// MARK: - Tests

final class APIContractTests: XCTestCase {

    // MARK: - pathTemplate Tests

    func testPathTemplateWithGroup() {
        XCTAssertEqual(GetUsersContract.pathTemplate, "/v1/users")
    }

    func testPathTemplateWithNoGroup() {
        XCTAssertEqual(NoGroupContract.pathTemplate, "/api/data")
    }

    func testPathTemplateWithPathParameter() {
        XCTAssertEqual(GetUserContract.pathTemplate, "/v1/users/:id")
    }

    // MARK: - resolvePath Default Implementation Tests

    func testResolvePathSimple() {
        let contract = GetUsersContract()
        let path = GetUsersContract.resolvePath(with: contract)
        XCTAssertEqual(path, "/v1/users")
    }

    func testResolvePathWithPathParameter() {
        let contract = GetUserContract(userId: "123")
        let path = GetUserContract.resolvePath(with: contract)
        XCTAssertEqual(path, "/v1/users/123")
    }

    func testResolvePathWithMultiplePathParameters() {
        struct MultiParamContract: APIContract, APIInput {
            typealias Group = TestGroup
            typealias Input = Self
            typealias Output = EmptyOutput

            static let method: APIMethod = .get
            static let subPath: String = "/users/:userId/posts/:postId"

            let userId: String
            let postId: String

            var pathParameters: [String: String] {
                ["userId": userId, "postId": postId]
            }
            var queryParameters: [String: String]? { nil }

            func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }

            static func decode(
                pathParameters: [String: String],
                queryParameters: [String: String],
                body: Data?,
                decoder: any APIBodyDecoder
            ) throws -> Self {
                Self(
                    userId: pathParameters["userId"] ?? "",
                    postId: pathParameters["postId"] ?? ""
                )
            }
        }

        let contract = MultiParamContract(userId: "user-1", postId: "post-2")
        let path = MultiParamContract.resolvePath(with: contract)
        XCTAssertEqual(path, "/v1/users/user-1/posts/post-2")
    }

    func testResolvePathWithBracePlaceholder() {
        // `{key}` is the placeholder syntax Go chi and OpenAPI use, so contracts written against
        // an existing spec keep that spelling. Both forms have to resolve to the same parameter.
        struct BraceContract: APIContract, APIInput {
            typealias Group = TestGroup
            typealias Input = Self
            typealias Output = EmptyOutput

            static let method: APIMethod = .patch
            static let subPath: String = "/social-challenges/{id}/status"

            let id: String

            var pathParameters: [String: String] { ["id": id] }
            var queryParameters: [String: String]? { nil }

            func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }

            static func decode(
                pathParameters: [String: String],
                queryParameters: [String: String],
                body: Data?,
                decoder: any APIBodyDecoder
            ) throws -> Self {
                Self(id: pathParameters["id"] ?? "")
            }
        }

        let contract = BraceContract(id: "abc-123")
        let path = BraceContract.resolvePath(with: contract)
        XCTAssertEqual(path, "/v1/social-challenges/abc-123/status")
    }

    // MARK: - Custom resolvePath Tests

    func testCustomResolvePathDirectCall() {
        let contract = CustomPathContract(customPath: "/custom/endpoint")
        let path = CustomPathContract.resolvePath(with: contract)
        XCTAssertEqual(path, "/custom/endpoint")
    }

    func testCustomResolvePathGenericCall() {
        func resolveGeneric<E: APIContract>(_ contract: E) -> String
            where E.Input == E, E: APIInput
        {
            E.resolvePath(with: contract)
        }

        let contract = CustomPathContract(customPath: "/v2/custom/path")
        let path = resolveGeneric(contract)
        XCTAssertEqual(path, "/v2/custom/path")
    }

    // MARK: - buildRequest Tests

    func testBuildRequestWithDefaultPath() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let contract = GetUsersContract()
        let request = try contract.buildRequest(baseURL: baseURL)

        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v1/users")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildRequestWithPathParameter() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let contract = GetUserContract(userId: "456")
        let request = try contract.buildRequest(baseURL: baseURL)

        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v1/users/456")
    }

    func testBuildRequestWithCustomPath() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let contract = CustomPathContract(customPath: "/v3/special/resource")
        let request = try contract.buildRequest(baseURL: baseURL)

        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v3/special/resource")
    }

    func testBuildRequestWithQueryParameters() throws {
        struct QueryContract: APIContract, APIInput {
            typealias Group = TestGroup
            typealias Input = Self
            typealias Output = EmptyOutput

            static let method: APIMethod = .get
            static let subPath: String = "/search"

            let query: String
            let page: Int

            var pathParameters: [String: String] { [:] }
            var queryParameters: [String: String]? {
                ["q": query, "page": "\(page)"]
            }

            func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }

            static func decode(
                pathParameters: [String: String],
                queryParameters: [String: String],
                body: Data?,
                decoder: any APIBodyDecoder
            ) throws -> Self {
                Self(query: queryParameters["q"] ?? "", page: Int(queryParameters["page"] ?? "0") ?? 0)
            }
        }

        let baseURL = URL(string: "https://api.example.com")!
        let contract = QueryContract(query: "test", page: 1)
        let request = try contract.buildRequest(baseURL: baseURL)

        let url = request.url!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []

        XCTAssertTrue(queryItems.contains { $0.name == "q" && $0.value == "test" })
        XCTAssertTrue(queryItems.contains { $0.name == "page" && $0.value == "1" })
    }

    // MARK: - Headers Tests

    func testBuildRequestWithGroupCommonHeaders() throws {
        let baseURL = URL(string: "https://api.anthropic.com")!
        let contract = HeaderContract(betaHeader: nil)
        let request = try contract.buildRequest(baseURL: baseURL)

        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
    }

    func testBuildRequestWithAdditionalHeaders() throws {
        let baseURL = URL(string: "https://api.anthropic.com")!
        let contract = HeaderContract(betaHeader: "structured-outputs-2025-11-13")
        let request = try contract.buildRequest(baseURL: baseURL)

        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-beta"), "structured-outputs-2025-11-13")
    }

    func testBuildRequestWithoutAdditionalHeaders() throws {
        let baseURL = URL(string: "https://api.anthropic.com")!
        let contract = HeaderContract(betaHeader: nil)
        let request = try contract.buildRequest(baseURL: baseURL)

        XCTAssertNil(request.value(forHTTPHeaderField: "anthropic-beta"))
    }

    // MARK: - APIMethod Tests

    func testAPIMethodRawValues() {
        XCTAssertEqual(APIMethod.get.rawValue, "GET")
        XCTAssertEqual(APIMethod.post.rawValue, "POST")
        XCTAssertEqual(APIMethod.put.rawValue, "PUT")
        XCTAssertEqual(APIMethod.patch.rawValue, "PATCH")
        XCTAssertEqual(APIMethod.delete.rawValue, "DELETE")
    }

    // MARK: - AuthScheme Tests

    func testAuthSchemeFromGroup() {
        XCTAssertEqual(GetUsersContract.auth, .bearer)
        XCTAssertEqual(NoGroupContract.auth, .bearer) // NoGroup defaults to bearer
    }

    func testAuthSchemeAPIKey() {
        XCTAssertEqual(APIKeyGroup.auth, .apiKey(headerName: "x-api-key"))
    }

    func testAuthSchemeNone() {
        XCTAssertEqual(EmptyGroup.auth, .none)
    }

    // MARK: - APIResponse Tests

    func testAPIResponseHeaderLookup() {
        let response = APIResponse(
            output: EmptyOutput(),
            statusCode: 200,
            headers: ["X-RateLimit-Remaining": "100", "Content-Type": "application/json"]
        )

        XCTAssertEqual(response.header("x-ratelimit-remaining"), "100")
        XCTAssertEqual(response.header("X-RateLimit-Remaining"), "100")
        XCTAssertNil(response.header("X-Missing"))
    }

    // MARK: - EmptyOutput Tests

    func testEmptyOutputDecoding() throws {
        let json = "{}".data(using: .utf8)!
        let decoder = JSONDecoder()
        let output = try decoder.decode(EmptyOutput.self, from: json)
        XCTAssertNotNil(output)
    }

    // MARK: - EmptyInput Tests

    func testEmptyInputProperties() {
        let input = EmptyInput()
        XCTAssertTrue(input.pathParameters.isEmpty)
        XCTAssertNil(input.queryParameters)
        XCTAssertNil(try input.encodeBody(using: JSONEncoder()))
    }
}

// MARK: - APIInput Tests

final class APIInputTests: XCTestCase {

    func testAPIInputConformance() {
        struct TestInput: APIInput {
            let id: String
            let name: String

            var pathParameters: [String: String] { ["id": id] }
            var queryParameters: [String: String]? { ["name": name] }

            func encodeBody(using encoder: any APIBodyEncoder) throws -> Data? { nil }

            static func decode(
                pathParameters: [String: String],
                queryParameters: [String: String],
                body: Data?,
                decoder: any APIBodyDecoder
            ) throws -> Self {
                Self(id: pathParameters["id"] ?? "", name: queryParameters["name"] ?? "")
            }
        }

        let input = TestInput(id: "123", name: "test")
        XCTAssertEqual(input.pathParameters["id"], "123")
        XCTAssertEqual(input.queryParameters?["name"], "test")
    }
}

// MARK: - APIContractGroup Tests

final class APIContractGroupTests: XCTestCase {

    func testNoGroupDefaults() {
        XCTAssertEqual(NoGroup.basePath, "")
        XCTAssertEqual(NoGroup.auth, .bearer)
        XCTAssertTrue(NoGroup.endpoints.isEmpty)
        XCTAssertTrue(NoGroup.commonHeaders.isEmpty)
    }

    func testCustomGroup() {
        XCTAssertEqual(TestGroup.basePath, "/v1")
        XCTAssertEqual(TestGroup.auth, .bearer)
    }

    func testGroupWithCommonHeaders() {
        XCTAssertEqual(APIKeyGroup.commonHeaders["anthropic-version"], "2023-06-01")
    }

    func testDefaultDecodeError() {
        let data = "{}".data(using: .utf8)!
        XCTAssertNil(TestGroup.decodeError(statusCode: 400, data: data, headers: [:], decoder: JSONDecoder()))
    }
}

// MARK: - EndpointDescriptor Tests

final class EndpointDescriptorTests: XCTestCase {

    func testFullPathWithLeadingSlash() {
        let descriptor = EndpointDescriptor(name: "getUser", method: .get, subPath: "/users/:id")
        XCTAssertEqual(descriptor.fullPath, "/users/:id")
    }

    func testFullPathWithoutLeadingSlash() {
        let descriptor = EndpointDescriptor(name: "getUser", method: .get, subPath: "users/:id")
        XCTAssertEqual(descriptor.fullPath, "/users/:id")
    }

    func testFullPathEmpty() {
        let descriptor = EndpointDescriptor(name: "root", method: .get, subPath: "")
        XCTAssertEqual(descriptor.fullPath, "")
    }
}
