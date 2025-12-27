# NWsearch iOS MVP

このフォルダには、要件定義書に基づくSwiftUIアプリの実装一式（ソースコード）を配置しています。
Xcodeプロジェクトは含めていないため、以下の手順で作成してください。

## セットアップ手順
1. Xcodeで「App」テンプレートを作成（iOS / SwiftUI / iOS 17+）。
2. 作成したプロジェクトの`<ProjectName>`グループに、`NWsearchApp/Sources`配下の`.swift`をすべて追加。
3. `NWsearchApp.swift`をAppエントリとして使用。
4. 実機またはシミュレータでビルド。

## 既知の前提
- 疑似Pingは`NWConnection`のTCP接続完了時間で算出しています。
- DNS指標は`URLSession`のレスポンスヘッダ受信までの時間です。
- ダウンロード計測は外部URL（Hetznerの固定サイズファイル）に依存します。

## 構成
- `Sources/Models.swift`: データモデル
- `Sources/Services`: 計測・保存・ルールエンジン
- `Sources/Views`: 画面/UI
- `Sources/Resources`: ガイドデータ、フォーマッタ
