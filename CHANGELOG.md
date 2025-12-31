# Changelog

このプロジェクトのすべての注目すべき変更はこのファイルに記録されます。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [未リリース]

<!-- 次のリリースに含める変更をここに追加 -->

## [1.0.1] - 2025-12-31

### 修正

- **Linux サポート**
  - `EndpointMacro.swift`: `String.replacingOccurrences` 使用のため `Foundation` をインポート
  - `APIContract.swift`: `URLRequest` 使用のため `FoundationNetworking` を条件付きインポート

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

### CI/CD

- **GitHub Actions**
  - `tests.yml`: PRごとのテスト自動実行
  - `auto-release-on-merge.yml`: リリースブランチマージ時の自動リリース
  - `docc.yml`: DocCドキュメントのGitHub Pagesデプロイ
- **自動リリースフロー**
  - CHANGELOGバリデーション
  - Gitタグ自動作成
  - GitHub Release自動生成
  - 次バージョンリリースブランチ自動作成

### ドキュメント

- README.md（日本語・英語）
- DocCドキュメント（GettingStarted、DefiningEndpoints）
- CHANGELOG.md

### テスト

- マクロ展開テスト（EndpointMacroTests）

[未リリース]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/no-problem-dev/swift-api-contract/releases/tag/v1.0.0

<!-- Auto-generated on 2025-12-31T03:15:51Z by release workflow -->

<!-- Auto-generated on 2025-12-31T08:03:40Z by release workflow -->
