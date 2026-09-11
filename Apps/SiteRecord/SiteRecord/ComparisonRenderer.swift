import SiteRecordCore
import UIKit

/// 施工前後の 2 枚を 1 枚の画像にまとめる。配置は `ComparisonComposer` が計算したものに従う。
enum ComparisonRenderer {
    private static let backgroundColor = UIColor.white
    private static let labelBackgroundColor = UIColor(white: 0.12, alpha: 1)

    static func render(
        before: UIImage,
        after: UIImage,
        axis: ComparisonAxis,
        labels: (before: String, after: String) = ("施工前", "施工後")
    ) -> UIImage {
        let layout = ComparisonComposer.layout(
            beforeSize: before.size,
            afterSize: after.size,
            axis: axis
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: layout.canvasSize, format: format).image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: layout.canvasSize))

            for (slot, content) in zip(layout.slots, [(before, labels.before), (after, labels.after)]) {
                content.0.draw(in: slot.imageRect)
                draw(label: content.1, in: slot.labelRect, fontSize: layout.fontSize)
            }
        }
    }

    private static func draw(label: String, in rect: CGRect, fontSize: CGFloat) {
        labelBackgroundColor.setFill()
        UIBezierPath(rect: rect).fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let text = label as NSString
        let size = text.size(withAttributes: attributes)
        let origin = CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)
        text.draw(at: origin, withAttributes: attributes)
    }
}
