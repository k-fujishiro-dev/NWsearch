import Foundation

struct MeasurementProgress {
    let step: String
    let detail: String
    let progress: Double
}

final class MeasurementRunner {
    // MVPでは外部サーバ不要のためダミー計測を返す（将来の実測置換前提）。
    func run(settings: AppSettings, endpoints: [Endpoint], connectionType: ConnectionType, progress: @escaping (MeasurementProgress) -> Void) async -> TestSession {
        let totalSteps = 5.0
        func update(stepIndex: Double, detail: String, stepProgress: Double) {
            let overall = min(1.0, (stepIndex - 1.0 + stepProgress) / totalSteps)
            progress(MeasurementProgress(step: stepName(for: stepIndex), detail: detail, progress: overall))
        }

        update(stepIndex: 1, detail: "接続状態を確認しています", stepProgress: 1)
        await pause(milliseconds: 120)

        var endpointResults: [EndpointResult] = []
        let attempts = max(1, settings.attempts)
        let totalAttempts = max(1, endpoints.count * attempts)
        var completedAttempts = 0

        for (endpointIndex, endpoint) in endpoints.enumerated() {
            var latencies: [Int] = []
            var failures = 0
            for attemptIndex in 0..<attempts {
                if Task.isCancelled { break }
                let result = simulateLatency(endpointIndex: endpointIndex, attemptIndex: attemptIndex)
                if let result {
                    latencies.append(result)
                } else {
                    failures += 1
                }
                completedAttempts += 1
                let stepProgress = Double(completedAttempts) / Double(totalAttempts)
                update(stepIndex: 2, detail: "レイテンシ計測中", stepProgress: stepProgress)
                await pause(milliseconds: 40)
            }
            let attempted = latencies.count + failures
            let lossRate = attempted > 0 ? Double(failures) / Double(attempted) : 1
            let endpointResult = EndpointResult(
                endpoint: endpoint,
                latenciesMs: latencies,
                failures: failures,
                attempts: attempted,
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
            await pause(milliseconds: 180)
            dnsIndexMs = simulateDnsIndexMs()
            update(stepIndex: 3, detail: "DNS指標を計測中", stepProgress: 1)
        }

        var downMbps: Double? = nil
        if !Task.isCancelled {
            update(stepIndex: 4, detail: "ダウンロード速度を計測中", stepProgress: 0.2)
            await pause(milliseconds: 200)
            downMbps = simulateDownMbps()
            update(stepIndex: 4, detail: "ダウンロード速度を計測中", stepProgress: 1)
        }

        let summary = buildSummary(connectionType: connectionType, endpointResults: endpointResults, dnsIndexMs: dnsIndexMs, downMbps: downMbps)
        update(stepIndex: 5, detail: "診断を作成中", stepProgress: 1)
        await pause(milliseconds: 80)

        return TestSession(
            id: UUID(),
            createdAt: Date(),
            connectionType: connectionType,
            userNetworkLabel: nil,
            settingsSnapshot: SettingsSnapshot(
                attempts: attempts,
                timeoutMs: max(500, settings.timeoutMs),
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

    private func simulateLatency(endpointIndex: Int, attemptIndex: Int) -> Int? {
        if attemptIndex == 0 && endpointIndex == 2 {
            return nil
        }
        let base = 24 + (endpointIndex * 6)
        let jitter = (attemptIndex % 5) * 3
        return base + jitter
    }

    private func simulateDnsIndexMs() -> Int? {
        90
    }

    private func simulateDownMbps() -> Double? {
        120.0
    }

    private func pause(milliseconds: Int) async {
        let nanos = UInt64(milliseconds) * 1_000_000
        try? await Task.sleep(nanoseconds: nanos)
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
