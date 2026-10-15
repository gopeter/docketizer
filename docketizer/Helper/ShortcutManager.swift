//
//  ShortcutManager.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import AppKit
import Combine
import Foundation
import MenuBarExtraAccess

struct RecordedShortcut: Codable, Equatable {
    let keyCode: UInt16
    let modifiers: UInt
    let displayString: String

    var eventModifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers).intersection(.deviceIndependentFlagsMask)
    }
}

class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()

    @Published var shortcut: RecordedShortcut? {
        didSet {
            saveShortcut()
            registerGlobalShortcut()
        }
    }

    /// The MenuBarExtra's status item, handed over by MenuBarExtraAccess. The shortcut toggles it
    /// directly – a signal observed inside the popover content would be lost until the popover was
    /// opened once, since SwiftUI only builds the content then.
    weak var statusItem: NSStatusItem?

    @Published var hasAccessibilityPermission: Bool = false

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let userDefaultsKey = "globalShortcut"

    private init() {
        loadShortcut()
        checkAccessibilityPermission()
        registerGlobalShortcut()
    }

    // MARK: - Accessibility

    func checkAccessibilityPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        AXIsProcessTrustedWithOptions(options)
        // Poll for a few seconds after the prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.checkAccessibilityPermission()
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Persistence

    private func loadShortcut() {
        guard
            let data = UserDefaults.standard.data(forKey: userDefaultsKey),
            let decoded = try? JSONDecoder().decode(RecordedShortcut.self, from: data)
        else { return }

        shortcut = decoded
    }

    private func saveShortcut() {
        guard let shortcut else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            return
        }
        if let encoded = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    // MARK: - Global Monitor

    func registerGlobalShortcut() {
        // Remove existing monitors first
        if let existing = globalMonitor {
            NSEvent.removeMonitor(existing)
            globalMonitor = nil
        }
        if let existing = localMonitor {
            NSEvent.removeMonitor(existing)
            localMonitor = nil
        }

        guard let shortcut, hasAccessibilityPermission else { return }

        // Global monitor fires when another app is in the foreground
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == shortcut.keyCode && flags == shortcut.eventModifiers {
                DispatchQueue.main.async {
                    self.statusItem?.togglePresented()
                }
            }
        }

        // Local monitor fires when this app (i.e. the MenuBarExtra window) is in the foreground
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == shortcut.keyCode && flags == shortcut.eventModifiers {
                DispatchQueue.main.async {
                    self?.statusItem?.togglePresented()
                }
                return nil  // consume the event
            }
            return event
        }

    }

    // MARK: - Formatting

    static func formatShortcut(flags: NSEvent.ModifierFlags, keyCode: UInt16, chars: String) -> String {
        var result = ""
        let f = flags.intersection(.deviceIndependentFlagsMask)
        if f.contains(.control) { result += "⌃" }
        if f.contains(.option) { result += "⌥" }
        if f.contains(.shift) { result += "⇧" }
        if f.contains(.command) { result += "⌘" }
        // Fall back to a keyCode-based label for non-printable keys
        let label = Self.labelForKeyCode(keyCode, chars: chars)
        result += label
        return result
    }

    static func labelForKeyCode(_ keyCode: UInt16, chars: String) -> String {
        switch keyCode {
        case 36: return "↩"
        case 48: return "⇥"
        case 49: return "Space"
        case 51: return "⌫"
        case 53: return "⎋"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 116: return "PgUp"
        case 121: return "PgDn"
        case 115: return "↖"
        case 119: return "↘"
        default:
            let clean = chars.trimmingCharacters(in: .controlCharacters)
            return clean.isEmpty ? "(\(keyCode))" : clean.uppercased()
        }
    }
}
