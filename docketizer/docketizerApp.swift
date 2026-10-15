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
    /// Set by MenuBarLabel – SwiftUI's Settings scene can only be opened from within a view.
    var openSettings: (() -> Void)?

    private var rightClickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Both are lazy singletons – start them right at launch instead of waiting for the popover
        // to be opened (e.g. after launch at login), so update checks and the global shortcut work.
        _ = UpdateReminder.shared.updater
        _ = ShortcutManager.shared

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

        let pendingVersion = UpdateReminder.shared.pendingUpdateVersion
        let updateItem = NSMenuItem(
            title: pendingVersion.map { "Install Update \($0)…" } ?? "Check for Updates…",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        updateItem.isEnabled = UpdateReminder.shared.updater.canCheckForUpdates
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
        UpdateReminder.shared.showUpdate()
    }
}

// MARK: - App

@main
struct docketizerApp: App {
    @State private var isMenuPresented = false

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var updateReminder = UpdateReminder.shared

    var body: some Scene {
        MenuBarExtra(
            content: {
                RootView()
            },
            label: {
                let image: NSImage = {
                    let ratio = $0.size.height / $0.size.width
                    $0.size.height = 17
                    $0.size.width = 17 / ratio
                    return $0
                }(NSImage(named: "favicon")!)

                MenuBarLabel(
                    image: updateReminder.hasPendingUpdate ? Self.badged(image) : image,
                    appDelegate: appDelegate
                )
            }
        )
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isMenuPresented) { statusItem in
            ShortcutManager.shared.statusItem = statusItem
        }

        SwiftUI.Settings {
            SettingsView(updater: UpdateReminder.shared.updater)
        }
    }

    /// Draws a small dot into the top-right corner of the menu bar icon to signal a pending update.
    /// MenuBarExtra labels ignore SwiftUI overlays, so the badge has to be part of the image itself.
    /// The result stays a template image so it keeps adapting to light/dark menu bars.
    private static func badged(_ image: NSImage) -> NSImage {
        let badged = NSImage(size: image.size, flipped: false) { rect in
            image.draw(in: rect)

            let diameter: CGFloat = 6
            let dot = NSRect(x: rect.maxX - diameter, y: rect.maxY - diameter, width: diameter, height: diameter)

            // Cut out a small gap around the dot so it stands out from the icon
            NSGraphicsContext.current?.compositingOperation = .clear
            NSBezierPath(ovalIn: dot.insetBy(dx: -1.5, dy: -1.5)).fill()

            NSGraphicsContext.current?.compositingOperation = .sourceOver
            NSColor.black.setFill()
            NSBezierPath(ovalIn: dot).fill()
            return true
        }
        badged.isTemplate = true
        return badged
    }
}

// MARK: - Menu Bar Label

/// The menu bar icon. Also hands SwiftUI's `openSettings` action over to the AppDelegate for the
/// right-click menu: unlike the popover content, the label exists right from launch.
private struct MenuBarLabel: View {
    let image: NSImage
    let appDelegate: AppDelegate

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Image(nsImage: image)
            .onAppear {
                appDelegate.openSettings = { openSettings() }
            }
    }
}
