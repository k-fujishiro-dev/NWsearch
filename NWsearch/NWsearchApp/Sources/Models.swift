import Foundation

enum ConnectionType: String, Codable, CaseIterable {
    case wifi
    case cellular
    case none

    var displayName: String {
        switch self {
        case .wifi: return "Wi‑Fi接続中"
        case .cellular: return "モバイル通信"
        case .none: return "未接続"
        }
    }
}

enum Verdict: String, Codable {
    case good
    case warn
    case bad
    case unknown

    var label: String {
        switch self {
        case .good: return "良好"
        case .warn: return "注意"
        case .bad: return "要改善"
        case .unknown: return "測定不能"
        }
    }

    var descriptionText: String {
        switch self {
        case .good: return "会議・動画は問題なさそう"
        case .warn: return "会議・動画は不安かも"
        case .bad: return "会議・動画は厳しいかも"
        case .unknown: return "状況の確認が必要"
        }
    }
}

enum EndpointScheme: String, Codable {
    case tcp
    case https
}

enum DownloadProfile: String, Codable, CaseIterable {
    case auto
    case small5MB
    case large20MB

    var label: String {
        switch self {
        case .auto: return "自動"
        case .small5MB: return "5MB"
        case .large20MB: return "20MB"
        }
    }
}

struct Endpoint: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var host: String
    var port: Int
    var scheme: EndpointScheme
}

struct EndpointResult: Codable, Hashable {
    var endpoint: Endpoint
    var latenciesMs: [Int]
    var failures: Int
    var attempts: Int
    var medianMs: Int?
    var p95Ms: Int?
    var jitterMs: Int?
    var lossRate: Double
}

struct SettingsSnapshot: Codable, Hashable {
    var attempts: Int
    var timeoutMs: Int
    var endpoints: [Endpoint]
    var downloadProfile: DownloadProfile
}

struct Reason: Codable, Hashable {
    var code: String
    var title: String
    var detail: String
}

struct ActionItem: Codable, Hashable, Identifiable {
    var id: String { code }
    var code: String
    var title: String
    var steps: [String]
    var priority: Int
}

struct SummaryMetrics: Codable, Hashable {
    var medianMs: Int?
    var p95Ms: Int?
    var jitterMs: Int?
    var lossRate: Double
    var dnsIndexMs: Int?
    var downMbps: Double?
    var verdict: Verdict
    var reasons: [Reason]
    var actions: [ActionItem]
}

struct TestSession: Identifiable, Codable, Hashable {
    var id: UUID
    var createdAt: Date
    var connectionType: ConnectionType
    var userNetworkLabel: String?
    var settingsSnapshot: SettingsSnapshot
    var summary: SummaryMetrics
    var endpointResults: [EndpointResult]
    var notes: String?
}

struct AppSettings: Codable, Hashable {
    var attempts: Int
    var timeoutMs: Int
    var downloadProfile: DownloadProfile
    var includeCloudflare: Bool
    var includeGoogle: Bool
    var customURL: String

    static let `default` = AppSettings(
        attempts: 10,
        timeoutMs: 1500,
        downloadProfile: .auto,
        includeCloudflare: true,
        includeGoogle: true,
        customURL: "https://example.com"
    )
}

struct GuideCard: Identifiable, Hashable {
    var id: String { code }
    var code: String
    var category: String
    var title: String
    var symptom: String
    var duration: String
    var steps: [String]
    var reason: String
    var caution: String
}

func median(_ values: [Int]) -> Int? {
    guard !values.isEmpty else { return nil }
    let sorted = values.sorted()
    let mid = sorted.count / 2
    if sorted.count % 2 == 0 {
        return Int((sorted[mid - 1] + sorted[mid]) / 2)
    }
    return sorted[mid]
}

func percentile(_ values: [Int], percentile: Double) -> Int? {
    guard !values.isEmpty else { return nil }
    let sorted = values.sorted()
    let rank = Int(ceil((percentile / 100.0) * Double(sorted.count))) - 1
    let index = max(0, min(sorted.count - 1, rank))
    return sorted[index]
}

func standardDeviation(_ values: [Int]) -> Int? {
    guard values.count >= 3 else { return nil }
    let mean = Double(values.reduce(0, +)) / Double(values.count)
    let variance = values.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(values.count)
    return Int(sqrt(variance).rounded())
}
