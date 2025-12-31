# APIContract

[English](README_EN.md) | 日本語

Swiftマクロを活用した型安全なAPIコントラクト定義ライブラリ。クライアントとサーバー間のAPI定義を共通化し、コンパイル時の型チェックを実現します。

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 特徴

- **型安全なAPI定義**: コンパイル時にエンドポイントの入出力型をチェック
- **Swiftマクロ**: `@Endpoint`、`@APIGroup`マクロによる宣言的なAPI定義
- **自動コード生成**: パスパラメータ、クエリパラメータ、ボディのエンコード処理を自動生成
- **グループ化**: 関連するエンドポイントを論理的にグループ化
- **Async/Await対応**: モダンな非同期処理との統合

## クイックスタート

```swift
import APIContract

// APIグループの定義
@APIGroup(path: "/v1/users", auth: .required)
enum UsersAPI {
    // GETエンドポイント（一覧取得）
    @Endpoint(.get)
    struct List {
        @QueryParam var limit: Int?
        @QueryParam var offset: Int?

        typealias Output = [User]
    }

    // GETエンドポイント（単一取得）
    @Endpoint(.get, path: ":userId")
    struct Get {
        @PathParam var userId: String

        typealias Output = User
    }

    // POSTエンドポイント（作成）
    @Endpoint(.post)
    struct Create {
        @Body var body: CreateUserRequest

        typealias Output = User
    }
}
```

### リクエストの実行

```swift
// APIExecutorプロトコルを実装したクライアントを使用
let client: APIExecutor = MyAPIClient(baseURL: "https://api.example.com")

// エンドポイントを作成
let endpoint = UsersAPI.Get(userId: "123")

// 実行（型安全なレスポンス）
let user: User = try await endpoint.execute(using: client)
```

## インストール

### Swift Package Manager

`Package.swift` に以下を追加：

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

## マクロ一覧

### @APIGroup

関連するエンドポイントをグループ化します。

```swift
@APIGroup(path: "/v1/users", auth: .required)
enum UsersAPI {
    // エンドポイント定義...
}
```

| パラメータ | 型 | 説明 |
|-----------|-----|------|
| `path` | `String` | グループの基本パス |
| `auth` | `AuthRequirement` | 認証要件（`.none` / `.required`） |

### @Endpoint

エンドポイントを定義します。

```swift
@Endpoint(.get, path: ":id")
struct GetUser {
    @PathParam var id: String
    typealias Output = User
}
```

| パラメータ | 型 | 説明 |
|-----------|-----|------|
| `method` | `HTTPMethod` | HTTPメソッド |
| `path` | `String?` | サブパス（オプション） |

### @PathParam

パスパラメータをマークします。

```swift
@PathParam var userId: String
```

### @QueryParam

クエリパラメータをマークします。カスタムパラメータ名も指定可能。

```swift
@QueryParam var limit: Int?
@QueryParam("page_size") var pageSize: Int?
```

### @Body

リクエストボディをマークします。

```swift
@Body var body: CreateUserRequest
```

## HTTPメソッド

| メソッド | 用途 |
|---------|------|
| `.get` | リソースの取得 |
| `.post` | リソースの作成 |
| `.put` | リソースの完全更新 |
| `.patch` | リソースの部分更新 |
| `.delete` | リソースの削除 |
| `.head` | ヘッダーのみ取得 |
| `.options` | 許可メソッドの確認 |

## 型サポート

### パラメータで使用可能な型

- `String`
- `Int`, `Int8`, `Int16`, `Int32`, `Int64`
- `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
- `Double`, `Float`
- `Bool`
- `Date`（ISO8601形式で自動変換）
- `RawRepresentable`な型（enumなど）
- 上記のOptional型

### 特殊な型

| 型 | 説明 |
|----|------|
| `EmptyInput` | パラメータなしのエンドポイント用 |
| `EmptyOutput` | レスポンスボディなしのエンドポイント用 |

## APIExecutorの実装

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

## 依存関係

| パッケージ | 用途 | 必須 |
|-----------|------|------|
| [swift-syntax](https://github.com/swiftlang/swift-syntax) | マクロ実装 | ✅ |

## ドキュメント

詳細なAPIドキュメントは [GitHub Pages](https://no-problem-dev.github.io/swift-api-contract/documentation/apicontract/) で確認できます。

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照してください。
