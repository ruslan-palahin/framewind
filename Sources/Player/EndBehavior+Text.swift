import Foundation
import PlayerCore

extension EndBehavior {
    var label: String {
        switch self {
        case .stopOnLastFrame: String(localized: "endBehavior.stop.label")
        case .loop: String(localized: "endBehavior.loop.label")
        case .returnToStart: String(localized: "endBehavior.returnToStart.label")
        }
    }

    var toolTip: String {
        switch self {
        case .stopOnLastFrame: String(localized: "endBehavior.stop.toolTip")
        case .loop: String(localized: "endBehavior.loop.toolTip")
        case .returnToStart: String(localized: "endBehavior.returnToStart.toolTip")
        }
    }
}
