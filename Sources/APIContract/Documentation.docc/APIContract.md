# ``APIContract``

Swiftマクロを活用した型安全なAPIコントラクト定義ライブラリ。

@Metadata {
    @PageColor(blue)
}

## Overview

APIContractは、クライアントとサーバー間のAPI定義を共通化し、コンパイル時の型チェックを実現するライブラリです。
Swiftマクロによる宣言的なAPI定義と、自動コード生成による開発効率の向上を提供します。

### 特徴

- **型安全なAPI定義**: コンパイル時にエンドポイントの入出力型をチェック
- **Swiftマクロ**: `@Endpoint`、`@APIGroup`マクロによる宣言的なAPI定義
- **自動コード生成**: パスパラメータ、クエリパラメータ、ボディのエンコード処理を自動生成
- **グループ化**: 関連するエンドポイントを論理的にグループ化
- **Async/Await対応**: モダンな非同期処理との統合

### クイックスタート

```swift
import APIContract

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
}
```

### リクエストの実行

```swift
let client: APIExecutor = MyAPIClient(baseURL: "https://api.example.com")
let endpoint = UsersAPI.Get(userId: "123")
let user: User = try await endpoint.execute(using: client)
```

## Topics

### はじめに

- <doc:GettingStarted>
- <doc:DefiningEndpoints>

### プロトコル

- ``APIContract``
- ``APIInput``
- ``APIContractGroup``
- ``APIExecutor``

### マクロ

- ``Endpoint(_:path:)``
- ``APIGroup(path:auth:)``
- ``PathParam()``
- ``QueryParam(_:)``
- ``Body()``

### 型

- ``HTTPMethod``
- ``AuthRequirement``
- ``EmptyInput``
- ``EmptyOutput``
