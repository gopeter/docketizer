//
//  docketizerApp.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check accessibility permission and register global shortcut on launch
        ShortcutManager.shared.checkAccessibilityPermission()
        ShortcutManager.shared.registerGlobalShortcut()
    }
}

@main
struct docketizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Docketizer", systemImage: "clock") {
            RootView()
        }
        .menuBarExtraStyle(.window)

        SwiftUI.Settings {
            SettingsView()
        }
    }
}
