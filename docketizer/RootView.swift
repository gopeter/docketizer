//
//  RootView.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import SwiftUI

struct RootView: View {
    @AppStorage("apiKey") var apiKey: String?
    @AppStorage("tenant") var tenant: String?
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        ZStack {
            Group {
                if apiKey == nil || tenant == nil {
                    LoginView().frame(width: 300)
                } else {
                    ContentView()
                        .frame(width: 640, height: 330)
                        .onAppear {
                            Task { await AuthManager.shared.refreshIfNeeded() }
                        }
                }
            }
            .disabled(!networkMonitor.isConnected)

            if !networkMonitor.isConnected {
                offlineOverlay
            }
        }
    }

    @ViewBuilder private var offlineOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            VStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)

                Text("You're offline")
                    .font(.headline)

                Text("Docketizer requires an internet connection.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.25)))
    }
}

#Preview {
    RootView()
}
