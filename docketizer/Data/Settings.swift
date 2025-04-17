//
//  SettingsManager.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import Foundation

class Settings {
    private let defaults = UserDefaults.standard
    
    var apiKey: String? {
        get { return defaults.string(forKey: "apiKey") }
        set { defaults.set(newValue, forKey: "apiKey") }
    }
    
    var tenant: String? {
        get { return defaults.string(forKey: "tenant") }
        set { defaults.set(newValue, forKey: "tenant") }
    }
}
