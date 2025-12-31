# はじめに

APIContractを使用してAPIエンドポイントを定義する方法を学びます。

@Metadata {
    @PageColor(blue)
}

## Overview

このガイドでは、APIContractを使用してAPIエンドポイントを定義し、実行する基本的な方法を説明します。

## インストール

Swift Package Managerを使用してインストールします。

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-api-contract.git", from: "1.0.0")
]
```

ターゲットに追加：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "APIContract", package: "swift-api-contract")
    ]
)
```

## 基本的なエンドポイント定義

### シンプルなGETエンドポイント

最もシンプルなエンドポイントは、パラメータなしのGETリクエストです。

```swift
import APIContract

@Endpoint(.get)
struct ListUsers {
    typealias Output = [User]
}
```

### パスパラメータを持つエンドポイント

パスパラメータは`@PathParam`でマークします。

```swift
@Endpoint(.get, path: ":userId")
struct GetUser {
    @PathParam var userId: String
    typealias Output = User
}
```

### クエリパラメータを持つエンドポイント

クエリパラメータは`@QueryParam`でマークします。

```swift
@Endpoint(.get)
struct SearchUsers {
    @QueryParam var query: String
    @QueryParam var limit: Int?
    @QueryParam("page_size") var pageSize: Int?  // カスタム名

    typealias Output = [User]
}
```

### リクエストボディを持つエンドポイント

リクエストボディは`@Body`でマークします。

```swift
@Endpoint(.post)
struct CreateUser {
    @Body var body: CreateUserRequest
    typealias Output = User
}
```

## APIグループの定義

関連するエンドポイントは`@APIGroup`でグループ化できます。

```swift
@APIGroup(path: "/v1/users", auth: .required)
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

## エンドポイントの実行

### APIExecutorの実装

まず、`APIExecutor`プロトコルを実装したクライアントを作成します。

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

### リクエストの実行

```swift
let client = MyAPIClient(
    baseURL: "https://api.example.com",
    session: .shared
)

// ユーザー一覧を取得
let users = try await UsersAPI.List(limit: 10).execute(using: client)

// 特定のユーザーを取得
let user = try await UsersAPI.Get(userId: "123").execute(using: client)

// 新しいユーザーを作成
let newUser = try await UsersAPI.Create(
    body: CreateUserRequest(name: "John", email: "john@example.com")
).execute(using: client)
```

## 次のステップ

- <doc:DefiningEndpoints> - より詳細なエンドポイント定義の方法
