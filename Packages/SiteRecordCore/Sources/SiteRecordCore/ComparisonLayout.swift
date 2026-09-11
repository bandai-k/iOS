import Foundation

/// 施工前後を並べる向き。
public enum ComparisonAxis: String, CaseIterable, Codable, Sendable {
    /// 左に施工前、右に施工後。
    case horizontal
    /// 上に施工前、下に施工後。
    case vertical
}

/// 比較画像 1 枚分（見出し帯と写真）の配置。
public struct ComparisonSlot: Equatable, Sendable {
    /// 「施工前」などの見出しを描く帯。
    public let labelRect: CGRect
    /// 写真を描く位置。元画像の縦横比を保ったままセル内で中央寄せされている。
    public let imageRect: CGRect

    public init(labelRect: CGRect, imageRect: CGRect) {
        self.labelRect = labelRect
        self.imageRect = imageRect
    }

    func scaled(by factor: CGFloat) -> ComparisonSlot {
        ComparisonSlot(
            labelRect: labelRect.scaled(by: factor),
            imageRect: imageRect.scaled(by: factor)
        )
    }
}

/// 比較画像 1 枚のレイアウト。描画そのものはアプリ側が行う。
public struct ComparisonLayout: Equatable, Sendable {
    public let canvasSize: CGSize
    /// `[施工前, 施工後]` の順。
    public let slots: [ComparisonSlot]
    /// 見出しの文字サイズ。
    public let fontSize: CGFloat

    public init(canvasSize: CGSize, slots: [ComparisonSlot], fontSize: CGFloat) {
        self.canvasSize = canvasSize
        self.slots = slots
        self.fontSize = fontSize
    }

    func scaled(by factor: CGFloat) -> ComparisonLayout {
        ComparisonLayout(
            canvasSize: CGSize(width: canvasSize.width * factor, height: canvasSize.height * factor),
            slots: slots.map { $0.scaled(by: factor) },
            fontSize: fontSize * factor
        )
    }
}

/// 施工前後の写真 2 枚を 1 枚にまとめるときの配置を計算する。
///
/// 2 枚のセルは必ず同じ大きさにし、写真は縦横比を保ったままその中央に置く。
/// 解像度が違う写真を並べても、見出しの高さや余白の比率が揃うようにしている。
public enum ComparisonComposer {
    /// 見出し帯の高さ（セル高に対する比率）。
    private static let labelRatio: CGFloat = 0.06
    /// 余白（セルの短辺に対する比率）。
    private static let paddingRatio: CGFloat = 0.02

    public static func layout(
        beforeSize: CGSize,
        afterSize: CGSize,
        axis: ComparisonAxis,
        maxLongSide: CGFloat = 4096
    ) -> ComparisonLayout {
        let sizes = [normalized(beforeSize), normalized(afterSize)]

        // 並べる向きに応じて、2 枚の «揃える辺» を最大値に合わせて拡大する。
        let scaledSizes: [CGSize]
        let cellSize: CGSize
        switch axis {
        case .horizontal:
            let height = max(sizes[0].height, sizes[1].height)
            scaledSizes = sizes.map { CGSize(width: $0.width * height / $0.height, height: height) }
            cellSize = CGSize(width: max(scaledSizes[0].width, scaledSizes[1].width), height: height)
        case .vertical:
            let width = max(sizes[0].width, sizes[1].width)
            scaledSizes = sizes.map { CGSize(width: width, height: $0.height * width / $0.width) }
            cellSize = CGSize(width: width, height: max(scaledSizes[0].height, scaledSizes[1].height))
        }

        let labelHeight = max(cellSize.height * labelRatio, 28)
        let padding = max(min(cellSize.width, cellSize.height) * paddingRatio, 8)
        let gap = padding

        let canvasSize: CGSize
        switch axis {
        case .horizontal:
            canvasSize = CGSize(
                width: padding * 2 + cellSize.width * 2 + gap,
                height: padding * 2 + labelHeight + cellSize.height
            )
        case .vertical:
            canvasSize = CGSize(
                width: padding * 2 + cellSize.width,
                height: padding * 2 + (labelHeight + cellSize.height) * 2 + gap
            )
        }

        let slots = scaledSizes.enumerated().map { index, scaled -> ComparisonSlot in
            let offset = CGFloat(index)
            let cellOrigin: CGPoint
            switch axis {
            case .horizontal:
                cellOrigin = CGPoint(x: padding + offset * (cellSize.width + gap), y: padding)
            case .vertical:
                cellOrigin = CGPoint(x: padding, y: padding + offset * (labelHeight + cellSize.height + gap))
            }

            let labelRect = CGRect(
                x: cellOrigin.x,
                y: cellOrigin.y,
                width: cellSize.width,
                height: labelHeight
            )
            let area = CGRect(
                x: cellOrigin.x,
                y: cellOrigin.y + labelHeight,
                width: cellSize.width,
                height: cellSize.height
            )
            let imageRect = CGRect(
                x: area.midX - scaled.width / 2,
                y: area.midY - scaled.height / 2,
                width: scaled.width,
                height: scaled.height
            )
            return ComparisonSlot(labelRect: labelRect, imageRect: imageRect)
        }

        let layout = ComparisonLayout(
            canvasSize: canvasSize,
            slots: slots,
            fontSize: labelHeight * 0.58
        )

        // 元が高解像度だと 2 枚分で巨大になるので、長辺で頭打ちにする。
        let longSide = max(canvasSize.width, canvasSize.height)
        guard longSide > maxLongSide, longSide > 0 else { return layout }
        return layout.scaled(by: maxLongSide / longSide)
    }

    /// 幅か高さが 0 以下・非有限の画像が来ても計算が壊れないようにする。
    private static func normalized(_ size: CGSize) -> CGSize {
        let width = size.width.isFinite && size.width > 0 ? size.width : 1
        let height = size.height.isFinite && size.height > 0 ? size.height : 1
        return CGSize(width: width, height: height)
    }
}

private extension CGRect {
    func scaled(by factor: CGFloat) -> CGRect {
        CGRect(
            x: origin.x * factor,
            y: origin.y * factor,
            width: width * factor,
            height: height * factor
        )
    }
}
