import SengiriCore
import SwiftUI
import UIKit

/// 千切りゲームの本体。タップ 1 回で 1 カット。
struct ChopGameView: View {
    let vegetable: Vegetable
    let target: Int

    private static let records = ChopRecordStore()

    @State private var session: ChopSession
    @State private var best: ChopRecord?
    @State private var isNewRecord = false
    /// 1 回のタッチで 1 カットにするためのフラグ。
    @State private var isTouching = false

    private let cutFeedback = UIImpactFeedbackGenerator(style: .rigid)

    init(vegetable: Vegetable, target: Int) {
        self.vegetable = vegetable
        self.target = target
        _session = State(initialValue: ChopSession(vegetable: vegetable, target: target))
    }

    var body: some View {
        VStack(spacing: 16) {
            timer
            board
            footer
        }
        .padding(20)
        .navigationTitle(vegetable.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cutFeedback.prepare()
            best = Self.records.best(for: vegetable, cutCount: session.target)
        }
    }

    // MARK: - 画面パーツ

    private var timer: some View {
        // 走っている間だけ細かく更新する。終了後は elapsed が止まるので値は動かない。
        TimelineView(.periodic(from: .now, by: 0.03)) { context in
            VStack(spacing: 4) {
                Text(ChopTimeFormatter.string(session.elapsed(at: context.date)))
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("\(session.cutCount) / \(session.target) カット")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var board: some View {
        VegetableBoardView(vegetable: vegetable, cuts: session.cutCount, target: session.target)
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            // タップの離し待ちが無いよう、指が触れた瞬間に 1 カットする。
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isTouching else { return }
                        isTouching = true
                        cut()
                    }
                    .onEnded { _ in isTouching = false }
            )
            .animation(.easeOut(duration: 0.08), value: session.cutCount)
    }

    @ViewBuilder
    private var footer: some View {
        if session.isFinished {
            result
        } else {
            VStack(spacing: 10) {
                ProgressView(value: session.progress)
                Text(session.hasStarted ? "あと \(session.remaining) カット" : "タップすると計測開始")
                    .font(.headline)
                    .foregroundStyle(session.hasStarted ? .primary : .secondary)
                if let best {
                    Text("ベスト \(ChopTimeFormatter.string(best.seconds)) 秒")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var result: some View {
        VStack(spacing: 12) {
            if isNewRecord {
                Text("新記録！")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.accentColor, in: Capsule())
            }

            if let result = session.result {
                HStack(spacing: 24) {
                    stat(title: "タイム", value: "\(ChopTimeFormatter.string(result)) 秒")
                    stat(title: "1 カット", value: "\(ChopTimeFormatter.string(result / Double(session.target))) 秒")
                }
            }

            if let best {
                Text("ベスト \(ChopTimeFormatter.string(best.seconds)) 秒（\(session.target) カット）")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                retry()
            } label: {
                Text("もう一度")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
    }

    // MARK: - 操作

    private func cut() {
        guard !session.isFinished else { return }
        session.cut(at: Date())
        cutFeedback.impactOccurred(intensity: 0.7)

        guard session.isFinished, let seconds = session.result else { return }
        let record = ChopRecord(
            vegetable: vegetable,
            cutCount: session.target,
            seconds: seconds,
            achievedAt: Date()
        )
        isNewRecord = Self.records.submit(record)
        best = Self.records.best(for: vegetable, cutCount: session.target)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func retry() {
        session = ChopSession(vegetable: vegetable, target: target)
        isNewRecord = false
        cutFeedback.prepare()
    }
}

#Preview {
    NavigationStack {
        ChopGameView(vegetable: .cabbage, target: 20)
    }
}
