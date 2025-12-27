# 要件定義書：宅内Wi‑Fi診断アプリ（iOS / MVP）  
**ファイル**: `wifi-diagnosis-spec.md`  
**目的**: このドキュメントだけ読めば、Codex/開発者がMVPを実装できる粒度まで落とし込む。  
**対象**: iOS（iPhone） / SwiftUI / iOS 17+ 推奨  
**方針**: 位置情報など“強い権限”は要求しない。サーバ不要（端末内保存）。  
**注意**: iOS制約により、SSID/BSSID/RSSIやICMP pingはMVPでは前提にしない（取得できない/審査リスク）。疑似PingはTCP connect timeで代替。  

---

## 0. 用語（本書内の定義）
- **テストセッション**: 1回の「診断開始」から「結果表示」までの計測一式（履歴の1件）
- **エンドポイント**: レイテンシ計測対象（例: `1.1.1.1:443`）
- **疑似Ping**: ICMPではなく、`NWConnection` 等で **TCP接続完了までの時間**をmsで測る
- **ロス相当**: 試行回数に対する接続失敗率（%）
- **DNS指標（MVP）**: “URLSessionで初回接続が確立するまで”の時間（ms）※純DNS分離は将来
- **ダウンロード速度**: 固定サイズファイルDLからMbps算出（参考値）

---

## 1. 背景・目的
家庭内Wi‑Fiの「遅い/途切れる/夜だけ重い」を、  
(1) 数値化 → (2) 状態判定 → (3) 次の手順（改善ガイド）へ最短導線で案内する。  
結果は家族やサポート窓口に共有できる形式にする。

### 成功指標（MVP）
- 1タップで診断開始 → 60秒以内に「判定＋次の一手」まで到達
- 共有は2タップ以内
- 位置情報権限なしで完結
- 失敗しても「途中結果＋次の一手」が出る（真っ白にしない）

---

## 2. スコープ
### 2.1 MVPに含める
- 接続種別（Wi‑Fi / Cellular / none）の判定
- レイテンシ（疑似Ping）、ジッター、ロス相当（失敗率）
- DNS指標（簡易）
- ダウンロード速度（簡易）
- ルールベース診断（Good/Warn/Bad）＋原因候補＋推奨アクション
- 改善ガイド（症状別カード）
- 履歴保存、前回比較
- 共有（ShareSheet）とCSVエクスポート
- 設定（試行回数/タイムアウト/宛先/任意ネットワーク名）

### 2.2 MVPに含めない（将来）
- ICMP ping
- 自動のWi‑Fi電波強度・チャンネル混雑解析
- ルータ機種の自動判別
- 常時バックグラウンド監視
- アップロード速度（サーバ/安定性/審査の工数増）

---

## 3. 非機能要件（MVP）
### 3.1 性能
- デフォルト設定（3宛先×10回、DL 5MB）で **30〜60秒以内**に完了
- UIは常に応答（メインスレッドを塞がない）

### 3.2 信頼性
- ネット不調/宛先ブロックでもクラッシュしない
- 診断途中キャンセルで安全に停止できる
- 失敗が続いても結果画面へ遷移し、原因候補とガイドを提示

### 3.3 プライバシー
- 収集データは端末内保存のみ（MVP）
- 位置情報/連絡先など個人情報権限は不要
- 外部共有はユーザー操作（ShareSheet）のみ

### 3.4 アクセシビリティ
- Dynamic Type
- VoiceOverで主要結果を読み上げられる
- 色だけに依存しない（ラベル/アイコン/文言併用）

---

## 4. データ設計（ローカル）
### 4.1 エンティティ
#### TestSession
- `id: UUID`
- `createdAt: Date`
- `connectionType: enum { wifi, cellular, none }`
- `userNetworkLabel: String?`（任意手入力）
- `settingsSnapshot: SettingsSnapshot`
- `summary: SummaryMetrics`
- `endpointResults: [EndpointResult]`
- `notes: String?`（将来用・MVPは未使用でもOK）

#### SettingsSnapshot
- `attempts: Int`
- `timeoutMs: Int`
- `endpoints: [Endpoint]`
- `downloadProfile: enum { auto, small5MB, large20MB }`

#### Endpoint
- `name: String`（例: Cloudflare / Google / Custom）
- `host: String`（IP or domain）
- `port: Int`（例: 443）
- `scheme: enum { tcp, https }`（MVPは tcp/https）

#### EndpointResult
- `endpoint: Endpoint`
- `latenciesMs: [Int]`（成功試行のみ）
- `failures: Int`
- `attempts: Int`
- `medianMs: Int?`
- `p95Ms: Int?`
- `jitterMs: Int?`（標準偏差 or 平均絶対偏差）
- `lossRate: Double`（0〜1）

#### SummaryMetrics
- `medianMs: Int?`
- `p95Ms: Int?`
- `jitterMs: Int?`
- `lossRate: Double`
- `dnsIndexMs: Int?`
- `downMbps: Double?`
- `verdict: enum { good, warn, bad, unknown }`
- `reasons: [Reason]`（最大3）
- `actions: [ActionItem]`（最大5）

#### Reason
- `code: String`（例: HIGH_LOSS / HIGH_LATENCY / DNS_SLOW / CONGESTION_SUSPECT）
- `title: String`
- `detail: String`

#### ActionItem
- `code: String`（例: REBOOT_ORDER / MOVE_ROUTER / SWITCH_BAND / CHANGE_DNS）
- `title: String`
- `steps: [String]`（改善ガイドへジャンプする要約）
- `priority: Int`（1が最優先）

---

## 5. 計測仕様（MVP）
### 5.1 共通
- タイムアウト（デフォルト）: **1500ms**
- 試行回数（デフォルト）: **10回**
- エンドポイント（デフォルト）:
  1. `1.1.1.1:443`（Cloudflare）
  2. `8.8.8.8:443`（Google）
  3. `https://example.com`（カスタムURL枠の初期値、または `www.apple.com` 等でも可）

### 5.2 レイテンシ（疑似Ping）
- 実装: `NWConnection(host, port, using: .tcp)` で `.ready` までの時間を計測（ms）
- 成功: `.ready` 到達
- 失敗: `.failed` / タイムアウト
- 出力:
  - 各宛先の `latenciesMs`, `failures`, `lossRate`
  - 宛先ごとの `median/p95/jitter`
  - 統合サマリ（宛先ごとの中央値の中央値など、実装しやすい集約でOK）

### 5.3 ジッター
- `latenciesMs` の分散指標
  - 推奨: 標準偏差（ms）
  - 成功試行が少ない場合（<3）は `nil` として扱う

### 5.4 ロス相当（失敗率）
- `failures / attempts`（0〜1）を`%`表示

### 5.5 DNS指標（簡易）
- “名前解決＋TLS接続開始まで”の体感指標として：
  - `URLSession` で軽量URLに対して **最初のレスポンスヘッダ受信まで**の時間（ms）
- 失敗時:
  - `nil` にして「測定不能」と表示（原因候補に反映）

### 5.6 ダウンロード速度（簡易）
- 固定サイズファイルをDLし、`sizeBytes / elapsed` からMbps算出
- 5MB/20MBの自動選択（目安）:
  - 直近レイテンシ良好なら20MB、悪いなら5MB
- 失敗時:
  - `nil` にして「測定不能」

---

## 6. 診断（ルールエンジン / MVP）
### 6.1 判定（Verdict）
- Good:
  - `lossRate < 0.02` かつ `medianMs < 60` かつ `jitterMs < 20`
- Warn:
  - `lossRate in [0.02, 0.08)` または `medianMs in [60,150)` または `jitterMs in [20,60)`
- Bad:
  - `lossRate >= 0.08` または `medianMs >= 150` または `jitterMs >= 60`
- Unknown:
  - サンプル不足/全測定失敗などで主要指標が揃わない

> 数値は初期値。将来、利用データから調整可能にする。

### 6.2 Reason生成（最大3）
優先順位例（上ほど優先）:
1. HIGH_LOSS（loss高い）
2. HIGH_LATENCY（遅延高い）
3. HIGH_JITTER（揺れ大）
4. DNS_SLOW（DNS指標が遅い/失敗）
5. THROUGHPUT_LOW（DL速度が低い）
6. CELLULAR_USED（Wi‑Fiではない）
7. MEASUREMENT_FAILED（測定不能）

### 6.3 ActionItem生成（最大5）
ルール例（上から該当を積む。重複は除外）:
- Wi‑Fiでない → `CHECK_WIFI_ON`（Wi‑Fi接続を促す）
- HIGH_LOSS or HIGH_JITTER → `MOVE_ROUTER`, `SWITCH_BAND`, `MESH_PLACEMENT`
- HIGH_LATENCY → `REBOOT_ORDER`, `MOVE_ROUTER`
- DNS_SLOW → `CHANGE_DNS`, `REBOOT_ORDER`
- THROUGHPUT_LOW → `CHECK_CONGESTION_TIME`, `WIRED_FOR_MEETINGS`
- 測定不能 → `RETRY_NEAR_ROUTER`, `CHECK_ROUTER_STATUS`

---

## 7. UI要件（画面ごと / 実装粒度）

> **共通UI**  
- ナビ: `TabView`（ホーム/履歴/ガイド/設定）＋必要に応じて `NavigationStack`  
- 主要ボタンは下部に配置（親指届きやすい）  
- 結果の状態は色だけに依存せず、**ラベル（良好/注意/要改善）**とアイコンを併用  
- 表示単位: ms, %, Mbps  
- `nil` の値は `—` で表示し、「測定不能」注記を出す  

---

### 7.1 画面：ホーム（診断開始）
**目的**: 1タップで診断開始。現在の接続状態が分かる。  
**ルート**: Tab「ホーム」

#### UIコンポーネント
- ヘッダ
  - タイトル: 「Wi‑Fi診断」
  - サブ: 現在の接続（例: 「Wi‑Fi接続中」/「モバイル通信」/「未接続」）
- カード：クイックサマリ（直近の履歴がある場合）
  - 前回判定バッジ + 主要指標（median/loss/down）
  - 「前回結果を見る」ボタン
- メインボタン
  - Primary: 「診断を開始」
  - Secondary: 「短い診断（30秒）」※将来でもOK。MVPでは省略可
- 注意文（小さめ）
  - 「結果は環境により変動します。参考値です。」

#### 状態・挙動
- Wi‑Fiではない場合：
  - Primary押下で開始は可能（Cellular測定）だが、結果で「Wi‑Fiではない」Reasonを最上位に出す  
  - 実装を簡単にするなら開始前モーダルは無しでOK
- 押下 → 計測中画面へ遷移（即時）

#### アクセシビリティ
- 接続状態をVoiceOverで読めるようにラベル化

---

### 7.2 画面：計測中（進捗）
**目的**: 何を測っているか分かり、キャンセルできる。  
**遷移元**: ホーム「診断を開始」

#### UIコンポーネント
- プログレス表示（割合 or ステップ）
  - ステップ例: 「接続確認 → レイテンシ → DNS → ダウンロード → 診断」
- 現在ステップの説明文（1行）
- メトリクスの簡易ライブ表示（任意）
  - 例: 現在の成功率、直近レイテンシ
- ボタン
  - 「キャンセル」
  - （キャンセル確認ダイアログ）「中断しますか？途中結果は保存されます」

#### 状態・挙動
- バックグラウンドに移った場合：
  - MVPでは中断でもOK（復帰時に中止扱い）  
- 失敗が連続した場合：
  - 画面に「接続が不安定です。続行しています…」を表示
- 完了 → 結果サマリへ遷移

---

### 7.3 画面：結果サマリ（判定＋次の一手）
**目的**: ぱっと見で状態が分かり、次にやるべきことが分かる。  
**遷移元**: 計測中完了 / 履歴詳細からも到達

#### UIコンポーネント
- 上部：判定バッジ（Good/Warn/Bad/Unknown）
  - テキスト: 「良好 / 注意 / 要改善 / 測定不能」
  - サブ: 「会議・動画は(問題なさそう/不安/厳しい)かも」
- 主要指標カード（4つ）
  1. レイテンシ（中央値 ms）
  2. ジッター（ms）
  3. ロス相当（%）
  4. DL速度（Mbps）
- Reasonセクション（最大3）
  - タイトル＋1行説明
- 「おすすめの改善」セクション（最大5）
  - 優先度順のカード（タップでガイドへ）
- アクションボタン列
  - Primary: 「改善手順を見る」
  - Secondary: 「詳細を見る」
  - Icon: 共有（Share）

#### 状態・挙動
- `nil` 指標は `—` 表示＋「測定不能」注記
- Cellular測定の場合：
  - 判定とは別に上部に「Wi‑Fi未接続」注意バナー
- Share押下：
  - 共有テキスト生成 → ShareSheet
- 保存：
  - 画面表示時点でセッションをローカル保存（失敗でも保存）

#### 共有テキストテンプレ（MVP）
```
Wi‑Fi診断結果（{date}）
接続: {wifi/cellular}
判定: {良好/注意/要改善/測定不能}

レイテンシ(中央値): {median} ms
ジッター: {jitter} ms
ロス相当: {loss} %
DL速度: {down} Mbps
DNS指標: {dns} ms

原因候補:
- {reason1}
- {reason2}

おすすめ:
- {action1}
- {action2}
```

---

### 7.4 画面：詳細（指標と宛先別）
**目的**: “どこが悪いか”を深掘りできる。  
**遷移元**: 結果サマリ「詳細を見る」

#### UIコンポーネント
- セッション情報
  - 実施日時 / 接続種別 / 任意ネットワーク名（表示）
- 指標テーブル（統合）
  - median / p95 / jitter / loss / dns / down
- 宛先別結果（リスト）
  - Cloudflare / Google / Custom
  - それぞれ：median, p95, jitter, loss、成功回数/失敗回数
- 失敗ログ（任意）
  - 直近のエラー種別（NWError）を丸めて表示

#### 状態・挙動
- 宛先が1つでも成功していれば詳細を出す
- すべて失敗の場合は「測定不能」説明＋改善ガイドへの導線を出す

---

### 7.5 画面：改善ガイド（一覧）
**目的**: 症状別の“やること”が見つかる。  
**ルート**: Tab「ガイド」 / 結果からの遷移

#### UIコンポーネント
- カテゴリ（セグメント or チップ）
  - 例: 「遅い」「途切れる」「DNS」「設置」「会議向け」
- ガイドカード一覧
  - タイトル / 想定症状（短文）/ 所要時間（例: 3分）
- 結果から来た場合：上部に「あなたのおすすめ」
  - ActionItemに対応するカードを優先表示

#### 状態・挙動
- タップ → ガイド詳細へ

---

### 7.6 画面：改善ガイド詳細（手順カード）
**目的**: その場で実行できるレベルの具体性。  
**遷移元**: ガイド一覧 / 結果サマリのおすすめ

#### UIコンポーネント（カード構造）
- タイトル
- 「何が起きてるか」説明（2〜3行）
- 手順（番号付き 3〜7ステップ）
- 「効果がある理由」（1〜2行）
- 注意点（免責・戻し方）
- CTA
  - Primary: 「今すぐ再診断」
  - Secondary: 「他の手順を見る」

#### MVPカード本文（コピペ可）
- **再起動の正しい順番（REBOOT_ORDER）**
  - 手順: ONU→ルータの順、30秒待つ、復旧後2〜3分待つ、再診断
- **置き場所の見直し（MOVE_ROUTER）**
  - 目安: 床置きNG/棚の奥NG/金属・電子レンジ近く回避/部屋の中心寄り
- **2.4GHz / 5GHz切替（SWITCH_BAND）**
  - 近距離＝5GHz、遠距離/壁多い＝2.4GHz
- **メッシュ/中継器配置（MESH_PLACEMENT）**
  - 親機と子機の中間、子機を奥に置きすぎない
- **DNS変更（CHANGE_DNS）**
  - 一般手順＋「戻し方」注記（機種依存のため詳細リンクは将来）
- **会議PCだけ有線（WIRED_FOR_MEETINGS）**
  - USB‑C→LANで会議の安定度を上げる

---

### 7.7 画面：履歴（一覧）
**目的**: いつ悪化したか、改善したかが分かる。  
**ルート**: Tab「履歴」

#### UIコンポーネント
- 履歴リスト（最新が上）
  - 判定バッジ / 日時 / median・loss・down（小さめ）
- 空状態
  - 「まだ履歴がありません」＋「診断を開始」

#### 状態・挙動
- タップ → 履歴詳細へ
- スワイプ削除（任意）

---

### 7.8 画面：履歴詳細（再表示・比較・共有・CSV）
**目的**: 過去の結果を再確認し、比較できる。  
**遷移元**: 履歴一覧

#### UIコンポーネント
- サマリ（結果サマリと同等）
- 比較セクション（前回と比較）
  - 差分表示（±）と改善/悪化ラベル
- 編集
  - ネットワーク名（任意ラベル）編集（TextField）
- 共有/CSV
  - Share（テキスト）
  - Export CSV（ファイル共有）

#### 状態・挙動
- 比較対象がない場合は非表示
- CSV出力
  - `session_summary.csv`
  - `endpoint_detail.csv`

---

### 7.9 画面：設定
**目的**: 計測条件をユーザーが調整できる（壊れない範囲で）。  
**ルート**: Tab「設定」

#### UIコンポーネント
- 試行回数（Stepper 5〜20）
- タイムアウト（1.0/1.5/2.0/3.0秒）
- 宛先
  - デフォルト宛先ON/OFF
  - カスタムURL（httpsのみ）
- ダウンロードサイズ（自動/5MB/20MB）
- データ
  - 履歴全削除（確認あり）
- 情報
  - 免責/プライバシー/バージョン

#### バリデーション
- 宛先が0件になるのは禁止（最低1つ必須）
- カスタムURLは `https://` 必須、空なら無効化

---

### 7.10 画面：ヘルプ/免責/プライバシー
- FAQ（折りたたみ）
- 免責（参考値、変動、自己責任）
- プライバシー（端末内、位置情報なし、共有は任意）

---

## 8. エラー設計（表示ルール）
- 未接続/Cellular: “状態”として明示し、Wi‑Fi接続を促すガイドへ
- 計測不能: Unknownで結果画面に到達し、「ルータ近くで再試行」を最優先アクションに
- DL失敗: downは`—`、他指標で判定は継続

---

## 9. 受け入れ条件（再掲）
- ホーム→診断→結果（成功/失敗問わず）まで到達
- UIフリーズなし
- 履歴永続化
- ShareSheet動作
- 位置情報権限なし
- 設定の変更が反映される

---

## 10. Codexに最初に投げる指示文（コピペ）
> この `wifi-diagnosis-spec.md` に従ってSwiftUIでiOSアプリを実装してください。  
> MVPとして「ホーム→計測→結果サマリ→履歴保存→履歴一覧→履歴詳細→共有→CSVエクスポート」まで動く最短構成を作ってください。  
> 疑似Pingは `NWConnection` のTCP connect timeで実装し、ICMPは使わないでください。  
> 位置情報権限は要求しないでください。  

