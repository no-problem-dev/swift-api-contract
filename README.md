# APIContract

English | [日本語](./README.ja.md)

Define an HTTP API once in Swift, and let the client and the server share it — endpoints, parameters and errors are checked by the compiler on both sides.

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Overview

An endpoint is a struct. Its properties are the request, its `Output` is the response, and macros
generate everything in between: URL building, query encoding, body encoding, and the server-side
decoding that turns a raw request back into the same struct.

- `@APIGroup` / `@Endpoint` describe the API declaratively
- `@PathParam`, `@QueryParam`, `@Body`, `@Header` place each value in the request
- `@StreamingEndpoint` covers Server-Sent Events
- No transport is bundled: you supply the client, so URLSession or anything else works

## Usage

```swift
import APIContract

@APIGroup(path: "/v1/users", auth: .bearer)
enum UsersAPI {
    @Endpoint(.get, path: ":userId")
    struct Get {
        @PathParam var userId: String
        typealias Output = User
    }
}

let user = try await UsersAPI.Get(userId: "123").execute(using: client)
```

## Documentation

[API reference and guides](https://no-problem-dev.github.io/swift-api-contract/documentation/apicontract/) —
defining endpoints, implementing a client, and serving the same definitions.

## Requirements

Swift 6.0+ · iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+ · Linux

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-api-contract.git", from: "2.1.2")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "APIContract", package: "swift-api-contract")
    ]
)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License — see [LICENSE](LICENSE).
