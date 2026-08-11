# Defining Endpoints

Every attribute, what it generates, and where each one stops working.

@Metadata {
    @PageColor(blue)
}

## Overview

An endpoint declaration is read at compile time, so what you write in the attributes is what the
macro can see. That is worth holding onto while reading this page: several of the limits below
follow from it, and none of them are diagnosed.

## The @Endpoint macro

`@Endpoint` turns a struct into one endpoint.

```swift
@Endpoint(.httpMethod, path: "optional/sub/path")
struct EndpointName {
    // parameter properties
    typealias Output = ResponseType
}
```

The struct becomes both the request description and the request value: calling
`GetUser(userId: "123")` produces something that knows its own method, path, query and body.

### HTTP methods

| Method | Use |
|---------|------|
| `.get` | Retrieve a resource |
| `.post` | Create a resource |
| `.put` | Replace a resource |
| `.patch` | Update part of a resource |
| `.delete` | Delete a resource |
| `.head` | Retrieve headers only |
| `.options` | Ask which methods are allowed |

### Paths

`path` is optional. Left out, the endpoint sits at the group's base path.

```swift
// No sub-path: the group's base path
@Endpoint(.get)
struct List { … }

// One placeholder
@Endpoint(.get, path: ":id")
struct Get { … }

// Several, at any depth
@Endpoint(.get, path: ":userId/posts/:postId/comments")
struct GetComments { … }
```

Placeholders can be written `:name` or `{name}`. Both resolve the same way, so a contract
transcribed from an OpenAPI spec or a chi router can keep the spelling it came with.

The name has to match the property name exactly. A mismatch is not an error: the placeholder
survives into the URL and the request goes out with `:userId` still in the path.

## Parameter attributes

### @PathParam

Fills a placeholder in the path.

```swift
@Endpoint(.get, path: ":userId/posts/:postId")
struct GetPost {
    @PathParam var userId: String
    @PathParam var postId: String

    typealias Output = Post
}

// Resolves to /123/posts/456
let endpoint = GetPost(userId: "123", postId: "456")
```

### @QueryParam

Sends the value as a URL query item. This is also what an unmarked property becomes, so writing
the attribute changes nothing except how the declaration reads.

```swift
@Endpoint(.get)
struct SearchUsers {
    @QueryParam var query: String                      // always sent
    @QueryParam var limit: Int?                        // dropped when nil
    @QueryParam(name: "page_size") var pageSize: Int?  // different key on the wire

    typealias Output = [User]
}

// ?query=john&limit=10&page_size=20
let endpoint = SearchUsers(query: "john", limit: 10, pageSize: 20)
```

Optionality is how an omitted filter is expressed: a `nil` optional is left out of the URL
entirely, rather than sent as an empty value.

### @Body

Sends the value as the request body. The type has to be `Encodable`; the encoder is whichever one
the client injects, and `Content-Type: application/json` is set whenever a body is present.

```swift
struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

@Endpoint(.post)
struct CreateUser {
    @Body var body: CreateUserRequest

    typealias Output = User
}
```

Only one body per endpoint is meaningful. A second `@Body` property is not diagnosed — it is
silently left out of the request.

### @Header

Sends the value as an HTTP header, for the headers that differ between calls to the same endpoint.
Constant ones belong on the group instead.

```swift
@Endpoint(.post)
struct CreateMessage {
    @Header("anthropic-beta") var beta: String?
    @Body var request: MessageRequest

    typealias Output = MessageResponse
}
```

Two things follow from a header being a header. It is applied after the group's common headers, so
it wins on a shared key. And it is left out of the server-side decoding, because on that side
headers come from the transport rather than from the reconstructed input.

## Parameter types

Path and query parameters are converted to strings by type:

- **Strings**: `String`
- **Integers**: `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
- **Floating point**: `Double`, `Float`
- **Booleans**: `Bool`
- **Dates**: `Date`, as ISO8601 including the time
- **Enums**: anything `RawRepresentable`, via `.rawValue`

```swift
enum Status: String {
    case active, inactive
}

@Endpoint(.get)
struct FilterUsers {
    @QueryParam var status: Status
    @QueryParam var createdAfter: Date?

    typealias Output = [User]
}
```

The enum case is the fallback, not a listed type: any type not named above is assumed to be
`RawRepresentable`. When it is not, the error surfaces as a compile failure inside the generated
code rather than as a diagnostic on your declaration.

Server-side decoding reverses this, but covers a narrower set: `Int`, `Int64`, `Int32`, `Double`,
`Float`, `Bool`, `Date` and `RawRepresentable`. The narrower integer widths — `Int16`, `Int8` and
the unsigned types — encode fine on the client, but fall into the `RawRepresentable` branch when
decoding, which does not compile. Use `Int` for a parameter an endpoint has to decode.

### EmptyInput and EmptyOutput

`EmptyInput` is the default input, so an endpoint with no parameters says nothing at all:

```swift
@Endpoint(.get)
struct GetServerStatus {
    typealias Output = ServerStatus
}
```

`EmptyOutput` is for a response with no body, such as a delete. It also selects the `execute`
overload that returns nothing, so the call site has no value to discard:

```swift
@Endpoint(.delete, path: ":id")
struct DeleteUser {
    @PathParam var id: String
    typealias Output = EmptyOutput
}
```

## The @APIGroup macro

`@APIGroup` collects related endpoints and holds what they share.

```swift
@APIGroup(path: "/v1/resource", auth: .bearer)
enum ResourceAPI {
    // endpoints
}
```

The enum is a namespace and is never instantiated. Membership is lexical: an endpoint belongs to
the group it is written inside. One declared outside any group falls back to ``NoGroup``, whose
base path is empty — which is the first thing to check when a request arrives at the wrong URL.

### Auth schemes

| Value | Meaning |
|----|------|
| `.none` | No credential |
| `.bearer` | `Authorization: Bearer <token>` |
| `.apiKey(headerName:)` | A dedicated header, such as `x-api-key` |
| `.queryParam(name:)` | In the URL, such as `?key=…` |

The default is `.bearer`, so a public group has to say `.none` explicitly. The scheme only
declares where a credential goes; obtaining and attaching it is the client's job.

### Common headers and scopes

```swift
@APIGroup(
    path: "/v1/messages",
    auth: .bearer,
    headers: ["anthropic-version": "2023-06-01"],
    scopes: ["messages:read"]
)
enum MessagesAPI {
    @Endpoint(.post, scopes: ["messages:write"])
    struct Create {
        @Body var body: CreateMessageRequest
        typealias Output = Message
    }
}
```

`headers` is applied to every request in the group. `scopes` is inherited by endpoints that do not
declare their own — `Create` above needs `messages:write` only, not both.

Both are read from the source text, so they have to be written as literals. A dictionary or array
built elsewhere is read as empty, without a diagnostic, and the endpoints end up with no common
headers or no scopes at all.

## Streaming endpoints

`@StreamingEndpoint` is the same declaration with a sequence of events in place of a single
response. Name the event type `Event` rather than `Output`.

```swift
@StreamingEndpoint(.post, path: "messages")
struct StreamMessages {
    @Body var request: MessageRequest
    typealias Event = MessageDelta
}

for try await delta in StreamMessages(request: request).stream(using: client) {
    print(delta)
}
```

Building the request adds the Server-Sent Events headers (`Accept: text/event-stream` and
`Cache-Control: no-cache`) before the group's, so a group pinning its own `Accept` wins.

Streaming endpoints are not collected by their group: they do not appear in `endpoints`, and
`registerAll(_:)` does not register them. Mount them individually through
``StreamingRouteRegistrar``.

## A complete group

```swift
import APIContract

struct User: Codable {
    let id: String
    let name: String
    let email: String
}

struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

struct UpdateUserRequest: Codable {
    let name: String?
    let email: String?
}

@APIGroup(path: "/v1/users", auth: .bearer)
enum UsersAPI {
    @Endpoint(.get)
    struct List {
        @QueryParam var limit: Int?
        @QueryParam var offset: Int?
        @QueryParam var status: String?

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

    @Endpoint(.patch, path: ":userId")
    struct Update {
        @PathParam var userId: String
        @Body var body: UpdateUserRequest

        typealias Output = User
    }

    @Endpoint(.delete, path: ":userId")
    struct Delete {
        @PathParam var userId: String

        typealias Output = EmptyOutput
    }
}
```
