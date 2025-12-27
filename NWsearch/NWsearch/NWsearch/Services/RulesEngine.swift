import Foundation

struct RulesEngine {
    static let goodLoss: Double = 0.02
    static let warnLoss: Double = 0.08
    static let goodMedianMs = 60
    static let warnMedianMs = 150
    static let goodJitterMs = 20
    static let warnJitterMs = 60

    static let dnsSlowMs = 300
    static let throughputLowMbps = 20.0

    static func verdict(medianMs: Int?, jitterMs: Int?, lossRate: Double) -> Verdict {
        guard let medianMs, let jitterMs else { return .unknown }
        if lossRate < goodLoss && medianMs < goodMedianMs && jitterMs < goodJitterMs {
            return .good
        }
        if lossRate >= warnLoss || medianMs >= warnMedianMs || jitterMs >= warnJitterMs {
            return .bad
        }
        return .warn
    }

    static func reasons(connectionType: ConnectionType, summary: SummaryMetrics, endpointResults: [EndpointResult]) -> [Reason] {
        var output: [Reason] = []
        let allFailed = endpointResults.allSatisfy { $0.latenciesMs.isEmpty }

        if summary.lossRate >= warnLoss {
            output.append(Reason(code: "HIGH_LOSS", title: "ロスが高い", detail: "接続失敗が多く発生しています。"))
        }
        if let median = summary.medianMs, median >= warnMedianMs {
            output.append(Reason(code: "HIGH_LATENCY", title: "遅延が高い", detail: "応答までの時間が長めです。"))
        }
        if let jitter = summary.jitterMs, jitter >= warnJitterMs {
            output.append(Reason(code: "HIGH_JITTER", title: "揺れが大きい", detail: "通信品質が安定していません。"))
        }
        if let dns = summary.dnsIndexMs {
            if dns >= dnsSlowMs {
                output.append(Reason(code: "DNS_SLOW", title: "DNSが遅い", detail: "名前解決や接続開始が遅めです。"))
            }
        } else {
            output.append(Reason(code: "DNS_SLOW", title: "DNS測定不能", detail: "DNS指標が取得できませんでした。"))
        }
        if let down = summary.downMbps, down < throughputLowMbps {
            output.append(Reason(code: "THROUGHPUT_LOW", title: "速度が低い", detail: "ダウンロード速度が低めです。"))
        }
        if connectionType != .wifi {
            output.append(Reason(code: "CELLULAR_USED", title: "Wi‑Fi未接続", detail: "Wi‑Fi以外での測定です。"))
        }
        if allFailed || summary.verdict == .unknown {
            output.append(Reason(code: "MEASUREMENT_FAILED", title: "測定不能", detail: "十分なデータが取得できませんでした。"))
        }

        let priorityCodes = ["HIGH_LOSS", "HIGH_LATENCY", "HIGH_JITTER", "DNS_SLOW", "THROUGHPUT_LOW", "CELLULAR_USED", "MEASUREMENT_FAILED"]
        let sorted = output.sorted { a, b in
            (priorityCodes.firstIndex(of: a.code) ?? 999) < (priorityCodes.firstIndex(of: b.code) ?? 999)
        }
        return Array(sorted.prefix(3))
    }

    static func actions(connectionType: ConnectionType, reasons: [Reason]) -> [ActionItem] {
        var items: [ActionItem] = []

        func add(_ item: ActionItem) {
            if items.contains(where: { $0.code == item.code }) { return }
            items.append(item)
        }

        if connectionType != .wifi {
            add(action(for: "CHECK_WIFI_ON"))
        }
        if reasons.contains(where: { $0.code == "HIGH_LOSS" || $0.code == "HIGH_JITTER" }) {
            add(action(for: "MOVE_ROUTER"))
            add(action(for: "SWITCH_BAND"))
            add(action(for: "MESH_PLACEMENT"))
        }
        if reasons.contains(where: { $0.code == "HIGH_LATENCY" }) {
            add(action(for: "REBOOT_ORDER"))
            add(action(for: "MOVE_ROUTER"))
        }
        if reasons.contains(where: { $0.code == "DNS_SLOW" }) {
            add(action(for: "CHANGE_DNS"))
            add(action(for: "REBOOT_ORDER"))
        }
        if reasons.contains(where: { $0.code == "THROUGHPUT_LOW" }) {
            add(action(for: "CHECK_CONGESTION_TIME"))
            add(action(for: "WIRED_FOR_MEETINGS"))
        }
        if reasons.contains(where: { $0.code == "MEASUREMENT_FAILED" }) {
            add(action(for: "RETRY_NEAR_ROUTER"))
            add(action(for: "CHECK_ROUTER_STATUS"))
        }

        return Array(items.sorted { $0.priority < $1.priority }.prefix(5))
    }

    static func action(for code: String) -> ActionItem {
        switch code {
        case "CHECK_WIFI_ON":
            return ActionItem(code: code, title: "Wi‑Fi接続を確認", steps: ["Wi‑Fiをオンにする", "正しいSSIDに接続", "再診断"], priority: 1)
        case "MOVE_ROUTER":
            return ActionItem(code: code, title: "置き場所の見直し", steps: ["床置きを避ける", "棚の奥を避ける", "部屋の中央寄りへ移動"], priority: 2)
        case "SWITCH_BAND":
            return ActionItem(code: code, title: "2.4GHz/5GHz切替", steps: ["近距離は5GHz", "遠距離/壁が多い場合は2.4GHz"], priority: 3)
        case "MESH_PLACEMENT":
            return ActionItem(code: code, title: "メッシュ/中継器配置", steps: ["親機と子機の中間に配置", "子機を奥に置きすぎない"], priority: 4)
        case "REBOOT_ORDER":
            return ActionItem(code: code, title: "再起動の正しい順番", steps: ["ONU→ルータの順で電源OFF", "30秒待機", "電源ON後2〜3分待つ"], priority: 1)
        case "CHANGE_DNS":
            return ActionItem(code: code, title: "DNS変更", steps: ["DNS設定を変更", "必要なら元に戻す方法を確認"], priority: 2)
        case "CHECK_CONGESTION_TIME":
            return ActionItem(code: code, title: "混雑時間の確認", steps: ["夜間など混雑時間帯を避ける", "再診断で比較"], priority: 3)
        case "WIRED_FOR_MEETINGS":
            return ActionItem(code: code, title: "会議PCは有線", steps: ["USB‑C→LANを使用", "会議中は有線に切替"], priority: 4)
        case "RETRY_NEAR_ROUTER":
            return ActionItem(code: code, title: "ルータ近くで再試行", steps: ["ルータの近くに移動", "再診断"], priority: 1)
        case "CHECK_ROUTER_STATUS":
            return ActionItem(code: code, title: "ルータの状態確認", steps: ["ランプ状態を確認", "必要なら再起動"], priority: 2)
        default:
            return ActionItem(code: code, title: "対処", steps: ["状況を確認"], priority: 5)
        }
    }
}
