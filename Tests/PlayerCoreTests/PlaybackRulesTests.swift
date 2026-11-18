import PlayerCore
import Testing

struct PlaybackRulesTests {
    @Test func stopsOnLastFrameByDefault() {
        #expect(PlaybackRules().endBehavior == .stopOnLastFrame)
    }

    @Test(arguments: [
        (EndBehavior.stopOnLastFrame, EndAction.stayOnLastFrame),
        (EndBehavior.loop, EndAction.playFromStart),
        (EndBehavior.returnToStart, EndAction.rewindToStart),
    ])
    func endOfVideoFollowsSelectedBehavior(behavior: EndBehavior, expected: EndAction) {
        var rules = PlaybackRules()
        rules.endBehavior = behavior
        #expect(rules.videoDidEnd() == expected)
    }

    @Test func playContinuesFromCurrentPositionBeforeTheEnd() {
        var rules = PlaybackRules()
        #expect(rules.startPlayback() == .fromCurrentPosition)
    }

    @Test func playAfterStoppingAtTheEndStartsFromBeginningOnce() {
        var rules = PlaybackRules()
        _ = rules.videoDidEnd()
        #expect(rules.startPlayback() == .fromBeginning)
        #expect(rules.startPlayback() == .fromCurrentPosition)
    }

    @Test(arguments: [EndBehavior.loop, EndBehavior.returnToStart])
    func loopingAndRewindingNeverForceARestart(behavior: EndBehavior) {
        var rules = PlaybackRules()
        rules.endBehavior = behavior
        _ = rules.videoDidEnd()
        #expect(rules.startPlayback() == .fromCurrentPosition)
    }

    @Test func changingBehaviorAfterStoppingKeepsTheRestartPending() {
        var rules = PlaybackRules()
        _ = rules.videoDidEnd()
        rules.endBehavior = .loop
        #expect(rules.startPlayback() == .fromBeginning)
    }

    @Test func seekingCancelsThePendingRestart() {
        var rules = PlaybackRules()
        _ = rules.videoDidEnd()
        rules.didSeek()
        #expect(rules.startPlayback() == .fromCurrentPosition)
    }

    @Test func openingANewVideoCancelsThePendingRestartAndKeepsTheBehavior() {
        var rules = PlaybackRules()
        _ = rules.videoDidEnd()
        rules.endBehavior = .returnToStart
        rules.didOpenNewVideo()
        #expect(rules.startPlayback() == .fromCurrentPosition)
        #expect(rules.endBehavior == .returnToStart)
    }
}
