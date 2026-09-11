# iOS モノレポ

複数の iOS アプリと、それらが共有する Swift Package を 1 つのリポジトリで管理します。

## ディレクトリ構成

```
Apps/                 アプリごとに 1 ディレクトリ（.xcodeproj はここに置く）
  UTCJST/             UTC と JST を表示するだけのアプリ
Packages/             アプリ間で共有する Swift Package
  ClockCore/          タイムゾーンの定義と時刻フォーマット（ロジック + テスト）
docs/                 運用メモ
Makefile              ビルド / テストのショートカット
```

アプリ本体（SwiftUI の画面）は `Apps/` に、テストしたいロジックは `Packages/` に置く、
という分け方にしています。ロジックがパッケージ側にあると `swift test` だけで
シミュレータを起動せずに検証でき、2 本目以降のアプリからも再利用できます。

## 必要なもの

- Xcode 16 以降（プロジェクト形式が objectVersion 77 のため）
- iOS 17 以降のシミュレータまたは実機

## 使い方

Xcode で開く:

```sh
open Apps/UTCJST/UTCJST.xcodeproj
```

`Packages/ClockCore` はローカルパッケージ参照としてプロジェクトに組み込まれているので、
別途 clone や resolve は不要です。編集するとそのままアプリ側に反映されます。

コマンドラインから:

```sh
make list                 # アプリと共有パッケージの一覧
make build APP=UTCJST     # シミュレータ向けにビルド
make test                 # 共有パッケージのテストを全部実行
```

## アプリ: UTCJST

現在時刻を UTC（協定世界時）と JST（日本標準時）の 2 つで並べて表示します。
表示するだけのアプリなので、設定画面もネットワーク通信もありません。

- 時刻は `HH:mm:ss`、日付は `yyyy-MM-dd (EEE)`、UTC からのオフセットも併記
- `TimelineView` で 0.5 秒ごとに更新（画面が見えていないときは停止する）
- ライト / ダークの両方に対応

## 新しいアプリを追加するには

[docs/adding-a-new-app.md](docs/adding-a-new-app.md) を参照してください。
