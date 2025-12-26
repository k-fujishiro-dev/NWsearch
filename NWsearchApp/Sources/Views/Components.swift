import SwiftUI

struct VerdictBadgeView: View {
    let verdict: Verdict

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: 2) {
                Text(verdict.label)
                    .font(.headline)
                Text(verdict.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("判定 \(verdict.label)")
    }

    private var color: Color {
        switch verdict {
        case .good: return .green
        case .warn: return .orange
        case .bad: return .red
        case .unknown: return .gray
        }
    }

    private var iconName: String {
        switch verdict {
        case .good: return "checkmark.seal"
        case .warn: return "exclamationmark.triangle"
        case .bad: return "xmark.octagon"
        case .unknown: return "questionmark.circle"
        }
    }
}

struct MetricCardView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ReasonRowView: View {
    let reason: Reason

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reason.title)
                .font(.subheadline)
                .bold()
            Text(reason.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ActionCardView: View {
    let item: ActionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.subheadline)
                .bold()
            ForEach(item.steps, id: \.self) { step in
                Text("• \(step)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct BannerView: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(text)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
