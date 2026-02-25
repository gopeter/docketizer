//
//  docketizerApp.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import AppKit
import MenuBarExtraAccess
import SwiftUI

@main
struct docketizerApp: App {
    @State private var isMenuPresented = false

    var body: some Scene {
        MenuBarExtra(
            content: {
                RootView()
                    .onReceive(ShortcutManager.shared.toggleMenuSignal) {
                        isMenuPresented.toggle()
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
            SettingsView()
        }
    }
}
