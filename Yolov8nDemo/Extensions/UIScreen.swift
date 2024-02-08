import UIKit

extension UIScreen {
    static var uiApplicationWidth: CGFloat {
        UIApplication.shared.currentWindow?.screen.bounds.width ?? .zero
    }
    
    static var uiApplicationHeight: CGFloat {
        UIApplication.shared.currentWindow?.screen.bounds.height ?? .zero
    }
}
