//
//  docketizerApp.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import AppKit
import MenuBarExtraAccess
import Sparkle
import SwiftUI

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()

    var updaterController: SPUStandardUpdaterController?
    var openSettings: (() -> Void)?

    private var rightClickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self,
                let window = event.window,
                window.className.contains("StatusBar")
            else { return event }

            let capturedWindow = window
            Task { @MainActor in self.showContextMenu(in: capturedWindow) }
            return nil
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = rightClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    @MainActor
    func showContextMenu(in eventWindow: NSWindow? = nil) {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(openSettingsWindow),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let updateItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        updateItem.isEnabled = updaterController?.updater.canCheckForUpdates ?? false
        menu.addItem(updateItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit docketizer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        // The event's own window is the NSStatusBarWindow – its contentView is the button
        if let button = eventWindow?.contentView as? NSButton {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        } else if let button = eventWindow?.contentView?.subviews.first as? NSButton {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        } else {
            // Last resort: show at mouse location
            menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        }
    }

    @objc private func openSettingsWindow() {
        openSettings?()
    }

    @objc private func checkForUpdates() {
        updaterController?.updater.checkForUpdates()
    }
}

// MARK: - App

@main
struct docketizerApp: App {
    @State private var isMenuPresented = false

    private let updaterController: SPUStandardUpdaterController
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    var body: some Scene {
        MenuBarExtra(
            content: {
                RootView()
                    .onReceive(ShortcutManager.shared.toggleMenuSignal) {
                        isMenuPresented.toggle()
                    }
                    .onAppear {
                        appDelegate.updaterController = updaterController
                    }
            },
            label: {
                let image: NSImage = {
                    let ratio = $0.size.height / $0.size.width
                    $0.size.height = 17
                    $0.size.width = 17 / ratio
                    return $0
                }(NSImage(named: "favicon")!)

                Image(nsImage: image)
            }
        )
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isMenuPresented)

        SwiftUI.Settings {
            SettingsView(updater: updaterController.updater)
        }
    }
}
