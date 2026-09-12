import ClockCore
import SwiftUI

/// タイムゾーン 1 つ分のカード。
struct ClockCardView: View {
    let zone: ClockZone
    let date: Date
    var hourStyle: HourStyle = .twentyFour
    /// 変換の入力側として選ばれているカードは枠を強調する。
    var isHighlighted: Bool = false

    var body: some View {
        // フォーマッタはストア側で組み合わせごとに使い回すので、ここで作り直さない。
        let snapshot = ClockFormatterStore.formatter(for: zone, hourStyle: hourStyle).snapshot(at: date)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(zone.id)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                    .fixedSize()
                Text(zone.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
                // `UTC+05:45` のように名前がずれそのものの場合、バッジは同じ内容になるので出さない。
                if snapshot.offset != zone.id {
                    Text(snapshot.offset)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.06), in: Capsule())
                }
            }

            Text(snapshot.time)
                .font(.system(size: 48, weight: .semibold, design: .monospaced))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
                .accessibilityLabel("\(zone.id) の時刻 \(snapshot.time)")

            Text(snapshot.date)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isHighlighted ? Color.accentColor.opacity(0.7) : Color.primary.opacity(0.06),
                    lineWidth: isHighlighted ? 2 : 1
                )
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        ClockCardView(zone: .utc, date: .now)
        ClockCardView(zone: .jst, date: .now, hourStyle: .twelve, isHighlighted: true)
    }
    .padding()
}
