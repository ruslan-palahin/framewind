import Foundation

package enum PlaybackTime {
    package static func format(_ seconds: Double) -> String {
        let wholeSeconds = seconds.isFinite ? max(0, Int(seconds)) : 0
        return String(format: "%d:%02d", wholeSeconds / 60, wholeSeconds % 60)
    }
}
