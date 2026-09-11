import Foundation

/// 千切りにする野菜。
public enum Vegetable: String, CaseIterable, Codable, Sendable, Identifiable {
    case cabbage
    case cucumber
    case carrot

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .cabbage: return "キャベツ"
        case .cucumber: return "きゅうり"
        case .carrot: return "にんじん"
        }
    }

    /// 初期状態の千切り回数。太さと切りやすさのイメージで変えている。
    public var defaultCutCount: Int {
        switch self {
        case .cabbage: return 50
        case .cucumber: return 30
        case .carrot: return 40
        }
    }
}

/// ゲームのルール上の制約。
public enum ChopRules {
    /// 設定できる千切り回数の範囲。
    public static let cutCountRange = 10...200

    public static func clamp(_ count: Int) -> Int {
        min(max(count, cutCountRange.lowerBound), cutCountRange.upperBound)
    }
}
