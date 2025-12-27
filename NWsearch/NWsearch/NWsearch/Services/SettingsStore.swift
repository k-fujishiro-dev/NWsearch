import Foundation

final class SettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet { save() }
    }

    private let storageKey = "NWsearch.settings.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    func snapshot(endpoints: [Endpoint]) -> SettingsSnapshot {
        SettingsSnapshot(
            attempts: settings.attempts,
            timeoutMs: settings.timeoutMs,
            endpoints: endpoints,
            downloadProfile: settings.downloadProfile
        )
    }

    func enabledEndpoints() -> [Endpoint] {
        var endpoints: [Endpoint] = []
        if settings.includeCloudflare {
            endpoints.append(Endpoint(name: "Cloudflare", host: "1.1.1.1", port: 443, scheme: .tcp))
        }
        if settings.includeGoogle {
            endpoints.append(Endpoint(name: "Google", host: "8.8.8.8", port: 443, scheme: .tcp))
        }
        if let custom = parseCustomEndpoint(urlString: settings.customURL) {
            endpoints.append(custom)
        }
        if endpoints.isEmpty {
            endpoints.append(Endpoint(name: "Cloudflare", host: "1.1.1.1", port: 443, scheme: .tcp))
        }
        return endpoints
    }

    func parseCustomEndpoint(urlString: String) -> Endpoint? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme == "https" else {
            return nil
        }
        guard let host = url.host else { return nil }
        let port = url.port ?? 443
        return Endpoint(name: "Custom", host: host, port: port, scheme: .https)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
