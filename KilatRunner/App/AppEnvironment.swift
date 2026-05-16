import Foundation

enum AppEnvironment {
    #if DEBUG
    static let baseURL = URL(string: "http://localhost:8080")!
    #else
    static let baseURL = URL(string: "https://api.kilat.my")!
    #endif

    static var apiBaseURL: URL {
        baseURL.appending(path: "api/v1")
    }

    static var wsBaseURL: URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        return components.url!
    }
}
