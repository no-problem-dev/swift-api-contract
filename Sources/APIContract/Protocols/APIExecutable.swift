import Foundation

/// API契約を実行するプロトコル
public protocol APIExecutable: Sendable {
    func execute<E: APIContract>(_ contract: E) async throws -> E.Output
        where E.Input == E, E: APIInput

    func execute<E: APIContract>(_ contract: E) async throws
        where E.Input == E, E.Output == EmptyOutput, E: APIInput
}
