# Changelog

このプロジェクトのすべての注目すべき変更はこのファイルに記録されます。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [未リリース]

<!-- 次のリリースに含める変更をここに追加 -->

## [1.0.0] - 2025-12-31

### 追加

- **コアプロトコル**
  - `APIContract`: エンドポイント定義のコアプロトコル
  - `APIInput`: リクエストパラメータ（パス、クエリ、ボディ）の型安全な定義
  - `APIContractGroup`: 関連エンドポイントのグループ化
  - `APIExecutor`: API実行のための抽象プロトコル

- **マクロ**
  - `@Endpoint`: エンドポイント構造体の自動生成マクロ
  - `@APIGroup`: APIグループenumの自動生成マクロ
  - `@PathParam`: パスパラメータのマーカーマクロ
  - `@QueryParam`: クエリパラメータのマーカーマクロ（カスタム名サポート）
  - `@Body`: リクエストボディのマーカーマクロ

- **型ユーティリティ**
  - `EmptyInput`: パラメータなしエンドポイント用
  - `EmptyOutput`: レスポンスボディなしエンドポイント用
  - `HTTPMethod`: GET、POST、PUT、DELETE、PATCH、HEAD、OPTIONS
  - `AuthRequirement`: none、required

- **自動コード生成**
  - `pathParameters`プロパティの自動生成
  - `queryParameters`プロパティの自動生成
  - `encodeBody()`メソッドの自動生成
  - `init()`イニシャライザの自動生成
  - URLRequest構築の自動化

### ドキュメント

- README.md（日本語・英語）
- DocCドキュメント
- CHANGELOG.md

### テスト

- マクロ展開テスト（EndpointMacroTests）

[未リリース]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/no-problem-dev/swift-api-contract/releases/tag/v1.0.0
