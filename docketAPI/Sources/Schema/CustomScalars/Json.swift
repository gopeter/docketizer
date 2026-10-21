// @generated
// This file was automatically generated and can be edited to
// implement advanced custom scalar functionality.
//
// Any changes to this file will not be overwritten by future
// code generation execution.

import ApolloAPI

/// Any JSON value. docket uses it for a mutation's `errors`, e.g. `{"title": ["is too long"]}` –
/// an object, so it can't be a String (that would fail the whole response). What the app needs
/// from it are the messages.
public struct Json: CustomScalarType, Hashable {
    public let value: JSONValue

    public init(_jsonValue value: JSONValue) throws {
        self.value = value
    }

    public var _jsonValue: JSONValue { value }

    /// Every string in the value, keys of an object prepended: ["title is too long"].
    public var messages: [String] { Self.messages(in: value) }

    private static func messages(in value: JSONValue, key: String? = nil) -> [String] {
        switch value {
        case let string as String:
            return [key.map { "\($0) \(string)" } ?? string]
        case let array as [JSONValue]:
            return array.flatMap { messages(in: $0, key: key) }
        case let object as JSONObject:
            return object.keys.sorted().flatMap { messages(in: object[$0]!, key: $0 == "base" ? nil : $0) }
        default:
            return []
        }
    }
}
