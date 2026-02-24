//
//  AppDefaults.swift
//  docketizer
//
//  Created by Peter Oesteritz on 03.04.25.
//

import Foundation

enum AppDefaults {
    /// The shared UserDefaults store for this app.
    /// Using .standard – there is no extension or widget that requires an App Group suite.
    static let shared: UserDefaults = .standard

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
