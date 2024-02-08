import UIKit

extension UIApplication {
    @MainActor
    func interfaceOrientation() -> UIInterfaceOrientation {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow }?
            .windowScene?
            .interfaceOrientation ?? .unknown
    }
}
