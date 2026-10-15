//
//  AuthManager.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import Foundation

enum AuthError: Error {
    case invalidURL
    case encodingError
    case invalidCredentials
    case serverError
    /// The account has two-factor authentication: ask for the authenticator app's code.
    case twoFactorRequired
    /// The two-factor code was wrong (or already used).
    case twoFactorInvalid
    /// The workspace requires two-factor authentication and the user hasn't set it up yet —
    /// only possible in the web app.
    case twoFactorSetupRequired
}

enum SilentReAuthResult {
    case success
    case failure(requiresLogin: Bool, error: Error?)
}

private struct LoginResponse: Codable {
    let auth_token: String
    /// Only for users with two-factor authentication: stands in for the code on later logins
    /// (30 days), so silent re-authentication works without asking for a code.
    let two_factor_token: String?
}

private struct LoginErrorResponse: Codable {
    let error: String?
    let code: String?
}

private struct LoginResult {
    let token: String
    let twoFactorToken: String?
}

class AuthManager {
    static let shared = AuthManager()

    private var reAuthTask: Task<SilentReAuthResult, Never>?
    private var lastReAuthDate: Date?
    private var lastReAuthResult: SilentReAuthResult?
    private var cachedTenant: String?
    private var cachedEmail: String?
    private var cachedPassword: String?

    private init() {}

    // MARK: - Public

    /// Logs in, saves credentials to Keychain, updates UserDefaults, reconfigures Apollo.
    /// `otpCode` is the authenticator app's code (or a backup code) for accounts with
    /// two-factor authentication — the first attempt without it throws `.twoFactorRequired`.
    func login(tenant: String, email: String, password: String, otpCode: String? = nil) async throws {
        let result = try await performLogin(
            tenant: tenant, email: email, password: password,
            otpCode: otpCode, twoFactorToken: KeychainHelper.load(for: "twoFactorToken")
        )
        let token = result.token
        storeTwoFactorToken(result.twoFactorToken)

        KeychainHelper.save(email, for: "email")
        KeychainHelper.save(password, for: "password")
        KeychainHelper.save(tenant, for: "tenant")

        UserDefaults.standard.set(token, forKey: "apiKey")
        UserDefaults.standard.set(tenant, forKey: "tenant")

        cachedTenant = tenant
        cachedEmail = email
        cachedPassword = password

        lastReAuthDate = nil
        lastReAuthResult = nil
        reAuthTask?.cancel()
        reAuthTask = nil

        Apollo.shared.configureClient()
    }

    /// Clears the session from both Keychain and UserDefaults.
    func logout() {
        KeychainHelper.delete(for: "email")
        KeychainHelper.delete(for: "password")
        KeychainHelper.delete(for: "tenant")
        KeychainHelper.delete(for: "twoFactorToken")

        UserDefaults.standard.removeObject(forKey: "apiKey")
        UserDefaults.standard.removeObject(forKey: "tenant")

        cachedTenant = nil
        cachedEmail = nil
        cachedPassword = nil

        lastReAuthDate = nil
        lastReAuthResult = nil
        reAuthTask?.cancel()
        reAuthTask = nil
    }

    /// Silently re-authenticates using stored Keychain credentials.
    /// Concurrent calls coalesce into a single request.
    /// Returns success or failure and updates UserDefaults with the new token.
    @discardableResult
    func silentReAuth(failedToken: String? = nil, force: Bool = false) async -> SilentReAuthResult {
        let currentToken = UserDefaults.standard.string(forKey: "apiKey")

        // Another concurrent caller already refreshed the token – treat as success.
        if !force,
            let failedToken,
            let currentToken,
            failedToken != currentToken
        {
            return .success
        }

        // Throttle: avoid retry loops within 30s.
        if !force,
            let lastDate = lastReAuthDate,
            Date().timeIntervalSince(lastDate) < 30,
            let lastResult = lastReAuthResult
        {
            return lastResult
        }

        // Coalesce concurrent calls into one in-flight task.
        if let existing = reAuthTask {
            return await existing.value
        }

        let task = Task<SilentReAuthResult, Never> {
            defer { reAuthTask = nil }

            let storedTenant = KeychainHelper.load(for: "tenant") ?? cachedTenant
            let email = KeychainHelper.load(for: "email") ?? cachedEmail
            let password = KeychainHelper.load(for: "password") ?? cachedPassword

            guard
                let storedTenant,
                let email,
                let password
            else {
                // Credentials are unavailable – do not force a logout since we have no proof
                // they are wrong. Return a non-fatal failure so the caller surfaces a network
                // error instead of kicking the user out.
                lastReAuthDate = Date()
                let result = SilentReAuthResult.failure(requiresLogin: false, error: nil)
                lastReAuthResult = result
                return result
            }

            do {
                let result = try await performLogin(
                    tenant: storedTenant, email: email, password: password,
                    otpCode: nil, twoFactorToken: KeychainHelper.load(for: "twoFactorToken")
                )
                storeTwoFactorToken(result.twoFactorToken)
                // Update UserDefaults so AuthHeaderInterceptor picks up the new token on retry.
                UserDefaults.standard.set(result.token, forKey: "apiKey")
                UserDefaults.standard.set(storedTenant, forKey: "tenant")

                lastReAuthDate = Date()
                lastReAuthResult = .success
                return .success
            } catch let authError as AuthError where authError != .serverError && authError != .invalidURL && authError != .encodingError {
                // Wrong credentials, or the server wants a two-factor code (the remembered
                // two-factor token expired or was voided): only the login form can help.
                lastReAuthDate = Date()
                let result = SilentReAuthResult.failure(requiresLogin: true, error: authError)
                lastReAuthResult = result
                return result
            } catch {
                // On network error, return failure but do not require login.
                lastReAuthDate = Date()
                let result = SilentReAuthResult.failure(requiresLogin: false, error: error)
                lastReAuthResult = result
                return result
            }
        }

        reAuthTask = task
        return await task.value
    }

    /// Called on ContentView appear. Proactively refreshes the token if it expires
    /// within the next 5 minutes. Never logs the user out – a failed refresh here is
    /// non-fatal since the 401 interceptor will handle an actually-expired token.
    func refreshIfNeeded() async {
        guard let currentToken = UserDefaults.standard.string(forKey: "apiKey") else { return }
        guard let expiry = tokenExpiryDate(from: currentToken) else { return }
        guard expiry.timeIntervalSinceNow < 5 * 60 else { return }

        await silentReAuth(force: true)
    }

    // MARK: - JWT

    /// Decodes the expiry date from a JWT payload. JWTs are base64url-encoded JSON,
    /// so no crypto library is needed to read the claims.
    func tokenExpiryDate(from token: String) -> Date? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }

        // Base64url → Base64 (URL-safe chars replaced, padding added).
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = payload.count % 4
        if remainder > 0 {
            payload += String(repeating: "=", count: 4 - remainder)
        }

        guard
            let data = Data(base64Encoded: payload),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let exp = json["exp"] as? TimeInterval
        else {
            return nil
        }

        return Date(timeIntervalSince1970: exp)
    }

    // MARK: - Private

    private func storeTwoFactorToken(_ token: String?) {
        if let token {
            KeychainHelper.save(token, for: "twoFactorToken")
        } else {
            KeychainHelper.delete(for: "twoFactorToken")
        }
    }

    private func performLogin(
        tenant: String, email: String, password: String, otpCode: String?, twoFactorToken: String?
    ) async throws -> LoginResult {
        var domain = ProcessInfo.processInfo.environment["DOCKET_URL"] ?? "godocket.app"
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            domain = "docket.dev:3000"
        }

        guard let url = URL(string: "https://\(tenant).\(domain)/api/login") else {
            throw AuthError.invalidURL
        }

        var payload = ["email": email, "password": password]
        if let otpCode, !otpCode.isEmpty { payload["otp_code"] = otpCode }
        if let twoFactorToken { payload["two_factor_token"] = twoFactorToken }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            throw AuthError.encodingError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                // `code` tells two-factor answers apart from wrong credentials.
                switch (try? JSONDecoder().decode(LoginErrorResponse.self, from: data))?.code {
                case "otp_required": throw AuthError.twoFactorRequired
                case "otp_invalid": throw AuthError.twoFactorInvalid
                case "otp_setup_required": throw AuthError.twoFactorSetupRequired
                default: throw AuthError.invalidCredentials
                }
            } else {
                throw AuthError.serverError
            }
        }

        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
        return LoginResult(token: decoded.auth_token, twoFactorToken: decoded.two_factor_token)
    }
}
