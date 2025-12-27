import SwiftUI

struct HelpView: View {
    @State private var showFAQ = false

    var body: some View {
        List {
            Section("FAQ") {
                DisclosureGroup("測定値が変動するのはなぜ？", isExpanded: $showFAQ) {
                    Text("電波状況や時間帯の混雑により数値が変動します。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("免責") {
                Text("測定結果は参考値です。通信環境により変動します。")
                    .font(.footnote)
            }

            Section("プライバシー") {
                Text("データは端末内に保存され、位置情報は取得しません。共有はユーザー操作のみです。")
                    .font(.footnote)
            }
        }
        .navigationTitle("ヘルプ")
    }
}
