import Foundation

/// The seam that keeps a concrete JSON encoder out of API definitions.
///
/// Endpoints depend on this abstraction instead of `JSONEncoder`, so the client layer decides
/// which implementation actually runs — Foundation's, or a faster one — while whoever writes the
/// API definitions only has to make their types `Encodable`.
public protocol APIBodyEncoder: Sendable {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

/// The decoding half of the same seam, used for response bodies and for server-side input decoding.
public protocol APIBodyDecoder: Sendable {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

// Foundation's coders already have matching shapes; conform them so the default
// path keeps working while higher layers move to swift-structured-data.
extension JSONEncoder: APIBodyEncoder {}
extension JSONDecoder: APIBodyDecoder {}
