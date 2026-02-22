//
//  RootView.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import SwiftUI

struct RootView: View {
    @AppStorage("apiKey", store: AppDefaults.shared) var apiKey: String?
    @AppStorage("tenant", store: AppDefaults.shared) var tenant: String?

    var body: some View {
        Group {
            if apiKey == nil || tenant == nil {
                LoginView().frame(width: 300)
            } else {
                ContentView()
                    .frame(width: 640, height: 300)
                    .onAppear {
                        Task { await AuthManager.shared.refreshIfNeeded() }
                    }
            }
        }
    }
}

#Preview {
    RootView()
}
