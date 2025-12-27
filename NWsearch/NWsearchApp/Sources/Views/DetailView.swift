import SwiftUI

struct DetailView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    let sessionID: UUID

    var body: some View {
        if let session = sessionStore.session(id: sessionID) {
            List {
                Section("セッション情報") {
                    LabeledContent("実施日時", value: DateFormatter.shared.string(from: session.createdAt))
                    LabeledContent("接続種別", value: session.connectionType.rawValue)
                    LabeledContent("ネットワーク名", value: session.userNetworkLabel ?? "—")
                }

                Section("指標") {
                    LabeledContent("中央値", value: MetricFormatter.ms(session.summary.medianMs))
                    LabeledContent("P95", value: MetricFormatter.ms(session.summary.p95Ms))
                    LabeledContent("ジッター", value: MetricFormatter.ms(session.summary.jitterMs))
                    LabeledContent("ロス相当", value: MetricFormatter.percent(session.summary.lossRate))
                    LabeledContent("DNS指標", value: MetricFormatter.ms(session.summary.dnsIndexMs))
                    LabeledContent("DL速度", value: MetricFormatter.mbps(session.summary.downMbps))
                }

                Section("宛先別結果") {
                    ForEach(session.endpointResults, id: \.endpoint.id) { result in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(result.endpoint.name)
                                .font(.headline)
                            Text("median: \(MetricFormatter.ms(result.medianMs)) / p95: \(MetricFormatter.ms(result.p95Ms)) / jitter: \(MetricFormatter.ms(result.jitterMs))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("成功: \(result.latenciesMs.count) / 失敗: \(result.failures)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("詳細")
        } else {
            Text("結果が見つかりません")
        }
    }
}
