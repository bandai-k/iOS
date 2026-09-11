import Foundation

enum CameraError: LocalizedError {
    case noCamera
    case configurationFailed
    case notReady
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .noCamera:
            return "カメラが見つかりません（シミュレータでは実行できません）"
        case .configurationFailed:
            return "カメラの初期化に失敗しました"
        case .notReady:
            return "カメラの準備ができていません"
        case .captureFailed:
            return "写真の取得に失敗しました"
        }
    }
}
