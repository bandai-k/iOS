import SengiriCore
import SwiftUI

/// にんじん。左が太く、右へ細くなる。
struct CarrotShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.height / 2
        let tip = rect.height * 0.06
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY - tip))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + tip))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX - radius * 0.6, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

/// 野菜の見た目。リストのバッジとゲーム画面で同じものを使う。
struct VegetableStyle {
    let shape: AnyShape
    let fill: Color
    let inner: Color
    let aspectRatio: CGFloat

    static func style(for vegetable: Vegetable) -> VegetableStyle {
        switch vegetable {
        case .cabbage:
            return VegetableStyle(
                shape: AnyShape(Circle()),
                fill: Color(red: 0.72, green: 0.85, blue: 0.55),
                inner: Color(red: 0.94, green: 0.97, blue: 0.87),
                aspectRatio: 1
            )
        case .cucumber:
            return VegetableStyle(
                shape: AnyShape(Capsule()),
                fill: Color(red: 0.24, green: 0.50, blue: 0.22),
                inner: Color(red: 0.64, green: 0.81, blue: 0.50),
                aspectRatio: 2.6
            )
        case .carrot:
            return VegetableStyle(
                shape: AnyShape(CarrotShape()),
                fill: Color(red: 0.89, green: 0.42, blue: 0.10),
                inner: Color(red: 0.98, green: 0.73, blue: 0.42),
                aspectRatio: 2.2
            )
        }
    }
}

/// 野菜と、そこに入った切れ目を描く。
struct VegetableBoardView: View {
    let vegetable: Vegetable
    let cuts: Int
    let target: Int

    private var style: VegetableStyle { .style(for: vegetable) }

    /// 切れ目の最大本数。目標回数が多いと線が潰れるので頭打ちにする。
    private var lineCount: Int { min(target, 40) }

    var body: some View {
        ZStack {
            style.shape.fill(
                LinearGradient(
                    colors: [style.inner, style.fill],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            if vegetable == .cabbage {
                rings
            }

            sliceLines

            style.shape.stroke(.black.opacity(0.18), lineWidth: 2)
        }
        .aspectRatio(style.aspectRatio, contentMode: .fit)
    }

    /// キャベツの断面らしさを出すための同心円。
    private var rings: some View {
        ZStack {
            ForEach(1..<4) { index in
                Circle()
                    .stroke(style.fill.opacity(0.5), lineWidth: 3)
                    .scaleEffect(1 - CGFloat(index) * 0.22)
            }
        }
    }

    private var sliceLines: some View {
        Canvas { context, size in
            let drawn = min(cuts, lineCount)
            guard drawn > 0, lineCount > 0 else { return }
            for index in 0..<drawn {
                let x = size.width * (CGFloat(index) + 1) / CGFloat(lineCount + 1)
                var path = Path()
                path.move(to: CGPoint(x: x, y: -10))
                path.addLine(to: CGPoint(x: x, y: size.height + 10))
                context.stroke(path, with: .color(.white.opacity(0.9)), lineWidth: 2)
            }
        }
        .mask { style.shape }
        .allowsHitTesting(false)
    }
}

/// リストに並べる小さい野菜アイコン。
struct VegetableBadge: View {
    let vegetable: Vegetable

    var body: some View {
        let style = VegetableStyle.style(for: vegetable)
        style.shape
            .fill(style.fill)
            .frame(width: 34, height: 34 / style.aspectRatio)
            .frame(width: 40, height: 40)
    }
}

#Preview {
    VStack(spacing: 24) {
        VegetableBoardView(vegetable: .cabbage, cuts: 12, target: 40)
        VegetableBoardView(vegetable: .cucumber, cuts: 20, target: 30)
        VegetableBoardView(vegetable: .carrot, cuts: 5, target: 40)
    }
    .padding()
}
