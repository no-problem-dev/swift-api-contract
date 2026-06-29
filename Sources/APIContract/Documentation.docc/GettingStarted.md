# はじめに

APIContractを使用してAPIエンドポイントを定義・実行する基本ガイド。

@Metadata {
    @PageColor(blue)
}

## Overview

APIContractを使用してAPIエンドポイントを定義し、実行する基本的な方法を解説する。

## インストール

Swift Package Managerで追加する。

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-api-contract.git", from: "2.1.2")
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

最もシンプルなエンドポイントは、パラメータなしのGETリクエスト。

```swift
import APIContract

@Endpoint(.get)
struct ListUsers {
    typealias Output = [User]
}
```

### パスパラメータを持つエンドポイント

パスパラメータは`@PathParam`でマークする。

```swift
@Endpoint(.get, path: ":userId")
struct GetUser {
    @PathParam var userId: String
    typealias Output = User
}
```

### クエリパラメータを持つエンドポイント

クエリパラメータは`@QueryParam`でマークする。

```swift
@Endpoint(.get)
struct SearchUsers {
    @QueryParam var query: String
    @QueryParam var limit: Int?
    @QueryParam(name: "page_size") var pageSize: Int?  // カスタム名

    typealias Output = [User]
}
```

### リクエストボディを持つエンドポイント

リクエストボディは`@Body`でマークする。

```swift
@Endpoint(.post)
struct CreateUser {
    @Body var body: CreateUserRequest
    typealias Output = User
}
```

## APIグループの定義

関連するエンドポイントは`@APIGroup`でグループ化できる。

```swift
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

## エンドポイントの実行

### APIExecutableの実装

`APIExecutable` プロトコルを実装したクライアントを作成する。
実装が必要なのは `executeWithResponse` のみ。`execute` の各オーバーロードはデフォルト実装が提供される。

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

### リクエストの実行

```swift
let client: any APIExecutable = MyAPIClient(
    baseURL: URL(string: "https://api.example.com")!,
    session: .shared
)

// ユーザー一覧を取得
let users = try await UsersAPI.List(limit: 10).execute(using: client)

// 特定のユーザーを取得
let user = try await UsersAPI.Get(userId: "123").execute(using: client)

// 新しいユーザーを作成
let newUser = try await UsersAPI.Create(
    body: CreateUserRequest(name: "田中", email: "tanaka@example.com")
).execute(using: client)
```

## 次のステップ

- <doc:DefiningEndpoints> - より詳細なエンドポイント定義の方法
