import AVFoundation
import UIKit

extension UIDeviceOrientation {
    var avCaptureVideoOrientation: AVCaptureVideoOrientation {
        switch self {
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeRight
            case .landscapeRight:
                return .landscapeLeft
            case .faceUp, .faceDown, .unknown:
                return .portrait
        }
    }
}
