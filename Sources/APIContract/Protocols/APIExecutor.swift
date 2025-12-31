import Foundation

/// API契約を実行するプロトコル
///
/// HTTPクライアントやモッククライアントがこのプロトコルに準拠し、
/// APIContractの実行を可能にします。
///
/// ## 使用例
/// ```swift
/// let client: APIExecutor = APIClientImpl(baseURL: url)
/// let activities = try await ActivitiesAPI.List(limit: 20).execute(using: client)
/// ```
public protocol APIExecutor: Sendable {
    /// APIContractを実行してレスポンスを返す
    ///
    /// - Parameter contract: 実行するAPI契約
    /// - Returns: デコードされたレスポンス（contract.Output型）
    func execute<E: APIContract>(_ contract: E) async throws -> E.Output
        where E.Input == E, E: APIInput

    /// レスポンスボディがないAPIContractを実行（DELETE等）
    ///
    /// - Parameter contract: 実行するAPI契約
    func execute<E: APIContract>(_ contract: E) async throws
        where E.Input == E, E.Output == EmptyOutput, E: APIInput
}
