import UIKit
import SwiftUI
import AVFoundation
import Vision

class CameraViewController: UIViewController {
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var imageOrientation = AVCaptureVideoOrientation.portrait
    
    var detectionManager: DetectionManagerProtocol = DetectionManager()
    
    deinit {
        captureSession.stopRunning()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            self.setupCaptureSession {
                dispatchGroup.leave()
            }
            dispatchGroup.wait()
            
            self.detectionManager.setupLayers()
            
            guard let detectionLayer = detectionManager.detectionLayer else { return }
            
            self.view.layer.addSublayer(detectionLayer)
            self.detectionManager.setupDetector()
            
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            self.previewLayer.frame = CGRect(
                x: 0,
                y: 0,
                width: UIScreen.uiApplicationWidth,
                height: UIScreen.uiApplicationHeight
            )
            
            self.previewLayer.connection?.videoOrientation = UIDevice.current.orientation.avCaptureVideoOrientation
            
            self.detectionManager.updateScreenRect(
                width: UIScreen.uiApplicationWidth,
                height: UIScreen.uiApplicationHeight
            )
            
            detectionManager.setVideoOrientation()
            self.detectionManager.updateLayers()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if connection.isVideoOrientationSupported {
            setInitialOrientation()
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )
        
        do {
            try imageRequestHandler.perform(detectionManager.requests)
        } catch {
            print(error)
        }
    }
}

// MARK: - Private

extension CameraViewController {
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                permissionGranted = true
            case .notDetermined:
                requestPermission()
            default:
                permissionGranted = false
        }
    }
    
    private func requestPermission() {
        sessionQueue.suspend()
        
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func setupCaptureSession(_ completion: @escaping () -> Void) {
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput)
        else { return }
        
        captureSession.addInput(videoDeviceInput)
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        detectionManager.setScreenSize {
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(
                x: 0,
                y: 0,
                width: detectionManager.screenRect?.width ?? 0,
                height: detectionManager.screenRect?.height ?? 0
        )
        
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = UIDevice.current.orientation.avCaptureVideoOrientation
        
        detectionManager.setBufferDelegate(for: self)
        captureSession.addOutput(detectionManager.videoOutput)
        detectionManager.setVideoOrientation()
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            self.view.layer.addSublayer(self.previewLayer)
            completion()
        }
    }
    
    private func setInitialOrientation() {
        DispatchQueue.main.async { [weak self] in
            self?.imageOrientation = UIDevice.current.orientation.avCaptureVideoOrientation
        }
    }
}
