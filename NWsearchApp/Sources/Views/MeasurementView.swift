import SwiftUI

struct MeasurementView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @Environment(\.dismiss) private var dismiss

    let onComplete: (TestSession) -> Void

    @State private var progressValue: Double = 0
    @State private var stepText: String = "準備中"
    @State private var detailText: String = ""
    @State private var isRunning = false
    @State private var showCancelAlert = false
    @State private var task: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 24) {
            Text("診断中")
                .font(.title2)
                .bold()

            ProgressView(value: progressValue)
                .progressViewStyle(.linear)

            VStack(spacing: 6) {
                Text(stepText)
                    .font(.headline)
                Text(detailText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                showCancelAlert = true
            } label: {
                Text("キャンセル")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .interactiveDismissDisabled(true)
        .onAppear {
            startMeasurement()
        }
        .alert("中断しますか？", isPresented: $showCancelAlert) {
            Button("中断する", role: .destructive) {
                task?.cancel()
            }
            Button("続ける", role: .cancel) {}
        } message: {
            Text("途中結果は保存されます。")
        }
    }

    private func startMeasurement() {
        guard !isRunning else { return }
        isRunning = true
        let runner = MeasurementRunner()
        let endpoints = settingsStore.enabledEndpoints()
        task = Task {
            let session = await runner.run(
                settings: settingsStore.settings,
                endpoints: endpoints,
                connectionType: networkMonitor.connectionType
            ) { progress in
                Task { @MainActor in
                    stepText = progress.step
                    detailText = progress.detail
                    progressValue = progress.progress
                }
            }
            await MainActor.run {
                onComplete(session)
                dismiss()
            }
        }
    }
}
