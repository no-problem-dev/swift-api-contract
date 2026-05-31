import Foundation

/// Encodes a request body to bytes.
///
/// The Codec seam: API definitions depend on this abstraction instead of a
/// concrete `JSONEncoder`, so the client layer can supply any
/// implementation (Foundation, swift-structured-data, …) without API authors
/// knowing or choosing. Authors still only write `Encodable` types.
public protocol APIBodyEncoder: Sendable {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

/// Decodes bytes into a response/body type.
public protocol APIBodyDecoder: Sendable {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

// Foundation's coders already have matching shapes; conform them so the default
// path keeps working while higher layers move to swift-structured-data.
extension JSONEncoder: APIBodyEncoder {}
extension JSONDecoder: APIBodyDecoder {}
