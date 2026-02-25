//
//  SettingsView.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import AppKit
import ServiceManagement
import Sparkle
import SwiftUI

// MARK: - Shortcut Recorder

struct ShortcutRecorderButton: View {
    @Binding var shortcut: RecordedShortcut?
    @State private var isRecording = false
    @State private var localMonitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                Text(isRecording ? "Recording …" : (shortcut?.displayString ?? "None"))
                    .frame(minWidth: 80)
            }
            .buttonStyle(.bordered)
            .foregroundStyle(isRecording ? .orange : .primary)

            if shortcut != nil && !isRecording {
                Button {
                    shortcut = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func startRecording() {
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Escape cancels recording
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            // Delete clears the shortcut
            if event.keyCode == 51 || event.keyCode == 117 {
                shortcut = nil
                stopRecording()
                return nil
            }

            // Require at least one modifier (excluding caps lock)
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let usableFlags = flags.subtracting(.capsLock)
            guard !usableFlags.isEmpty else { return event }

            let chars = event.charactersIgnoringModifiers ?? ""
            let display = ShortcutManager.formatShortcut(flags: usableFlags, keyCode: event.keyCode, chars: chars)

            shortcut = RecordedShortcut(keyCode: event.keyCode, modifiers: usableFlags.rawValue, displayString: display)
            stopRecording()

            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}

// MARK: - Check for Updates

final class UpdaterViewModel: ObservableObject {
    private let updater: SPUUpdater

    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        self.updater = updater
        // SPUUpdater publishes canCheckForUpdates via KVO
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}

struct CheckForUpdatesView: View {
    @StateObject private var viewModel: UpdaterViewModel

    init(updater: SPUUpdater) {
        _viewModel = StateObject(wrappedValue: UpdaterViewModel(updater: updater))
    }

    var body: some View {
        Button("Check for Updates…") {
            viewModel.checkForUpdates()
        }
        .disabled(!viewModel.canCheckForUpdates)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    let updater: SPUUpdater

    @StateObject private var shortcutManager = ShortcutManager.shared

    @State private var launchAtLogin: Bool = (SMAppService.mainApp.status == .enabled)
    @State private var launchAtLoginError: String? = nil

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                if let error = launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                CheckForUpdatesView(updater: updater)
            }

            Section("Global Shortcut") {
                LabeledContent("Open docketizer") {
                    ShortcutRecorderButton(shortcut: $shortcutManager.shortcut)
                }

                if !shortcutManager.hasAccessibilityPermission {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Accessibility access required")
                                .font(.callout)
                                .fontWeight(.medium)

                            Text("To use a global shortcut, docketizer needs Accessibility access so it can detect key presses while other apps are active.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button("Open Privacy Settings") {
                                shortcutManager.requestAccessibilityPermission()
                                shortcutManager.openAccessibilitySettings()
                            }
                            .padding(.top, 2)

                            Button("Check Again") {
                                shortcutManager.checkAccessibilityPermission()
                                if shortcutManager.hasAccessibilityPermission {
                                    shortcutManager.registerGlobalShortcut()
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .padding(0)
        .onAppear {
            // we don't want to focus our preview again and again
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows
                        .filter { $0.canBecomeKey && $0.styleMask.contains(.titled) }
                        .first?
                        .makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginError = error.localizedDescription
            // Revert the toggle if it failed
            launchAtLogin = !enabled
        }
    }
}

#Preview {
    SettingsView(updater: SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil).updater)
}
