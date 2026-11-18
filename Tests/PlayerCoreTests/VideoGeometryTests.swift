import CoreGraphics
import PlayerCore
import Testing

struct VideoGeometryTests {
    private let landscape = CGSize(width: 1920, height: 1080)
    private let portrait = CGSize(width: 1080, height: 1920)

    @Test func keepsNaturalSizeWithoutRotation() {
        #expect(VideoGeometry.displaySize(naturalSize: landscape, transform: .identity) == landscape)
    }

    @Test func swapsSidesForQuarterTurns() {
        let clockwise = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 1080, ty: 0)
        let counterClockwise = CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: 1920)
        #expect(VideoGeometry.displaySize(naturalSize: landscape, transform: clockwise) == portrait)
        #expect(VideoGeometry.displaySize(naturalSize: landscape, transform: counterClockwise) == portrait)
    }

    @Test func keepsSidesForHalfTurn() {
        let halfTurn = CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: 1920, ty: 1080)
        #expect(VideoGeometry.displaySize(naturalSize: landscape, transform: halfTurn) == landscape)
    }
}
