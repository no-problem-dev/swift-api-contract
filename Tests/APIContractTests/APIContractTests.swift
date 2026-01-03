import XCTest
import Foundation
@testable import APIContract

// MARK: - Test Groups

enum TestGroup: APIContractGroup {
    static let basePath: String = "/v1"
    static let auth: AuthRequirement = .required
    static let endpoints: [EndpointDescriptor] = []
}

enum EmptyGroup: APIContractGroup {
    static let basePath: String = ""
    static let auth: AuthRequirement = .none
    static let endpoints: [EndpointDescriptor] = []
}

// MARK: - Test Contracts

/// 標準的なエンドポイント（デフォルトのresolvePath使用）
struct GetUsersContract: APIContract, APIInput {
    typealias Group = TestGroup
    typealias Input = Self
    typealias Output = EmptyOutput

    static let method: APIMethod = .get
    static let subPath: String = "/users"

    var pathParameters: [String: String] { [:] }
    var queryParameters: [String: String]? { nil }

    func encodeBody(using encoder: JSONEncoder) throws -> Data? { nil }

    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: JSONDecoder
    ) throws -> Self {
        Self()
    }
}

/// パスパラメータ付きエンドポイント
struct GetUserContract: APIContract, APIInput {
    typealias Group = TestGroup
    typealias Input = Self
    typealias Output = EmptyOutput

    static let method: APIMethod = .get
    static let subPath: String = "/users/:id"

    let userId: String

    var pathParameters: [String: String] { ["id": userId] }
    var queryParameters: [String: String]? { nil }

    func encodeBody(using encoder: JSONEncoder) throws -> Data? { nil }

    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: JSONDecoder
    ) throws -> Self {
        Self(userId: pathParameters["id"] ?? "")
    }
}

/// カスタムresolvePath実装を持つエンドポイント
struct CustomPathContract: APIContract, APIInput {
    typealias Group = NoGroup
    typealias Input = Self
    typealias Output = EmptyOutput

    static let method: APIMethod = .get
    static let subPath: String = ""

    let customPath: String

    var pathParameters: [String: String] { [:] }
    var queryParameters: [String: String]? { nil }

    func encodeBody(using encoder: JSONEncoder) throws -> Data? { nil }

    /// カスタムパス解決（プロトコル要件をオーバーライド）
    static func resolvePath(with input: Self) -> String {
        input.customPath
    }

    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: JSONDecoder
    ) throws -> Self {
        fatalError("Client-only contract")
    }
}

/// グループなしでsubPath付きエンドポイント
struct NoGroupContract: APIContract, APIInput {
    typealias Group = NoGroup
    typealias Input = Self
    typealias Output = EmptyOutput

    static let method: APIMethod = .post
    static let subPath: String = "/api/data"

    var pathParameters: [String: String] { [:] }
    var queryParameters: [String: String]? { nil }

    func encodeBody(using encoder: JSONEncoder) throws -> Data? { nil }

    static func decode(
        pathParameters: [String: String],
        queryParameters: [String: String],
        body: Data?,
        decoder: JSONDecoder
    ) throws -> Self {
        Self()
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
        // テスト用にインラインで定義
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

            func encodeBody(using encoder: JSONEncoder) throws -> Data? { nil }

            static func decode(
                pathParameters: [String: String],
                queryParameters: [String: String],
                body: Data?,
                decoder: JSONDecoder
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

    // MARK: - Custom resolvePath Tests

    func testCustomResolvePathDirectCall() {
        let contract = CustomPathContract(customPath: "/custom/endpoint")
        let path = CustomPathContract.resolvePath(with: contract)
        XCTAssertEqual(path, "/custom/endpoint")
    }

    func testCustomResolvePathGenericCall() {
        // ジェネリック経由でもカスタム実装が呼ばれることを確認
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

            func encodeBody(using encoder: JSONEncoder) throws -> Data? { nil }

            static func decode(
                pathParameters: [String: String],
                queryParameters: [String: String],
                body: Data?,
                decoder: JSONDecoder
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

    // MARK: - APIMethod Tests

    func testAPIMethodRawValues() {
        XCTAssertEqual(APIMethod.get.rawValue, "GET")
        XCTAssertEqual(APIMethod.post.rawValue, "POST")
        XCTAssertEqual(APIMethod.put.rawValue, "PUT")
        XCTAssertEqual(APIMethod.patch.rawValue, "PATCH")
        XCTAssertEqual(APIMethod.delete.rawValue, "DELETE")
    }

    // MARK: - AuthRequirement Tests

    func testAuthRequirementFromGroup() {
        XCTAssertEqual(GetUsersContract.auth, .required)
        XCTAssertEqual(NoGroupContract.auth, .required) // NoGroup defaults to required
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

            func encodeBody(using encoder: JSONEncoder) throws -> Data? { nil }

            static func decode(
                pathParameters: [String: String],
                queryParameters: [String: String],
                body: Data?,
                decoder: JSONDecoder
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
        XCTAssertEqual(NoGroup.auth, .required)
        XCTAssertTrue(NoGroup.endpoints.isEmpty)
    }

    func testCustomGroup() {
        XCTAssertEqual(TestGroup.basePath, "/v1")
        XCTAssertEqual(TestGroup.auth, .required)
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
