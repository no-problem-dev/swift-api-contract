# エンドポイントの定義

APIContractでエンドポイントを定義する詳細なガイド。

@Metadata {
    @PageColor(blue)
}

## Overview

このガイドでは、APIContractの各マクロの詳細な使い方と、様々なパターンのエンドポイント定義を説明します。

## @Endpointマクロ

`@Endpoint`マクロは、構造体をAPIエンドポイントに変換します。

### 基本構文

```swift
@Endpoint(.httpMethod, path: "optional/sub/path")
struct EndpointName {
    // パラメータ定義
    typealias Output = ResponseType
}
```

### HTTPメソッド

サポートされるHTTPメソッド：

| メソッド | 用途 |
|---------|------|
| `.get` | リソースの取得 |
| `.post` | リソースの作成 |
| `.put` | リソースの完全更新 |
| `.patch` | リソースの部分更新 |
| `.delete` | リソースの削除 |
| `.head` | ヘッダーのみ取得 |
| `.options` | 許可メソッドの確認 |

### パス指定

パスは省略可能です。省略した場合、グループのベースパスが使用されます。

```swift
// パスなし → グループのベースパスのみ
@Endpoint(.get)
struct List { ... }

// パスあり → グループのベースパス + サブパス
@Endpoint(.get, path: ":id")
struct Get { ... }

// 複雑なパス
@Endpoint(.get, path: ":userId/posts/:postId/comments")
struct GetComments { ... }
```

## パラメータマクロ

### @PathParam

URLパス内のプレースホルダーに対応するパラメータを定義します。

```swift
@Endpoint(.get, path: ":userId/posts/:postId")
struct GetPost {
    @PathParam var userId: String
    @PathParam var postId: String

    typealias Output = Post
}

// 生成されるパス: /users/123/posts/456
let endpoint = GetPost(userId: "123", postId: "456")
```

### @QueryParam

URLクエリパラメータを定義します。

```swift
@Endpoint(.get)
struct SearchUsers {
    @QueryParam var query: String          // 必須
    @QueryParam var limit: Int?            // オプション
    @QueryParam("page_size") var pageSize: Int?  // カスタム名

    typealias Output = [User]
}

// 生成されるURL: /users?query=john&limit=10&page_size=20
let endpoint = SearchUsers(query: "john", limit: 10, pageSize: 20)
```

### @Body

リクエストボディを定義します。`Encodable`に準拠した型を使用します。

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

// リクエストボディがJSON形式でエンコードされる
let endpoint = CreateUser(body: CreateUserRequest(name: "John", email: "john@example.com"))
```

## 型サポート

### パラメータで使用可能な型

以下の型がパスパラメータとクエリパラメータで使用できます：

- **文字列**: `String`
- **整数**: `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
- **浮動小数点**: `Double`, `Float`
- **真偽値**: `Bool`
- **日付**: `Date`（ISO8601形式で自動変換）
- **Enum**: `RawRepresentable`な型

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

### 特殊な型

#### EmptyInput

パラメータなしのエンドポイントに使用します。

```swift
@Endpoint(.get)
struct GetServerStatus {
    typealias Output = ServerStatus
}
```

#### EmptyOutput

レスポンスボディがないエンドポイント（DELETEなど）に使用します。

```swift
@Endpoint(.delete, path: ":id")
struct DeleteUser {
    @PathParam var id: String
    typealias Output = EmptyOutput
}
```

## @APIGroupマクロ

関連するエンドポイントをグループ化し、共通のベースパスと認証設定を定義します。

### 基本構文

```swift
@APIGroup(path: "/v1/resource", auth: .required)
enum ResourceAPI {
    // エンドポイント定義
}
```

### 認証要件

| 値 | 説明 |
|----|------|
| `.none` | 認証不要 |
| `.required` | 認証必要 |

### グループ化の例

```swift
// ユーザーAPI
@APIGroup(path: "/v1/users", auth: .required)
enum UsersAPI {
    @Endpoint(.get) struct List { ... }
    @Endpoint(.get, path: ":id") struct Get { ... }
    @Endpoint(.post) struct Create { ... }
    @Endpoint(.put, path: ":id") struct Update { ... }
    @Endpoint(.delete, path: ":id") struct Delete { ... }
}

// 認証API（認証不要）
@APIGroup(path: "/v1/auth", auth: .none)
enum AuthAPI {
    @Endpoint(.post, path: "login") struct Login { ... }
    @Endpoint(.post, path: "register") struct Register { ... }
    @Endpoint(.post, path: "refresh") struct Refresh { ... }
}
```

## 完全な例

```swift
import APIContract

// モデル定義
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

// API定義
@APIGroup(path: "/v1/users", auth: .required)
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
