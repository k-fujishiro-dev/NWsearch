import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var sessionStore: SessionStore

    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            Section("計測") {
                Stepper(value: $settingsStore.settings.attempts, in: 5...20, step: 1) {
                    Text("試行回数: \(settingsStore.settings.attempts)")
                }
                Picker("タイムアウト", selection: $settingsStore.settings.timeoutMs) {
                    Text("1.0秒").tag(1000)
                    Text("1.5秒").tag(1500)
                    Text("2.0秒").tag(2000)
                    Text("3.0秒").tag(3000)
                }
                Picker("ダウンロードサイズ", selection: $settingsStore.settings.downloadProfile) {
                    ForEach(DownloadProfile.allCases, id: \.self) { profile in
                        Text(profile.label).tag(profile)
                    }
                }
            }

            Section("宛先") {
                Toggle("Cloudflare (1.1.1.1)", isOn: $settingsStore.settings.includeCloudflare)
                Toggle("Google (8.8.8.8)", isOn: $settingsStore.settings.includeGoogle)
                TextField("カスタムURL (https://)", text: $settingsStore.settings.customURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if settingsStore.parseCustomEndpoint(urlString: settingsStore.settings.customURL) == nil {
                    Text("https:// で始まるURLのみ有効です")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("宛先が0件になる場合はCloudflareが自動で有効になります")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Section("データ") {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Text("履歴全削除")
                }
            }

            Section("情報") {
                NavigationLink("ヘルプ/免責/プライバシー") {
                    HelpView()
                }
                Text("バージョン: 0.1 (MVP)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("設定")
        .alert("履歴を全削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                sessionStore.deleteAll()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }
}
