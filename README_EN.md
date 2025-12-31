# APIContract

English | [日本語](README.md)

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
@APIGroup(path: "/v1/users", auth: .required)
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
// Use a client implementing APIExecutor protocol
let client: APIExecutor = MyAPIClient(baseURL: "https://api.example.com")

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
    .package(url: "https://github.com/no-problem-dev/swift-api-contract.git", from: "1.0.0")
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
@APIGroup(path: "/v1/users", auth: .required)
enum UsersAPI {
    // Endpoint definitions...
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | `String` | Base path for the group |
| `auth` | `AuthRequirement` | Authentication requirement (`.none` / `.required`) |

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
| `method` | `HTTPMethod` | HTTP method |
| `path` | `String?` | Sub-path (optional) |

### @PathParam

Marks a path parameter.

```swift
@PathParam var userId: String
```

### @QueryParam

Marks a query parameter. Custom parameter names are supported.

```swift
@QueryParam var limit: Int?
@QueryParam("page_size") var pageSize: Int?
```

### @Body

Marks the request body.

```swift
@Body var body: CreateUserRequest
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

## Implementing APIExecutor

```swift
struct MyAPIClient: APIExecutor {
    let baseURL: String
    let session: URLSession

    func execute<E: APIContract>(_ endpoint: E) async throws -> E.Output
    where E.Output: Decodable {
        let request = try endpoint.urlRequest(baseURL: baseURL)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(E.Output.self, from: data)
    }

    func execute<E: APIContract>(_ endpoint: E) async throws
    where E.Output == EmptyOutput {
        let request = try endpoint.urlRequest(baseURL: baseURL)
        _ = try await session.data(for: request)
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
