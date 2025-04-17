//
//  docketizerApp.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import SwiftUI

@main
struct docketizerApp: App {
    var body: some Scene {
        MenuBarExtra("Docketizer", systemImage: "clock") {
            RootView()
        }
        .menuBarExtraStyle(.window)
    }
}
