import Foundation

enum GuideData {
    static let cards: [GuideCard] = [
        GuideCard(
            code: "REBOOT_ORDER",
            category: "遅い",
            title: "再起動の正しい順番",
            symptom: "速度低下・不安定",
            duration: "3分",
            steps: ["ONU→ルータの順で電源OFF", "30秒待つ", "電源ON後2〜3分待つ", "再診断"],
            reason: "セッションが再確立され安定化することがあります。",
            caution: "作業中の通信は切断されます。"
        ),
        GuideCard(
            code: "MOVE_ROUTER",
            category: "設置",
            title: "置き場所の見直し",
            symptom: "遅い・途切れる",
            duration: "5分",
            steps: ["床置きを避ける", "棚の奥を避ける", "金属・電子レンジ近くを避ける", "部屋の中心寄りに移動"],
            reason: "遮蔽物や干渉源を避けることで電波が改善します。",
            caution: "固定具がある場合は安全に配線してください。"
        ),
        GuideCard(
            code: "SWITCH_BAND",
            category: "遅い",
            title: "2.4GHz / 5GHz切替",
            symptom: "距離や壁が多い",
            duration: "2分",
            steps: ["近距離は5GHz", "遠距離/壁が多い場合は2.4GHz"],
            reason: "周波数特性により最適帯域が異なります。",
            caution: "SSIDが分かれている場合は接続先を確認してください。"
        ),
        GuideCard(
            code: "MESH_PLACEMENT",
            category: "設置",
            title: "メッシュ/中継器配置",
            symptom: "家の奥が弱い",
            duration: "10分",
            steps: ["親機と子機の中間に配置", "子機を奥に置きすぎない"],
            reason: "中継の品質が改善します。",
            caution: "再起動が必要な場合があります。"
        ),
        GuideCard(
            code: "CHANGE_DNS",
            category: "DNS",
            title: "DNS変更",
            symptom: "Web表示が遅い",
            duration: "5分",
            steps: ["DNS設定を変更", "必要なら元に戻す方法を確認"],
            reason: "名前解決の遅延が改善する場合があります。",
            caution: "機種により設定画面が異なります。"
        ),
        GuideCard(
            code: "WIRED_FOR_MEETINGS",
            category: "会議向け",
            title: "会議PCだけ有線",
            symptom: "会議で途切れる",
            duration: "3分",
            steps: ["USB‑C→LANを使用", "会議中は有線に切替"],
            reason: "無線の揺れを避け安定性が上がります。",
            caution: "有線アダプタの準備が必要です。"
        ),
        GuideCard(
            code: "CHECK_WIFI_ON",
            category: "途切れる",
            title: "Wi‑Fi接続の確認",
            symptom: "Wi‑Fi未接続",
            duration: "1分",
            steps: ["Wi‑Fiをオンにする", "正しいSSIDに接続", "再診断"],
            reason: "Wi‑Fi接続が前提の診断です。",
            caution: "モバイル通信の通信量に注意してください。"
        ),
        GuideCard(
            code: "CHECK_CONGESTION_TIME",
            category: "遅い",
            title: "混雑時間の確認",
            symptom: "夜だけ遅い",
            duration: "2分",
            steps: ["混雑時間帯を避ける", "時間帯を変えて再診断"],
            reason: "回線共有による混雑の影響を受けます。",
            caution: "根本対策が必要な場合があります。"
        ),
        GuideCard(
            code: "RETRY_NEAR_ROUTER",
            category: "途切れる",
            title: "ルータ近くで再試行",
            symptom: "測定不能",
            duration: "2分",
            steps: ["ルータ近くに移動", "再診断"],
            reason: "電波状況を確認するための手順です。",
            caution: "改善しない場合は故障の可能性があります。"
        ),
        GuideCard(
            code: "CHECK_ROUTER_STATUS",
            category: "途切れる",
            title: "ルータの状態確認",
            symptom: "測定不能",
            duration: "3分",
            steps: ["ランプ状態を確認", "必要なら再起動"],
            reason: "一時的な不調を解消できます。",
            caution: "作業中の通信は切断されます。"
        )
    ]

    static let categories: [String] = ["すべて", "遅い", "途切れる", "DNS", "設置", "会議向け"]

    static func card(for code: String) -> GuideCard? {
        cards.first { $0.code == code }
    }
}
