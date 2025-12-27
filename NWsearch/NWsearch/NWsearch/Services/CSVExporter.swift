import Foundation

struct CSVExporter {
    func export(session: TestSession) -> [URL] {
        let tempDir = FileManager.default.temporaryDirectory
        let summaryURL = tempDir.appendingPathComponent("session_summary.csv")
        let endpointURL = tempDir.appendingPathComponent("endpoint_detail.csv")

        let summaryCSV = buildSummaryCSV(session: session)
        let endpointCSV = buildEndpointCSV(session: session)

        try? summaryCSV.data(using: .utf8)?.write(to: summaryURL, options: [.atomic])
        try? endpointCSV.data(using: .utf8)?.write(to: endpointURL, options: [.atomic])

        return [summaryURL, endpointURL]
    }

    private func buildSummaryCSV(session: TestSession) -> String {
        let summary = session.summary
        let header = "date,connection,verdict,median_ms,jitter_ms,loss_rate,dns_ms,down_mbps\n"
        let row = [
            ISO8601DateFormatter().string(from: session.createdAt),
            session.connectionType.rawValue,
            summary.verdict.rawValue,
            summary.medianMs.map(String.init) ?? "",
            summary.jitterMs.map(String.init) ?? "",
            String(format: "%.4f", summary.lossRate),
            summary.dnsIndexMs.map(String.init) ?? "",
            summary.downMbps.map { String(format: "%.2f", $0) } ?? ""
        ].joined(separator: ",")
        return header + row + "\n"
    }

    private func buildEndpointCSV(session: TestSession) -> String {
        let header = "endpoint,host,port,attempts,failures,loss_rate,median_ms,p95_ms,jitter_ms\n"
        let rows = session.endpointResults.map { result in
            [
                result.endpoint.name,
                result.endpoint.host,
                String(result.endpoint.port),
                String(result.attempts),
                String(result.failures),
                String(format: "%.4f", result.lossRate),
                result.medianMs.map(String.init) ?? "",
                result.p95Ms.map(String.init) ?? "",
                result.jitterMs.map(String.init) ?? ""
            ].joined(separator: ",")
        }
        return header + rows.joined(separator: "\n") + "\n"
    }
}
