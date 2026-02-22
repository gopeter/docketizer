//
//  AppDefaults.swift
//  docketizer
//
//  Created by Peter Oesteritz on 03.04.25.
//

import Foundation

enum AppDefaults {
    /// App Group identifier used for shared defaults storage.
    static let appGroupIdentifier = "group.com.docket.docketizer"

    /// Shared UserDefaults store for the app group.
    /// Falls back to standard if the suite cannot be created.
    static let shared: UserDefaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard

    /// Convenience accessors
    static var apiKey: String? {
        get { shared.string(forKey: "apiKey") }
        set { shared.set(newValue, forKey: "apiKey") }
    }

    static var tenant: String? {
        get { shared.string(forKey: "tenant") }
        set { shared.set(newValue, forKey: "tenant") }
    }
}
