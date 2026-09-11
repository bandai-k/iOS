import ClockCore
import SwiftUI

/// タイムゾーン 1 つ分のカード。
struct ClockCardView: View {
    let zone: ClockZone
    let date: Date

    var body: some View {
        // フォーマッタはストア側でゾーンごとに使い回すので、ここで作り直さない。
        let snapshot = ClockFormatterStore.formatter(for: zone).snapshot(at: date)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(zone.id)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                Text(zone.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(snapshot.offset)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.06), in: Capsule())
            }

            Text(snapshot.time)
                .font(.system(size: 52, weight: .semibold, design: .monospaced))
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
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        ClockCardView(zone: .utc, date: .now)
        ClockCardView(zone: .jst, date: .now)
    }
    .padding()
}
