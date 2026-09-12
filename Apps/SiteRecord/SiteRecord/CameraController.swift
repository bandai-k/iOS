import AVFoundation
import UIKit

/// 撮影した写真 1 枚分。画像と、カメラが付けた EXIF などのメタデータ。
struct CapturedPhoto {
    let image: UIImage
    let metadata: [String: Any]
}

/// 背面カメラのセッションと撮影を受け持つ。
///
/// AVFoundation の設定・開始はブロックするのでプライベートキューで行い、
/// 画面が見る `status` だけをメインキューで更新する。
final class CameraController: NSObject, ObservableObject {
    enum Status: Equatable {
        case configuring
        case ready
        case denied
        case failed(String)
    }

    @Published private(set) var status: Status = .configuring
    @Published private(set) var isCapturing = false

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "app.siterecord.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    /// 撮影完了デリゲートと `capturePhoto()` の橋渡し。メインキューでのみ触る。
    private var captureContinuation: CheckedContinuation<CapturedPhoto, Error>?

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.configureAndRun()
                    } else {
                        self.status = .denied
                    }
                }
            }
        default:
            status = .denied
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func configureAndRun() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                do {
                    try self.configureSession()
                    self.isConfigured = true
                } catch {
                    let message = error.localizedDescription
                    DispatchQueue.main.async { self.status = .failed(message) }
                    return
                }
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
            DispatchQueue.main.async { self.status = .ready }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.noCamera
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw CameraError.configurationFailed }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else { throw CameraError.configurationFailed }
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .balanced

        // 画面を縦固定で使うので、撮影結果も縦向き（90°）に固定する。
        if let connection = photoOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    /// シャッターを切って撮影画像を返す。メインアクターから呼ぶこと。
    @MainActor
    func capturePhoto() async throws -> CapturedPhoto {
        guard status == .ready else { throw CameraError.notReady }
        guard !isCapturing else { throw CameraError.notReady }

        isCapturing = true
        defer { isCapturing = false }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CapturedPhoto, Error>) in
            captureContinuation = continuation
            sessionQueue.async { [weak self] in
                guard let self else { return }
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .off
                settings.photoQualityPrioritization = self.photoOutput.maxPhotoQualityPrioritization
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let result: Result<CapturedPhoto, Error>
        if let error {
            result = .failure(error)
        } else if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            // 撮影日時や機種は合成後の写真にも残したいので、メタデータを一緒に持ち帰る。
            result = .success(CapturedPhoto(image: image, metadata: photo.metadata))
        } else {
            result = .failure(CameraError.captureFailed)
        }

        // デリゲートは任意のキューで呼ばれるため、continuation の操作はメインに寄せる。
        DispatchQueue.main.async { [weak self] in
            guard let self, let continuation = self.captureContinuation else { return }
            self.captureContinuation = nil
            continuation.resume(with: result)
        }
    }
}
