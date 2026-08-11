# Getting Started

Define a group of endpoints, call them from a client, and serve them from the same declaration.

@Metadata {
    @PageColor(blue)
}

## Overview

This walks through one API end to end. The point to keep in view is that the group below is the
only place the endpoints are described — the client code and the server code that follow both read
from it, and neither can drift from it without failing to compile.

## Defining a group

Related endpoints live inside an enum marked with `@APIGroup`. The group carries what they share:
a base path, an auth scheme, and any headers or scopes that apply to all of them.

```swift
import APIContract

@APIGroup(path: "/v1/users", auth: .bearer)
enum UsersAPI {
    @Endpoint(.get)
    struct List {
        @QueryParam var limit: Int?
        typealias Output = [User]
    }

    @Endpoint(.get, path: ":userId")
    struct Get {
        @PathParam var userId: String
        typealias Output = User
    }

    @Endpoint(.post)
    struct Create {
        @Body var body: CreateUserRequest
        typealias Output = User
    }

    @Endpoint(.delete, path: ":userId")
    struct Delete {
        @PathParam var userId: String
        typealias Output = EmptyOutput
    }
}
```

Each nested struct is a whole endpoint: the attributes decide where a value travels, and `Output`
names what comes back. `Delete` returns `EmptyOutput` because the response has no body — that also
selects the `execute` overload that returns nothing.

For the attribute-by-attribute detail, and the parameter types that can be converted, see
<doc:DefiningEndpoints>.

## Implementing a client

No transport ships with this package, so the first step is one conformance to ``APIExecutable``.
Only `executeWithResponse(_:)` needs writing; the `execute(_:)` overloads come from an extension.

```swift
struct MyAPIClient: APIExecutable {
    let baseURL: URL
    let session: URLSession

    func executeWithResponse<E: APIContract>(_ contract: E) async throws -> APIResponse<E.Output>
    where E.Input == E, E: APIInput
    {
        let request = try contract.buildRequest(baseURL: baseURL)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) { result, pair in
            if let key = pair.key as? String, let value = pair.value as? String {
                result[key] = value
            }
        }
        let output = try JSONDecoder().decode(E.Output.self, from: data)
        return APIResponse(output: output, statusCode: httpResponse.statusCode, headers: headers)
    }
}
```

`buildRequest(baseURL:)` does the assembly — path substitution, query items, body encoding, group
and endpoint headers. What is left to the client is the part that is genuinely yours: retries,
authentication, and how a non-2xx response becomes an error.

## Making calls

An endpoint value is both the description of the call and its arguments, so there is nothing to
wire up at the call site.

```swift
let client = MyAPIClient(baseURL: URL(string: "https://api.example.com")!, session: .shared)

let users = try await UsersAPI.List(limit: 10).execute(using: client)
let user = try await UsersAPI.Get(userId: "123").execute(using: client)

let created = try await UsersAPI.Create(
    body: CreateUserRequest(name: "Ada", email: "ada@example.com")
).execute(using: client)

try await UsersAPI.Delete(userId: "123").execute(using: client)
```

When the status code or the response headers matter — a rate-limit budget, a pagination cursor —
call `executeWithResponse(_:)` instead and read them off ``APIResponse``.

## Serving the same definition

`@APIGroup` also emits a protocol named after the group, with one `handle(_:context:)` requirement
per endpoint. Implementing it is how a server proves it covers the whole group: leaving an
endpoint out is a compile error.

```swift
struct UsersService: UsersAPIService {
    func handle(_ input: UsersAPI.List, context: ServiceContext) async throws -> [User] { … }
    func handle(_ input: UsersAPI.Get, context: ServiceContext) async throws -> User { … }
    func handle(_ input: UsersAPI.Create, context: ServiceContext) async throws -> User { … }
    func handle(_ input: UsersAPI.Delete, context: ServiceContext) async throws { … }
}
```

The inputs arrive already decoded, because the same macro that generated the client's encoding
generated the matching decoding. Registering the routes is one call per group, against your
``APIRouteRegistrar`` conformance:

```swift
UsersAPI.registerAll(registrar)
```

Streaming endpoints are not included in that call — register those through
``StreamingRouteRegistrar``.

## Next steps

- <doc:DefiningEndpoints> — every attribute, the supported parameter types, and streaming
