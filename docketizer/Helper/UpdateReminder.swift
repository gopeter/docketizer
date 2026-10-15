//
//  UpdateReminder.swift
//  docketizer
//

import AppKit
import Sparkle

/// Implements Sparkle's "gentle reminders" for this menu bar app.
///
/// As a background app (LSUIElement), an update alert found by a scheduled check would pop up
/// behind other apps and easily go unnoticed. Instead we keep track of the pending update and
/// show unobtrusive indicators (menu bar badge, footer button, context menu entry).
/// See https://sparkle-project.org/documentation/gentle-reminders
///
/// Also owns the updater itself, so views and the AppDelegate share one instance.
final class UpdateReminder: NSObject, ObservableObject, SPUStandardUserDriverDelegate {
    static let shared = UpdateReminder()

    /// Created on first access – AppDelegate touches it at launch so scheduled checks start right away.
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: self
    )

    var updater: SPUUpdater { updaterController.updater }

    /// Display version of an update found by a scheduled check that the user hasn't looked at yet.
    @Published private(set) var pendingUpdateVersion: String? = nil

    var hasPendingUpdate: Bool { pendingUpdateVersion != nil }

    // MARK: - SPUStandardUserDriverDelegate

    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        // Let Sparkle show the alert only if it would be in utmost focus (e.g. right after launch),
        // otherwise we show our own reminder.
        immediateFocus
    }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        guard !handleShowingUpdate else { return }
        pendingUpdateVersion = update.displayVersionString
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        pendingUpdateVersion = nil
    }

    func standardUserDriverWillFinishUpdateSession() {
        pendingUpdateVersion = nil
    }

    // MARK: - Actions

    /// Brings the pending update (or a fresh check) into focus.
    func showUpdate() {
        // As a background app we need to activate first, otherwise the alert opens behind other apps
        NSApp.activate()
        updater.checkForUpdates()
    }
}
