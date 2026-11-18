package enum EndAction: Sendable {
    case stayOnLastFrame
    case playFromStart
    case rewindToStart
}

package enum PlaybackStart: Sendable {
    case fromBeginning
    case fromCurrentPosition
}

package struct PlaybackRules: Sendable {
    package var endBehavior = EndBehavior.stopOnLastFrame
    private var reachedEnd = false

    package init() {}

    package mutating func videoDidEnd() -> EndAction {
        switch endBehavior {
        case .stopOnLastFrame:
            reachedEnd = true
            return .stayOnLastFrame
        case .loop:
            return .playFromStart
        case .returnToStart:
            return .rewindToStart
        }
    }

    package mutating func startPlayback() -> PlaybackStart {
        guard reachedEnd else { return .fromCurrentPosition }
        reachedEnd = false
        return .fromBeginning
    }

    package mutating func didSeek() {
        reachedEnd = false
    }

    package mutating func didOpenNewVideo() {
        reachedEnd = false
    }
}
