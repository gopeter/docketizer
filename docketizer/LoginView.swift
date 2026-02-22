//
//  LoginView.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import SwiftUI

struct LoginView: View {
    @State var tenant: String = ""
    @State var email: String = ""
    @State var password: String = ""
    @State var errors: String = ""
    @State var isLoading: Bool = false

    var body: some View {
        Form {
            TextField("Tenant", text: $tenant)
            TextField("Email", text: $email)
            SecureField("Password", text: $password)

            if errors != "" {
                Text(errors).padding(.vertical)
            }

            Button(action: { Task { await login() } }) {
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 12, height: 12)
                    }
                    Text(isLoading ? "Logging in …" : "Login")
                }
            }
            .disabled(isLoading)
        }
        .onSubmit {
            guard !isLoading else { return }
            Task { await login() }
        }
        .padding()
    }

    private func login() async {
        errors = ""
        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthManager.shared.login(tenant: tenant, email: email, password: password)
        } catch AuthError.invalidCredentials {
            errors = "User not found or password wrong, please try again"
        } catch {
            errors = "An error occurred, please try again"
        }
    }
}

#Preview {
    LoginView().frame(width: 300)
}
