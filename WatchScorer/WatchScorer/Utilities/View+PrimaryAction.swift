import SwiftUI

extension View {
    /// Marks the view's primary action so that supported hardware gestures such as Double Tap can trigger it.
    func primaryAction(_ action: @escaping () -> Void) -> some View {
        accessibilityAction(.primaryAction, action)
    }
}
