# Changelog

All notable changes to this project are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.1.3] - 2026-07-19

### Changed

- README is now English primary with a `README.ja.md` translation; `README_EN.md` removed.
- Expanded doc comments on the macros and the public types, and corrected README claims that had
  drifted from the actual API.
- CI builds documentation on macOS with Swift 6.2 and deploys it through GitHub Pages.

### Added

- Expansion tests for `@StreamingEndpoint` and `@APIServices`, including misuse diagnostics.

## [2.1.2] - 2026-06-14

### Fixed

- An endpoint that resolves to an empty path no longer gets a trailing slash appended to the base
  URL, which some servers answered with a 404.

## [2.1.1] - 2026-06-13

Re-tag of 2.1.0. No source changes.

## [2.1.0] - 2026-06-13

### Added

- `requiredScopes` on endpoints and groups: `@Endpoint(scopes:)` and `@APIGroup(scopes:)` declare
  the OAuth scopes a call needs, and an endpoint without its own inherits the group's.
- The same `requiredScopes` on `StreamingAPIContract`.

## [2.0.1] - 2026-06-08

### Changed

- Widened the accepted swift-syntax range from `from: 602.0.0` to `600.0.0..<604.0.0` so
  dependency graphs pinning older swift-syntax resolve. The macros are verified against both
  600.0.1 and 603.0.1.

## [2.0.0] - 2026-05-31

### Changed

- **Breaking.** `encodeBody(using:)`, `decode(...)` and `decodeError(...)` now take
  `APIBodyEncoder` / `APIBodyDecoder` instead of Foundation's concrete `JSONEncoder` /
  `JSONDecoder`, so a client can inject its own coder while API definitions stay on `Codable`.
  Foundation's coders conform to the new protocols, so the default path is unchanged.
  Hand-written contract implementations must swap the parameter types.

## [1.2.0] - 2026-04-18

### Added

- **`{key}` placeholder syntax**: `resolvePath` substitutes `{key}` as well as `:key`
  - Matches what Go's chi router and OpenAPI specs use
  - Existing `:key` definitions keep working
  - `@Endpoint(.patch, path: "/social-challenges/{id}/status")` now expands `id` correctly

## [1.0.7] - 2026-01-11

### Added

- **`@StreamingEndpoint` macro**: support for defining SSE streaming APIs
  - `StreamingAPIContract`: streaming responses, with an `Event` associated type
  - `StreamingAPIExecutable`: client-side stream execution
  - `StreamingRouteRegistrar`: server-side route registration
  - `@StreamingEndpoint`: the streaming counterpart of `@Endpoint`

  ```swift
  @StreamingEndpoint(.post, path: "stream")
  public struct StartStream {
      @Body public var request: SearchRequest
      public typealias Event = SearchEvent  // event type streamed to the client
  }
  ```

## [1.0.6] - 2026-01-03

### Fixed

- **`resolvePath` promoted to a protocol requirement**: custom implementations are now reached
  through a generic constraint (`E: APIContract`), not only on concrete types. The default
  implementation stays, so existing code is unaffected.

### Added

- **APIContract tests**: 22 new tests
  - `pathTemplate`
  - default `resolvePath`
  - custom `resolvePath`, called directly and generically
  - `buildRequest`
  - `APIMethod`, `AuthRequirement`, `EmptyOutput`, `EmptyInput`
  - `APIInput`, `APIContractGroup`, `EndpointDescriptor`

## [1.0.5] - 2026-01-03

### Changed

- **`APIExecutor` renamed to `APIExecutable`**, for consistency with the ~able naming convention.
- **Code cleanup**: removed redundant MARK comments and verbose documentation, keeping concise
  doc comments on the public protocols.

### Fixed

- **Tests**: updated expectations to match the macro output.

## [1.0.4] - 2026-01-02

### Changed

- **Swift 6.2 support**
  - `swift-tools-version`: 6.0 → 6.2
  - `swift-syntax`: 600.0.0 → 602.0.0
  - dependency requirements unified on `.upToNextMajor`

### Added

- **CI test workflow**: tests on Linux x86_64 (swift:6.2-bookworm)

## [1.0.3] - 2026-01-01

### Added

- **`@APIServices` macro**
  - registers multiple API services in one call
  - generates `registerAll<R: Routes>(_ routes: R)`

- **`APIRouteRegistrar` protocol**
  - type-safe abstraction for route registration

### Changed

- **Handler renamed to Service**
  - `APIGroupHandler` → `APIService`
  - `APIRouteRegistrar.Handler` → `APIRouteRegistrar.Service`
  - the protocol `@APIGroup` generates: `XxxHandler` → `XxxService`

## [1.0.2] - 2026-01-01

### Added

- **Server-side handler protocols**
  - `APIGroupHandler`: type-safe API handler protocol
  - `AuthenticationProvider`: authentication abstraction
  - `HandlerContext`: authenticated user context

- **Error handling**
  - `APIContractError`: standard error type (unauthorized, forbidden, notFound, badRequest, conflict, internalError)

### Changed

- `HTTPMethod` renamed to `APIMethod`
- `@Endpoint` gained an `authRequirement` parameter
- added the `AuthRequirement` enum (none, required)

## [1.0.1] - 2025-12-31

### Fixed

- **Linux support**
  - `EndpointMacro.swift`: import `Foundation` for `String.replacingOccurrences`
  - `APIContract.swift`: conditionally import `FoundationNetworking` for `URLRequest`

## [1.0.0] - 2025-12-31

### Added

- **Core protocols**
  - `APIContract`: the endpoint definition protocol
  - `APIInput`: type-safe request parameters (path, query, body)
  - `APIContractGroup`: grouping of related endpoints
  - `APIExecutor`: abstraction for executing a call

- **Macros**
  - `@Endpoint`: generates the endpoint struct's members
  - `@APIGroup`: generates the API group enum's members
  - `@PathParam`, `@QueryParam` (with custom names), `@Body`: parameter markers

- **Type utilities**
  - `EmptyInput`: endpoints without parameters
  - `EmptyOutput`: endpoints without a response body
  - `APIMethod`: GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
  - `AuthRequirement`: none, required

- **Generated code**: `pathParameters`, `queryParameters`, `encodeBody()`, `init()`, and
  URLRequest construction

- **CI/CD**: test workflow per PR, automatic release on release-branch merge, DocC deployment to
  GitHub Pages

- **Documentation**: README (Japanese and English), DocC articles (GettingStarted,
  DefiningEndpoints), CHANGELOG

- **Tests**: macro expansion tests (EndpointMacroTests)

[Unreleased]: https://github.com/no-problem-dev/swift-api-contract/compare/2.1.3...HEAD
[2.1.3]: https://github.com/no-problem-dev/swift-api-contract/compare/v2.1.2...2.1.3
[2.1.2]: https://github.com/no-problem-dev/swift-api-contract/compare/v2.1.1...v2.1.2
[2.1.1]: https://github.com/no-problem-dev/swift-api-contract/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/no-problem-dev/swift-api-contract/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/no-problem-dev/swift-api-contract/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.7...v1.2.0
[1.0.7]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/no-problem-dev/swift-api-contract/releases/tag/v1.0.0
