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
    @State var otpCode: String = ""
    /// Shown once the server answers that this account uses two-factor authentication.
    @State var needsOtpCode: Bool = false
    @State var errors: String = ""
    @State var isLoading: Bool = false

    var body: some View {
        Form {
            TextField("Tenant", text: $tenant)
            TextField("Email", text: $email)
            SecureField("Password", text: $password)

            if needsOtpCode {
                TextField("Two-factor code", text: $otpCode)
            }

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
            try await AuthManager.shared.login(
                tenant: tenant, email: email, password: password,
                otpCode: needsOtpCode ? otpCode : nil
            )
        } catch AuthError.invalidCredentials {
            errors = "User not found or password wrong, please try again"
        } catch AuthError.twoFactorRequired {
            needsOtpCode = true
            errors = "Enter the code from your authenticator app (or a backup code)"
        } catch AuthError.twoFactorInvalid {
            otpCode = ""
            errors = "That code didn't work, please try again"
        } catch AuthError.twoFactorSetupRequired {
            errors = "Your workspace requires two-factor authentication. Set it up in docket in your browser first."
        } catch {
            errors = "An error occurred, please try again"
        }
    }
}

#Preview {
    LoginView().frame(width: 300)
}
