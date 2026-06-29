import Foundation

/// リクエストボディをバイト列にエンコードするプロトコル
///
/// コーデック抽象化点: API 定義はこの抽象に依存し、具体的な `JSONEncoder` は選ばない。
/// クライアント層が Foundation・swift-structured-data など任意の実装を提供でき、
/// API 定義者は `Encodable` 型の記述だけに集中できる。
public protocol APIBodyEncoder: Sendable {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

/// バイト列をレスポンス/ボディ型にデコードするプロトコル。
public protocol APIBodyDecoder: Sendable {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

// Foundation's coders already have matching shapes; conform them so the default
// path keeps working while higher layers move to swift-structured-data.
extension JSONEncoder: APIBodyEncoder {}
extension JSONDecoder: APIBodyDecoder {}
