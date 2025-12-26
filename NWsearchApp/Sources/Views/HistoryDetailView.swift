import SwiftUI

struct HistoryDetailView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    let sessionID: UUID

    @State private var showShareSheet = false
    @State private var showCSVSheet = false
    @State private var labelText: String = ""

    var body: some View {
        if let session = sessionStore.session(id: sessionID) {
            let previous = sessionStore.previousSession(for: session)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VerdictBadgeView(verdict: session.summary.verdict)

                    if let previous {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("前回との比較")
                                .font(.headline)
                            ComparisonRow(title: "レイテンシ", current: session.summary.medianMs, previous: previous.summary.medianMs, unit: "ms")
                            ComparisonRow(title: "ロス相当", current: session.summary.lossRate, previous: previous.summary.lossRate, unit: "%", scale: 100)
                            ComparisonRow(title: "DL速度", current: session.summary.downMbps, previous: previous.summary.downMbps, unit: "Mbps")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ネットワーク名")
                            .font(.headline)
                        TextField("任意ラベル", text: $labelText)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("指標")
                            .font(.headline)
                        MetricCardView(title: "中央値", value: MetricFormatter.ms(session.summary.medianMs))
                        MetricCardView(title: "ジッター", value: MetricFormatter.ms(session.summary.jitterMs))
                        MetricCardView(title: "ロス相当", value: MetricFormatter.percent(session.summary.lossRate))
                        MetricCardView(title: "DL速度", value: MetricFormatter.mbps(session.summary.downMbps))
                    }

                    NavigationLink("詳細を見る") {
                        DetailView(sessionID: sessionID)
                    }
                    .buttonStyle(.bordered)

                    HStack(spacing: 12) {
                        Button("共有") {
                            showShareSheet = true
                        }
                        .buttonStyle(.borderedProminent)

                        Button("CSVエクスポート") {
                            showCSVSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("履歴詳細")
            .onAppear {
                labelText = session.userNetworkLabel ?? ""
            }
            .onChange(of: labelText) { newValue in
                sessionStore.updateNetworkLabel(sessionID: sessionID, label: newValue)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [ShareBuilder.text(for: session)])
            }
            .sheet(isPresented: $showCSVSheet) {
                let urls = CSVExporter().export(session: session)
                ShareSheet(items: urls)
            }
        } else {
            Text("結果が見つかりません")
        }
    }
}

struct ComparisonRow: View {
    let title: String
    let current: Any?
    let previous: Any?
    let unit: String
    var scale: Double = 1

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(diffText())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func diffText() -> String {
        if let current = current as? Int, let previous = previous as? Int {
            let delta = (Double(current) - Double(previous)) * scale
            return format(delta: delta)
        }
        if let current = current as? Double, let previous = previous as? Double {
            let delta = (current - previous) * scale
            return format(delta: delta)
        }
        return "—"
    }

    private func format(delta: Double) -> String {
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", delta)) \(unit)"
    }
}
