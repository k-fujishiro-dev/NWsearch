import Foundation

struct DownloadTester {
    func measure(url: URL, timeoutMs: Int) async -> Double? {
        let config = URLSessionConfiguration.ephemeral
        let timeout = Double(timeoutMs) / 1000.0
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: config)

        let start = Date()
        do {
            let (data, _) = try await session.data(from: url, delegate: nil)
            let elapsed = Date().timeIntervalSince(start)
            guard elapsed > 0 else { return nil }
            let bits = Double(data.count) * 8.0
            let mbps = (bits / 1_000_000.0) / elapsed
            return mbps
        } catch {
            return nil
        }
    }
}
