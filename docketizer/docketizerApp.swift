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
        // If an apiKey exists in AppDefaults but no credentials are in the Keychain,
        // the session belongs to a different build or was manually cleared – force logout
        // so the user isn't stuck in a broken authenticated state.
        // if AppDefaults.apiKey != nil {
        //     let hasCredentials =
        //         KeychainHelper.load(for: "email") != nil
        //         && KeychainHelper.load(for: "password") != nil
        //     if !hasCredentials {
        //         AuthManager.shared.logout()
        //     }
        // }

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
