# APIContract

[English](./README.md) | 日本語

HTTP API を Swift で一度書けば、クライアントとサーバーが同じ定義を共有する。エンドポイント・パラメータ・エラーが両側でコンパイラに検査される。

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 概要

エンドポイントは struct として書く。プロパティがリクエスト、`Output` がレスポンスで、その間はマクロが生成する。
URL の組み立て、クエリのエンコード、ボディのエンコード、そして生のリクエストを同じ struct に戻すサーバー側のデコードまで。

- `@APIGroup` / `@Endpoint` で API を宣言的に記述する
- `@PathParam`・`@QueryParam`・`@Body`・`@Header` が各値をリクエストのどこに置くかを決める
- `@StreamingEndpoint` が Server-Sent Events を扱う
- 通信層は同梱しない。クライアントは自分で用意するので URLSession でも他でも動く

## 使い方

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

## ドキュメント

[API リファレンスとガイド](https://no-problem-dev.github.io/swift-api-contract/documentation/apicontract/) —
エンドポイントの定義、クライアントの実装、同じ定義でサーバーを動かす方法。

## 動作環境

Swift 6.0+ · iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+ · Linux

## インストール

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

## コントリビュート

[CONTRIBUTING.md](CONTRIBUTING.md) を参照。

## ライセンス

MIT License — 詳細は [LICENSE](LICENSE) を参照。
