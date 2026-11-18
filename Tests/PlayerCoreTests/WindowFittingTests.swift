import CoreGraphics
import PlayerCore
import Testing

struct WindowFittingTests {
    private let screen = CGRect(x: 0, y: 0, width: 2000, height: 1250)
    private let minimum = CGSize(width: 680, height: 240)

    private func contentSize(forVideo video: CGSize) -> CGSize {
        WindowFitting.contentSize(
            forVideo: video,
            available: screen,
            controlBarHeight: 44,
            minimumContentSize: minimum,
            maxScreenShare: 0.8
        )
    }

    private func isClose(_ actual: CGSize, _ expected: CGSize) -> Bool {
        abs(actual.width - expected.width) < 0.01 && abs(actual.height - expected.height) < 0.01
    }

    @Test func keepsSmallVideoAtNaturalSizePlusControlBar() {
        #expect(isClose(contentSize(forVideo: CGSize(width: 800, height: 450)), CGSize(width: 800, height: 494)))
    }

    @Test func neverGoesBelowMinimumContentSize() {
        #expect(isClose(contentSize(forVideo: CGSize(width: 320, height: 180)), minimum))
    }

    @Test func scalesWideVideoDownToScreenShareWidth() {
        #expect(isClose(contentSize(forVideo: CGSize(width: 3200, height: 900)), CGSize(width: 1600, height: 494)))
    }

    @Test func scalesTallVideoDownToScreenShareHeightMinusControlBar() {
        #expect(isClose(contentSize(forVideo: CGSize(width: 1080, height: 1920)), CGSize(width: 680, height: 1000)))
    }

    @Test func scalesLargeVideoByTheTighterSide() {
        #expect(isClose(contentSize(forVideo: CGSize(width: 3840, height: 2160)), CGSize(width: 1600, height: 944)))
    }

    @Test func centersNewFrameOnCurrentWindow() {
        let origin = WindowFitting.origin(
            forFrameSize: CGSize(width: 1000, height: 600),
            centeredOn: CGRect(x: 500, y: 300, width: 800, height: 500),
            within: screen
        )
        #expect(origin == CGPoint(x: 400, y: 250))
    }

    @Test func keepsFrameInsideBottomLeftEdges() {
        let origin = WindowFitting.origin(
            forFrameSize: CGSize(width: 1000, height: 600),
            centeredOn: CGRect(x: 0, y: 0, width: 200, height: 200),
            within: screen
        )
        #expect(origin == CGPoint(x: 0, y: 0))
    }

    @Test func keepsFrameInsideTopRightEdges() {
        let origin = WindowFitting.origin(
            forFrameSize: CGSize(width: 1000, height: 600),
            centeredOn: CGRect(x: 1900, y: 1150, width: 100, height: 100),
            within: screen
        )
        #expect(origin == CGPoint(x: 1000, y: 650))
    }

    @Test func respectsScreensWithNegativeCoordinates() {
        let leftScreen = CGRect(x: -1920, y: -200, width: 1920, height: 1080)
        let origin = WindowFitting.origin(
            forFrameSize: CGSize(width: 1000, height: 600),
            centeredOn: CGRect(x: -1900, y: -150, width: 400, height: 300),
            within: leftScreen
        )
        #expect(origin == CGPoint(x: -1920, y: -200))
    }
}
