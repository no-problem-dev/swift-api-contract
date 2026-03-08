import Foundation

/// API契約を実行するプロトコル
public protocol APIExecutable: Sendable {
    /// メタデータ付きレスポンスを返す（基本実装）
    func executeWithResponse<E: APIContract>(_ contract: E) async throws -> APIResponse<E.Output>
        where E.Input == E, E: APIInput

    /// Output のみ返す（コンビニエンス）
    func execute<E: APIContract>(_ contract: E) async throws -> E.Output
        where E.Input == E, E: APIInput

    /// EmptyOutput 用（コンビニエンス）
    func execute<E: APIContract>(_ contract: E) async throws
        where E.Input == E, E.Output == EmptyOutput, E: APIInput
}

extension APIExecutable {
    public func execute<E: APIContract>(_ contract: E) async throws -> E.Output
        where E.Input == E, E: APIInput
    {
        try await executeWithResponse(contract).output
    }

    public func execute<E: APIContract>(_ contract: E) async throws
        where E.Input == E, E.Output == EmptyOutput, E: APIInput
    {
        _ = try await executeWithResponse(contract)
    }
}
