import ClockCore
import SwiftUI

struct ContentView: View {
    /// 0.5 秒ごとに描画を更新する。1 秒間隔だと秒の切り替わりが最大 1 秒遅れて見えるため。
    private let tick: TimeInterval = 0.5

    var body: some View {
        TimelineView(.periodic(from: .now, by: tick)) { context in
            ZStack {
                BackgroundView()

                VStack(spacing: 20) {
                    header

                    ForEach(ClockZone.all) { zone in
                        ClockCardView(zone: zone, date: context.date)
                    }

                    Text("時差: JST は UTC より 9 時間進んでいます")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 520)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("UTC / JST")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("いまの時刻を 2 つのタイムゾーンで表示します")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.bottom, 4)
    }
}

private struct BackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.18),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .center
        )
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
