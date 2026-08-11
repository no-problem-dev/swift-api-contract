# ``APIContract``

Define an HTTP API once in Swift and share it between the client and the server.

@Metadata {
    @PageColor(blue)
}

## Overview

An endpoint is a struct. Its properties are the request, its `Output` is the response, and the
macros generate what sits between them — URL building, query and body encoding, and the
server-side decoding that turns a raw request back into the same struct.

Because both ends compile against the same declaration, a change to a path, a parameter or a
response type is a compile error on whichever side has not caught up, instead of a bug found at
runtime.

Three things are deliberately left out:

- **No transport.** Conform to ``APIExecutable`` with whatever client you already have.
- **No server framework.** Conform to ``APIRouteRegistrar`` to mount the generated routes.
- **No fixed JSON coder.** Endpoints depend on ``APIBodyEncoder`` and ``APIBodyDecoder``, so the
  client picks the implementation.

Once a group is defined, the same declaration drives both sides:

```swift
// Client: build and send a request.
let user = try await UsersAPI.Get(userId: "123").execute(using: client)

// Server: implement the protocol the group generated, then register every route at once.
struct UsersService: UsersAPIService {
    func handle(_ input: UsersAPI.Get, context: ServiceContext) async throws -> User {
        try await store.user(id: input.userId, requestedBy: context.requireUserId())
    }
}

UsersAPI.registerAll(registrar)
```

<doc:GettingStarted> walks through defining a group, implementing a client and serving it.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:DefiningEndpoints>

### Defining an API

- ``APIGroup(path:auth:headers:scopes:)``
- ``Endpoint(_:path:scopes:)``
- ``StreamingEndpoint(_:path:scopes:)``

### Placing values in a request

- ``PathParam()``
- ``QueryParam(name:)``
- ``Body()``
- ``Header(_:)``

### Endpoint protocols

- ``APIContract``
- ``StreamingAPIContract``
- ``APIInput``
- ``APIContractGroup``
- ``EndpointDescriptor``
- ``NoGroup``

### Calling an API

- ``APIExecutable``
- ``StreamingAPIExecutable``
- ``APIResponse``

### Serving an API

- ``APIServices()``
- ``APIService``
- ``APIRouteRegistrar``
- ``StreamingRouteRegistrar``
- ``ServiceContext``
- ``AnyEndpointDispatcher``
- ``AuthenticationProvider``

### Encoding

- ``APIBodyEncoder``
- ``APIBodyDecoder``

### Requests and responses

- ``APIMethod``
- ``AuthScheme``
- ``EmptyInput``
- ``EmptyOutput``

### Errors

- ``APIContractError``
- ``ErrorResponse``
- ``HTTPError``
- ``AuthenticationError``
- ``ContractBuildError``
- ``NoContractError``
