import SwiftUI

struct GuideListView: View {
    let recommendedCodes: [String]
    @State private var selectedCategory: String = "すべて"

    private var filteredCards: [GuideCard] {
        if selectedCategory == "すべて" {
            return GuideData.cards
        }
        return GuideData.cards.filter { $0.category == selectedCategory }
    }

    var body: some View {
        List {
            if !recommendedCodes.isEmpty {
                Section("あなたのおすすめ") {
                    ForEach(recommendedCards()) { card in
                        NavigationLink {
                            GuideDetailView(card: card)
                        } label: {
                            GuideRow(card: card)
                        }
                    }
                }
            }

            Section("ガイド一覧") {
                ForEach(filteredCards) { card in
                    NavigationLink {
                        GuideDetailView(card: card)
                    } label: {
                        GuideRow(card: card)
                    }
                }
            }
        }
        .navigationTitle("改善ガイド")
        .toolbar {
            Picker("カテゴリ", selection: $selectedCategory) {
                ForEach(GuideData.categories, id: \.self) { category in
                    Text(category)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func recommendedCards() -> [GuideCard] {
        let items = recommendedCodes.compactMap { GuideData.card(for: $0) }
        return items.isEmpty ? [] : items
    }
}

struct GuideRow: View {
    let card: GuideCard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.title)
                .font(.headline)
            Text(card.symptom)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("所要時間: \(card.duration)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
