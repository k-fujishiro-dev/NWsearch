import Foundation
import Network

struct MeasurementProgress {
    let step: String
    let detail: String
    let progress: Double
}

final class MeasurementRunner {
    private let dnsProbe = DNSProbe()
    private let downloadTester = DownloadTester()

    func run(settings: AppSettings, endpoints: [Endpoint], connectionType: ConnectionType, progress: @escaping (MeasurementProgress) -> Void) async -> TestSession {
        let totalSteps = 5.0
        func update(stepIndex: Double, detail: String, stepProgress: Double) {
            let overall = min(1.0, (stepIndex - 1.0 + stepProgress) / totalSteps)
            progress(MeasurementProgress(step: stepName(for: stepIndex), detail: detail, progress: overall))
        }

        update(stepIndex: 1, detail: "接続状態を確認しています", stepProgress: 1)

        var endpointResults: [EndpointResult] = []
        let attempts = max(1, settings.attempts)
        let timeoutMs = max(500, settings.timeoutMs)
        let totalAttempts = max(1, endpoints.count * attempts)
        var completedAttempts = 0

        for endpoint in endpoints {
            var latencies: [Int] = []
            var failures = 0
            for _ in 0..<attempts {
                if Task.isCancelled { break }
                let result = await measureTcpLatency(host: endpoint.host, port: endpoint.port, timeoutMs: timeoutMs)
                if let result {
                    latencies.append(result)
                } else {
                    failures += 1
                }
                completedAttempts += 1
                let stepProgress = Double(completedAttempts) / Double(totalAttempts)
                update(stepIndex: 2, detail: "レイテンシ計測中", stepProgress: stepProgress)
            }
            let lossRate = Double(failures) / Double(attempts)
            let endpointResult = EndpointResult(
                endpoint: endpoint,
                latenciesMs: latencies,
                failures: failures,
                attempts: attempts,
                medianMs: median(latencies),
                p95Ms: percentile(latencies, percentile: 95),
                jitterMs: standardDeviation(latencies),
                lossRate: lossRate
            )
            endpointResults.append(endpointResult)
        }

        var dnsIndexMs: Int? = nil
        if !Task.isCancelled {
            update(stepIndex: 3, detail: "DNS指標を計測中", stepProgress: 0.3)
            if let url = dnsProbeURL(from: settings, endpoints: endpoints) {
                dnsIndexMs = await dnsProbe.measure(url: url, timeoutMs: timeoutMs)
            }
            update(stepIndex: 3, detail: "DNS指標を計測中", stepProgress: 1)
        }

        var downMbps: Double? = nil
        if !Task.isCancelled {
            update(stepIndex: 4, detail: "ダウンロード速度を計測中", stepProgress: 0.2)
            if let url = downloadURL(settings: settings, endpointResults: endpointResults) {
                downMbps = await downloadTester.measure(url: url, timeoutMs: timeoutMs)
            }
            update(stepIndex: 4, detail: "ダウンロード速度を計測中", stepProgress: 1)
        }

        let summary = buildSummary(connectionType: connectionType, endpointResults: endpointResults, dnsIndexMs: dnsIndexMs, downMbps: downMbps)
        update(stepIndex: 5, detail: "診断を作成中", stepProgress: 1)

        return TestSession(
            id: UUID(),
            createdAt: Date(),
            connectionType: connectionType,
            userNetworkLabel: nil,
            settingsSnapshot: SettingsSnapshot(
                attempts: attempts,
                timeoutMs: timeoutMs,
                endpoints: endpoints,
                downloadProfile: settings.downloadProfile
            ),
            summary: summary,
            endpointResults: endpointResults,
            notes: nil
        )
    }

    private func stepName(for index: Double) -> String {
        switch index {
        case 1: return "接続確認"
        case 2: return "レイテンシ"
        case 3: return "DNS"
        case 4: return "ダウンロード"
        default: return "診断"
        }
    }

    private func measureTcpLatency(host: String, port: Int, timeoutMs: Int) async -> Int? {
        await withCheckedContinuation { continuation in
            let nwHost = NWEndpoint.Host(host)
            guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
                continuation.resume(returning: nil)
                return
            }
            let connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)
            let queue = DispatchQueue(label: "tcp-latency")
            let start = DispatchTime.now()

            var finished = false
            func finish(_ value: Int?) {
                guard !finished else { return }
                finished = true
                connection.cancel()
                continuation.resume(returning: value)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
                    finish(Int(elapsed / 1_000_000))
                case .failed:
                    finish(nil)
                default:
                    break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
                finish(nil)
            }
        }
    }

    private func dnsProbeURL(from settings: AppSettings, endpoints: [Endpoint]) -> URL? {
        if let custom = URL(string: settings.customURL), custom.scheme == "https" {
            return custom
        }
        if let httpsEndpoint = endpoints.first(where: { $0.scheme == .https }) {
            return URL(string: "https://\(httpsEndpoint.host)")
        }
        return URL(string: "https://example.com")
    }

    private func downloadURL(settings: AppSettings, endpointResults: [EndpointResult]) -> URL? {
        let smallURL = URL(string: "https://speed.hetzner.de/5MB.bin")
        let largeURL = URL(string: "https://speed.hetzner.de/20MB.bin")

        switch settings.downloadProfile {
        case .small5MB:
            return smallURL
        case .large20MB:
            return largeURL
        case .auto:
            let medians = endpointResults.compactMap { $0.medianMs }
            let jitter = endpointResults.compactMap { $0.jitterMs }
            let totalFailures = endpointResults.reduce(0) { $0 + $1.failures }
            let totalAttempts = endpointResults.reduce(0) { $0 + $1.attempts }
            let lossRate = totalAttempts > 0 ? Double(totalFailures) / Double(totalAttempts) : 1
            let isGood = (median(medians) ?? 999) < RulesEngine.goodMedianMs && (median(jitter) ?? 999) < RulesEngine.goodJitterMs && lossRate < RulesEngine.goodLoss
            return isGood ? largeURL : smallURL
        }
    }

    private func buildSummary(connectionType: ConnectionType, endpointResults: [EndpointResult], dnsIndexMs: Int?, downMbps: Double?) -> SummaryMetrics {
        let endpointMedians = endpointResults.compactMap { $0.medianMs }
        let endpointP95 = endpointResults.compactMap { $0.p95Ms }
        let endpointJitter = endpointResults.compactMap { $0.jitterMs }
        let totalFailures = endpointResults.reduce(0) { $0 + $1.failures }
        let totalAttempts = endpointResults.reduce(0) { $0 + $1.attempts }
        let lossRate = totalAttempts > 0 ? Double(totalFailures) / Double(totalAttempts) : 1

        var summary = SummaryMetrics(
            medianMs: median(endpointMedians),
            p95Ms: median(endpointP95),
            jitterMs: median(endpointJitter),
            lossRate: lossRate,
            dnsIndexMs: dnsIndexMs,
            downMbps: downMbps,
            verdict: .unknown,
            reasons: [],
            actions: []
        )

        summary.verdict = RulesEngine.verdict(medianMs: summary.medianMs, jitterMs: summary.jitterMs, lossRate: summary.lossRate)
        summary.reasons = RulesEngine.reasons(connectionType: connectionType, summary: summary, endpointResults: endpointResults)
        summary.actions = RulesEngine.actions(connectionType: connectionType, reasons: summary.reasons)
        return summary
    }
}
