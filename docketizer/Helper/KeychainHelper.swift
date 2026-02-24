//
//  KeychainHelper.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import Foundation
import Security

struct KeychainHelper {
    #if DEBUG
        private static let service = (Bundle.main.bundleIdentifier ?? "dev.docket.docketizer") + ".debug"
    #else
        private static let service = Bundle.main.bundleIdentifier ?? "dev.docket.docketizer"
    #endif
    private static let fallbackDefaults = AppDefaults.shared
    private static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    @discardableResult
    static func save(_ value: String, for key: String) -> Bool {
        guard !isPreview else { return true }
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        // Delete any existing item first to allow updates
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            fallbackDefaults.set(value, forKey: "keychain_fallback_\(key)")
        }
        return true
    }

    static func load(for key: String) -> String? {
        guard !isPreview else { return nil }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
            let data = result as? Data,
            let string = String(data: data, encoding: .utf8)
        {
            return string
        }

        return fallbackDefaults.string(forKey: "keychain_fallback_\(key)")
    }

    @discardableResult
    static func delete(for key: String) -> Bool {
        guard !isPreview else { return true }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        fallbackDefaults.removeObject(forKey: "keychain_fallback_\(key)")
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
