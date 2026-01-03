# Changelog

このプロジェクトのすべての注目すべき変更はこのファイルに記録されます。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [未リリース]

なし

## [1.0.5] - 2026-01-03

### 変更

- **APIExecutor → APIExecutable リネーム**: ~able命名規則に統一
  - `APIExecutor` プロトコルを `APIExecutable` に変更

### 改善

- **コードクリーンアップ**: 不要なMARKコメントと冗長なドキュメントを削除
  - publicプロトコルには簡潔なドキュメントコメントを保持

### 修正

- **テスト修正**: テストの期待値をマクロ出力に合わせて更新

## [1.0.4] - 2026-01-02

### 変更

- **Swift 6.2 対応**: Swift 6.2 安定版に対応
  - `swift-tools-version`: 6.0 → 6.2
  - `swift-syntax`: 600.0.0 → 602.0.0
  - 依存関係指定を `.upToNextMajor` に統一

### 追加

- **CI テストワークフロー**: Linux x86_64 でのテストを追加
  - Linux x86_64 (swift:6.2-bookworm)

## [1.0.3] - 2026-01-01

### 追加

- **@APIServices マクロ**
  - 複数のAPIサービスを一括登録するマクロ
  - `registerAll<R: Routes>(_ routes: R)` メソッドを自動生成

- **APIRouteRegistrar プロトコル**
  - ルート登録のための型安全な抽象化

### 変更

- **Handler → Service リネーム**
  - `APIGroupHandler` → `APIService`
  - `APIRouteRegistrar.Handler` → `APIRouteRegistrar.Service`
  - `@APIGroup` マクロが生成するプロトコル名を `XxxHandler` → `XxxService` に変更

## [1.0.2] - 2026-01-01

### 追加

- **サーバーサイドハンドラプロトコル**
  - `APIGroupHandler`: 型安全なAPIハンドラプロトコル
  - `AuthenticationProvider`: 認証抽象化プロトコル
  - `HandlerContext`: 認証済みユーザーコンテキスト

- **エラーハンドリング**
  - `APIContractError`: 標準化されたエラー型（unauthorized, forbidden, notFound, badRequest, conflict, internalError）

### 変更

- `HTTPMethod` を `APIMethod` にリネーム
- `@Endpoint` マクロに `authRequirement` パラメータを追加
- `AuthRequirement` enum を追加（none, required）

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
  - `APIMethod`: GET、POST、PUT、DELETE、PATCH、HEAD、OPTIONS
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

[未リリース]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.5...HEAD
[1.0.5]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/no-problem-dev/swift-api-contract/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/no-problem-dev/swift-api-contract/releases/tag/v1.0.0

<!-- Auto-generated on 2025-12-31T03:15:51Z by release workflow -->

<!-- Auto-generated on 2025-12-31T08:03:40Z by release workflow -->

<!-- Auto-generated on 2026-01-01T05:49:57Z by release workflow -->

<!-- Auto-generated on 2026-01-01T12:25:13Z by release workflow -->

<!-- Auto-generated on 2026-01-02T07:35:29Z by release workflow -->
