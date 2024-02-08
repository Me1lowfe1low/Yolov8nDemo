import Vision
import AVFoundation
import UIKit
import Combine

class DetectionManager {
    private var videoOutput = AVCaptureVideoDataOutput()
    private var requests = [VNRequest]()
    private var detectionLayer: CALayer?
    private var screenRect: CGRect?
    
    func setupDetector() {
        do {
            let model = try yolov8n().model
            
            guard let _ = model.modelDescription.classLabels as? [String] else { return }

            let visionModel = try VNCoreMLModel(for: model)
            let recognitions = VNCoreMLRequest(model: visionModel) { [unowned self] request, error in
                detectionDidComplete(request: request, error: error)
            }
            
            requests = [recognitions]
        } catch let error {
            fatalError("mlpackage error: "+error.localizedDescription)
        }
    }
    
    func setupLayers() {
        detectionLayer = CALayer()
        
        guard let detectionLayer else { return }
        
        updateScreenRect(width: UIScreen.uiApplicationWidth, height: UIScreen.uiApplicationHeight)
        
        detectionLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.uiApplicationWidth,
            height: UIScreen.uiApplicationHeight
        )
    }
    
    func updateLayers() {
        guard let screenRect else { return }
        
        detectionLayer?.frame = CGRect(
            x: 0,
            y: 0,
            width: screenRect.size.width,
            height: screenRect.size.height
        )
    }
    
    func updateScreenRect(width newWidth: CGFloat, height newHeight: CGFloat) {
        screenRect = CGRect(
            x: 0,
            y: 0,
            width: newWidth,
            height: newHeight
        )
    }
    
    func setBufferDelegate(for delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        videoOutput.setSampleBufferDelegate(
            delegate,
            queue: DispatchQueue(label: "sampleBufferQueue")
        )
    }
    
    func getVideoOutput() -> AVCaptureVideoDataOutput {
        videoOutput
    }

    func setVideoOrientation() {
        DispatchQueue.main.async { [weak self] in
            self?.videoOutput.connection(with: .video)?.videoOrientation = .portrait
        }
    }
    
    func getRequests() -> [VNRequest] {
        requests
    }
    
    func getLayer() -> CALayer {
        guard let detectionLayer else { return CALayer() }
        
        return detectionLayer
    }
    
    func setScreenSize(_ completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            let screenWidth = UIScreen.uiApplicationWidth
            let screenHeight = UIScreen.uiApplicationHeight
            
            self?.screenRect = CGRect(
                x: 0,
                y: 0,
                width: screenWidth,
                height: screenHeight
            )
            
            completion()
        }
    }
    
    func getScreenSize() -> CGRect {
        guard let screenRect else { return CGRect() }
        
        return screenRect
    }
}

// MARK: - Private

extension DetectionManager {
    private func drawBoundingBox(_ bounds: CGRect, label: String) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        boxLayer.borderWidth = 4.0
        boxLayer.borderColor = CGColor.init(
            red: 0.0,
            green: 0.0,
            blue: 0.0,
            alpha: 0.5
        )
        boxLayer.cornerRadius = 4
        
        let textLayer = CATextLayer()
        textLayer.string = label
        textLayer.fontSize = calculateFontSize(for: textLayer, in: boxLayer.bounds.size)
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.alignmentMode = .center
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        rotateLayer(textLayer, to: UIDevice.current.orientation)
        
        boxLayer.addSublayer(textLayer)
        
        return boxLayer
    }
    
    private func detectionDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            if let results = request.results {
                self.extractDetections(results)
            }
        })
    }
    
    private func extractDetections(_ results: [VNObservation]) {
        detectionLayer?.sublayers = nil
        
        for observation in results where observation is VNRecognizedObjectObservation {
            var label: String = ""
            
            guard let objectObservation = observation as? VNRecognizedObjectObservation else { continue }
            if let classLabel = objectObservation.labels.first?.identifier {
                label = classLabel
            }
            
            // TODO: we could add additional checks here, e.g. show only objects that we are confident of
            //            guard observation.confidence > 0.75 else { return }
            
            guard let screenRect else { return }
            
            let objectBounds = VNImageRectForNormalizedRect(
                objectObservation.boundingBox,
                Int(screenRect.size.width),
                Int(screenRect.size.height)
            )
            
            let transformedBounds = CGRect(
                x: objectBounds.minX,
                y: screenRect.size.height - objectBounds.maxY,
                width: objectBounds.width,
                height: objectBounds.height
            )
            
            let boxLayer = self.drawBoundingBox(transformedBounds, label: label)
            detectionLayer?.addSublayer(boxLayer)
        }
    }
    
    private func calculateFontSize(for textLayer: CATextLayer, in size: CGSize) -> CGFloat {
        let maxHeight = size.height
        let maxWidth = size.width
        let maxFontSize: CGFloat = 20.0
        
        var fontSize: CGFloat = maxFontSize
        
        while true {
            let textSize = (textLayer.string as? String)?.size(
                withAttributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)
                ]
            )
            
            if let textSize = textSize, textSize.height <= maxHeight, textSize.width <= maxWidth {
                break
            }
            
            fontSize -= 1.0
            
            if fontSize < 1.0 {
                break
            }
        }
        
        return fontSize
    }
    
    private func rotateLayer(_ layer: CALayer, to orientation: UIDeviceOrientation) {
        var rotationTransform: CATransform3D
        
        switch orientation {
            case .landscapeLeft:
                rotationTransform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
            case .landscapeRight:
                rotationTransform = CATransform3DMakeRotation(CGFloat.pi + CGFloat.pi / 2, 0, 0, 1)
            case .portraitUpsideDown:
                rotationTransform = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)
            default:
                rotationTransform = CATransform3DIdentity
        }
        
        layer.transform = rotationTransform
    }
}
