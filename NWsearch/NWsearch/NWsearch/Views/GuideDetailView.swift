import SwiftUI

struct GuideDetailView: View {
    let card: GuideCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(card.title)
                    .font(.title2)
                    .bold()

                Text("何が起きてるか")
                    .font(.headline)
                Text(card.symptom)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("手順")
                    .font(.headline)
                ForEach(card.steps.indices, id: \.self) { index in
                    Text("\(index + 1). \(card.steps[index])")
                        .font(.subheadline)
                }

                Text("効果がある理由")
                    .font(.headline)
                Text(card.reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("注意点")
                    .font(.headline)
                Text(card.caution)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    NavigationLink("今すぐ再診断") {
                        HomeView()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("他の手順を見る") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("ガイド")
    }
}
