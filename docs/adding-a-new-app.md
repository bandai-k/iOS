# 新しいアプリを追加する

このモノレポにアプリを 1 本増やすときの手順です。ここでは例として `MyApp` を追加します。

## 1. Xcode でプロジェクトを作る

1. Xcode で **File > New > Project… > iOS > App** を選ぶ
2. Product Name に `MyApp`、Interface は **SwiftUI**、Language は **Swift** を指定
3. 保存先をリポジトリの `Apps/` にする（結果として `Apps/MyApp/MyApp.xcodeproj` になる）

`Apps/<アプリ名>/<アプリ名>.xcodeproj` という配置を守ってください。`Makefile` と CI が
この規約に依存しています。

## 2. 共有パッケージを使う

`Packages/` のパッケージを使いたい場合:

1. Xcode のプロジェクト設定 > **Package Dependencies** > **+** > **Add Local…**
2. `Packages/ClockCore` を選ぶ
3. ターゲットの **General > Frameworks, Libraries, and Embedded Content** に
   ライブラリが入っていることを確認する

`project.pbxproj` には相対パス（例: `../../Packages/ClockCore`）で記録されるので、
clone 先のパスが人によって違っても壊れません。

## 3. スキームを共有する

Xcode の **Product > Scheme > Manage Schemes…** で対象スキームの **Shared** に
チェックを入れ、`MyApp.xcodeproj/xcshareddata/xcschemes/MyApp.xcscheme` をコミットします。
これを忘れると `xcodebuild -scheme MyApp` が CI で失敗します。

## 4. 動作確認

```sh
make build APP=MyApp
make test
```

## 共有パッケージを新しく作る場合

```sh
mkdir -p Packages/MyFeature
cd Packages/MyFeature
swift package init --type library --name MyFeature
```

`Package.swift` の `platforms` にアプリと同じ（もしくはそれ以下の）iOS バージョンを
指定してください。`make test` は `Packages/*` を自動で拾うので、Makefile の変更は不要です。
