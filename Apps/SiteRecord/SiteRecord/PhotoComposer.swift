import SiteRecordCore
import SwiftUI
import UIKit

/// 撮影した写真に看板と撮影日時を焼き込む。
///
/// 画面に出しているのと同じ `BoardCard` を `ImageRenderer` で画像化して重ねるので、
/// プレビューと出来上がりの写真で見た目がずれない。
@MainActor
enum PhotoComposer {
    /// 写真の幅に対する看板の幅の比率。
    private static let cardWidthRatio: CGFloat = 0.46
    /// 写真の幅に対する余白の比率。
    private static let marginRatio: CGFloat = 0.03

    static func compose(photo: UIImage, board: SiteBoard, timestamp: String) -> UIImage {
        let size = photo.size
        guard size.width > 0, size.height > 0 else { return photo }

        let margin = size.width * marginRatio
        let cardWidth = min(size.width * cardWidthRatio, size.width - margin * 2)
        let unit = cardWidth / BoardCard.baseWidth

        let renderer = ImageRenderer(
            content: BoardCard(board: board, timestamp: timestamp, unit: unit)
                .frame(width: cardWidth)
        )
        renderer.scale = photo.scale
        renderer.isOpaque = false

        guard let card = renderer.uiImage else { return photo }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = photo.scale
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            photo.draw(in: CGRect(origin: .zero, size: size))
            // 左下に配置。看板が縦に伸びても写真からはみ出さないよう上端で止める。
            let y = max(margin, size.height - card.size.height - margin)
            card.draw(at: CGPoint(x: margin, y: y))
        }
    }
}
