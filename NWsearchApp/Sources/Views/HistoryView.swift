import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        List {
            if sessionStore.sessions.isEmpty {
                VStack(spacing: 12) {
                    Text("まだ履歴がありません")
                        .font(.headline)
                    Text("診断を開始してください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
            } else {
                ForEach(sessionStore.sessions) { session in
                    NavigationLink {
                        HistoryDetailView(sessionID: session.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(session.summary.verdict.label)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Capsule())
                                Text(DateFormatter.shared.string(from: session.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("中央値: \(MetricFormatter.ms(session.summary.medianMs)) / ロス: \(MetricFormatter.percent(session.summary.lossRate)) / DL: \(MetricFormatter.mbps(session.summary.downMbps))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: sessionStore.delete)
            }
        }
        .listStyle(.plain)
        .navigationTitle("履歴")
    }
}
