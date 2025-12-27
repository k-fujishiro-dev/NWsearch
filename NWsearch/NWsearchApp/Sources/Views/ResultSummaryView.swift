import SwiftUI

struct ResultSummaryView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var showShareSheet = false

    let sessionID: UUID

    var body: some View {
        if let session = sessionStore.session(id: sessionID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VerdictBadgeView(verdict: session.summary.verdict)

                    if session.connectionType != .wifi {
                        BannerView(text: "Wi‑Fi未接続での測定です", systemImage: "wifi.slash")
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCardView(title: "レイテンシ", value: MetricFormatter.ms(session.summary.medianMs))
                        MetricCardView(title: "ジッター", value: MetricFormatter.ms(session.summary.jitterMs))
                        MetricCardView(title: "ロス相当", value: MetricFormatter.percent(session.summary.lossRate))
                        MetricCardView(title: "DL速度", value: MetricFormatter.mbps(session.summary.downMbps))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("原因候補")
                            .font(.headline)
                        ForEach(session.summary.reasons, id: \.code) { reason in
                            ReasonRowView(reason: reason)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("おすすめの改善")
                            .font(.headline)
                        ForEach(session.summary.actions) { item in
                            NavigationLink {
                                if let card = GuideData.card(for: item.code) {
                                    GuideDetailView(card: card)
                                } else {
                                    GuideDetailView(card: GuideData.cards.first!)
                                }
                            } label: {
                                ActionCardView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 12) {
                        NavigationLink("改善手順を見る") {
                            GuideListView(recommendedCodes: session.summary.actions.map { $0.code })
                        }
                        .buttonStyle(.borderedProminent)

                        NavigationLink("詳細を見る") {
                            DetailView(sessionID: sessionID)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("結果サマリ")
            .toolbar {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [ShareBuilder.text(for: session)])
            }
        } else {
            Text("結果が見つかりません")
        }
    }
}
