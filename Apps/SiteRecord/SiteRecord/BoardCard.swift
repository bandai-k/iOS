import SiteRecordCore
import SwiftUI

/// 看板の見た目。画面のプレビューにも、写真への焼き込みにも同じものを使う。
///
/// 画面と写真でレイアウトをずらさないよう、寸法はすべて `unit` 倍で持つ。
/// `unit == 1` が画面表示サイズ（幅 `baseWidth`）。
struct BoardCard: View {
    /// 画面表示時の基準幅。写真合成時はこの幅に対する比率を `unit` に渡す。
    static let baseWidth: CGFloat = 300

    let board: SiteBoard
    let timestamp: String
    var unit: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 5 * unit) {
            if board.isEmpty {
                Text("看板が未設定です")
                    .font(.system(size: 13 * unit, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            } else {
                ForEach(board.rows) { row in
                    rowView(row)
                }
            }

            Rectangle()
                .fill(.white.opacity(0.35))
                .frame(height: max(0.5, 1 * unit))
                .padding(.vertical, 2 * unit)

            HStack(spacing: 8 * unit) {
                Text("撮影日時")
                    .font(.system(size: 11 * unit, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer(minLength: 0)
                Text(timestamp)
                    .font(.system(size: 15 * unit, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
        }
        .padding(12 * unit)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8 * unit, style: .continuous)
                .fill(.black.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8 * unit, style: .continuous)
                .stroke(.white.opacity(0.45), lineWidth: max(0.5, 1 * unit))
        )
    }

    private func rowView(_ row: BoardRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8 * unit) {
            Text(row.label)
                .font(.system(size: 11 * unit, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 58 * unit, alignment: .leading)
            Text(row.value)
                .font(.system(size: 14 * unit, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        BoardCard(
            board: SiteBoard(
                projectName: "〇〇橋下部工事",
                workType: "配筋検査",
                location: "A1 橋台 フーチング",
                contractor: "〇〇建設"
            ),
            timestamp: "2026/09/11 09:41:07"
        )
        .frame(width: BoardCard.baseWidth)
    }
    .ignoresSafeArea()
}
