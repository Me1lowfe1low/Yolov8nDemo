import UIKit
import AVFoundation

extension UIInterfaceOrientation {
    var avCaptureOrientation: AVCaptureVideoOrientation {
        switch self {
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            default:
                return .portrait
        }
    }
}
