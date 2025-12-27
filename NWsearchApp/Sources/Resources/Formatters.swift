import Foundation

enum MetricFormatter {
    static func ms(_ value: Int?) -> String {
        guard let value else { return "—" }
        return "\(value) ms"
    }

    static func percent(_ value: Double) -> String {
        let percentValue = max(0, value) * 100
        return String(format: "%.1f %%", percentValue)
    }

    static func percentOrDash(_ value: Double, hasData: Bool) -> String {
        guard hasData else { return "—" }
        return percent(value)
    }

    static func mbps(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f Mbps", value)
    }
}
