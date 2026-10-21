import Foundation

/// Where docket lives — the one place that names its domain. `DOCKET_URL` (set in the scheme for
/// development) overrides it; SwiftUI previews talk to the local dev server. Workspaces are
/// subdomains of it (`<tenant>.docket.rocks`); the former godocket.app still answers the API, but
/// docket.rocks is canonical since October 2026.
enum DocketServer {
    static let productionDomain = "docket.rocks"

    static var domain: String {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return "docket.dev:3000"
        }
        return ProcessInfo.processInfo.environment["DOCKET_URL"] ?? productionDomain
    }
}
