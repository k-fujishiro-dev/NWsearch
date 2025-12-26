import Foundation

enum ShareBuilder {
    static func text(for session: TestSession) -> String {
        let date = DateFormatter.shared.string(from: session.createdAt)
        let summary = session.summary
        let lines = [
            "Wi‑Fi診断結果（\(date)）",
            "接続: \(session.connectionType.rawValue)",
            "判定: \(summary.verdict.label)",
            "",
            "レイテンシ(中央値): \(summary.medianMs.map { "\($0) ms" } ?? "—")",
            "ジッター: \(summary.jitterMs.map { "\($0) ms" } ?? "—")",
            "ロス相当: \(MetricFormatter.percent(summary.lossRate))",
            "DL速度: \(summary.downMbps.map { String(format: "%.1f Mbps", $0) } ?? "—")",
            "DNS指標: \(summary.dnsIndexMs.map { "\($0) ms" } ?? "—")",
            "",
            "原因候補:",
            summary.reasons.map { "- \($0.title)" }.joined(separator: "\n"),
            "",
            "おすすめ:",
            summary.actions.map { "- \($0.title)" }.joined(separator: "\n")
        ]
        return lines.joined(separator: "\n")
    }
}

extension DateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
