import WatchKit

enum HapticEvent {
    case single
    case double
}

final class HapticsManager {
    func play(_ event: HapticEvent) {
        let device = WKInterfaceDevice.current()
        switch event {
        case .single:
            device.play(.click)
        case .double:
            device.play(.directionUp)
        }
    }
}
