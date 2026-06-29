# APIContract

English | [日本語](./README.ja.md)

A type-safe API contract definition library powered by Swift macros. Share API definitions between client and server with compile-time type checking.

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- **Type-Safe API Definitions**: Compile-time validation of endpoint input/output types
- **Swift Macros**: Declarative API definitions with `@Endpoint` and `@APIGroup` macros
- **Auto Code Generation**: Automatic encoding for path parameters, query parameters, and body
- **Grouping**: Logically group related endpoints
- **Async/Await Support**: Modern concurrency integration

## Quick Start

```swift
import APIContract

// Define an API group
@APIGroup(path: "/v1/users", auth: .bearer)
enum UsersAPI {
    // GET endpoint (list)
    @Endpoint(.get)
    struct List {
        @QueryParam var limit: Int?
        @QueryParam var offset: Int?

        typealias Output = [User]
    }

    // GET endpoint (single item)
    @Endpoint(.get, path: ":userId")
    struct Get {
        @PathParam var userId: String

        typealias Output = User
    }

    // POST endpoint (create)
    @Endpoint(.post)
    struct Create {
        @Body var body: CreateUserRequest

        typealias Output = User
    }
}
```

### Execute Requests

```swift
// Use a client implementing APIExecutable protocol
let client: any APIExecutable = MyAPIClient(baseURL: URL(string: "https://api.example.com")!)

// Create an endpoint
let endpoint = UsersAPI.Get(userId: "123")

// Execute (type-safe response)
let user: User = try await endpoint.execute(using: client)
```

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-api-contract.git", from: "2.1.2")
]
```

Add to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "APIContract", package: "swift-api-contract")
    ]
)
```

## Macros

### @APIGroup

Groups related endpoints together.

```swift
@APIGroup(path: "/v1/users", auth: .bearer)
enum UsersAPI {
    // Endpoint definitions...
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | `String` | Base path for the group |
| `auth` | `AuthScheme` | Auth scheme (`.none` / `.bearer` / `.apiKey(headerName:)` / `.queryParam(name:)`) |
| `headers` | `[String: String]` | Common headers applied to all endpoints in the group |
| `scopes` | `[String]` | Default OAuth scopes for the group |

### @Endpoint

Defines an endpoint.

```swift
@Endpoint(.get, path: ":id")
struct GetUser {
    @PathParam var id: String
    typealias Output = User
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `method` | `APIMethod` | HTTP method |
| `path` | `String` | Sub-path (default: `""`) |
| `scopes` | `[String]` | OAuth scopes for this endpoint (inherits group default when empty) |

### @PathParam

Marks a path parameter.

```swift
@PathParam var userId: String
```

### @QueryParam

Marks a query parameter. Custom parameter names are supported.

```swift
@QueryParam var limit: Int?
@QueryParam(name: "page_size") var pageSize: Int?
```

### @Body

Marks the request body.

```swift
@Body var body: CreateUserRequest
```

### @Header

Marks a dynamic HTTP header added per request.

```swift
@Header("anthropic-beta") var beta: String?
```

### @StreamingEndpoint

Defines a streaming endpoint. Uses `Event` type instead of `Output`.

```swift
@StreamingEndpoint(.post, path: "messages")
struct StreamMessages {
    @Body var request: MessageRequest
    typealias Event = MessageDelta
}
```

### @APIServices

Groups multiple API services for bulk registration.

```swift
@APIServices
struct AppServices {
    let users: UsersService
    let posts: PostsService
}

// Generated method:
// func registerAll<R: Routes>(_ routes: R) { ... }

// Usage:
services.registerAll(server.routes)
```

## HTTP Methods

| Method | Usage |
|--------|-------|
| `.get` | Retrieve resources |
| `.post` | Create resources |
| `.put` | Full resource update |
| `.patch` | Partial resource update |
| `.delete` | Delete resources |
| `.head` | Retrieve headers only |
| `.options` | Check allowed methods |

## Type Support

### Parameter Types

- `String`
- `Int`, `Int8`, `Int16`, `Int32`, `Int64`
- `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
- `Double`, `Float`
- `Bool`
- `Date` (auto-converted to ISO8601 format)
- `RawRepresentable` types (enums, etc.)
- Optional versions of all above

### Special Types

| Type | Description |
|------|-------------|
| `EmptyInput` | For endpoints without parameters |
| `EmptyOutput` | For endpoints without response body |

## Implementing APIExecutable (Client)

Only `executeWithResponse` needs to be implemented; `execute` overloads are provided as default extensions.

```swift
struct MyAPIClient: APIExecutable {
    let baseURL: URL
    let session: URLSession

    func executeWithResponse<E: APIContract>(_ contract: E) async throws -> APIResponse<E.Output>
        where E.Input == E, E: APIInput
    {
        let request = try contract.buildRequest(baseURL: baseURL)
        let (data, response) = try await session.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        let headers = httpResponse.allHeaderFields
            .compactMapValues { $0 as? String }
            .reduce(into: [String: String]()) { $0[$1.key as! String] = $1.value }
        let output = try JSONDecoder().decode(E.Output.self, from: data)
        return APIResponse(output: output, statusCode: httpResponse.statusCode, headers: headers)
    }
}
```

## Implementing APIService (Server)

The `@APIGroup` macro auto-generates a corresponding Service protocol.

```swift
// @APIGroup(path: "/v1/users", auth: .bearer)
// enum UsersAPI { ... }
// ↓ Auto-generated
// protocol UsersAPIService: APIService where Group == UsersAPI { ... }

struct UsersService: UsersAPIService {
    func handle(_ input: UsersAPI.List, context: ServiceContext) async throws -> [User] {
        // Implementation
    }

    func handle(_ input: UsersAPI.Get, context: ServiceContext) async throws -> User {
        // Implementation
    }

    func handle(_ input: UsersAPI.Create, context: ServiceContext) async throws -> User {
        // Implementation
    }
}
```

## Dependencies

| Package | Purpose | Required |
|---------|---------|----------|
| [swift-syntax](https://github.com/swiftlang/swift-syntax) | Macro implementation | ✅ |

## Documentation

Detailed API documentation is available at [GitHub Pages](https://no-problem-dev.github.io/swift-api-contract/documentation/apicontract/).

## License

MIT License - See [LICENSE](LICENSE) for details.
