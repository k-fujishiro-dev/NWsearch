import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @State private var showMeasurement = false
    @State private var showResult = false
    @State private var latestSessionID: UUID?

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Wi‑Fi診断")
                    .font(.largeTitle)
                    .bold()
                Text(networkMonitor.connectionType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let latest = sessionStore.sessions.first {
                VStack(alignment: .leading, spacing: 12) {
                    Text("前回の結果")
                        .font(.headline)
                    VerdictBadgeView(verdict: latest.summary.verdict)
                    HStack(spacing: 12) {
                        MetricCardView(title: "中央値", value: MetricFormatter.ms(latest.summary.medianMs))
                        MetricCardView(title: "ロス", value: MetricFormatter.percent(latest.summary.lossRate))
                        MetricCardView(title: "DL", value: MetricFormatter.mbps(latest.summary.downMbps))
                    }
                    NavigationLink("前回結果を見る") {
                        ResultSummaryView(sessionID: latest.id)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Spacer()

            Button {
                showMeasurement = true
            } label: {
                Text("診断を開始")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Text("結果は環境により変動します。参考値です。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(isPresented: $showMeasurement) {
            MeasurementView { session in
                sessionStore.add(session)
                latestSessionID = session.id
                showMeasurement = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showResult = true
                }
            }
        }
        .navigationDestination(isPresented: $showResult) {
            if let id = latestSessionID {
                ResultSummaryView(sessionID: id)
            }
        }
    }
}
