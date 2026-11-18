import CoreGraphics

package enum WindowFitting {
    package static func contentSize(
        forVideo videoSize: CGSize,
        available: CGRect,
        controlBarHeight: CGFloat,
        minimumContentSize: CGSize,
        maxScreenShare: CGFloat
    ) -> CGSize {
        let maxVideoWidth = available.width * maxScreenShare
        let maxVideoHeight = available.height * maxScreenShare - controlBarHeight
        let scale = min(1, maxVideoWidth / videoSize.width, maxVideoHeight / videoSize.height)
        return CGSize(
            width: max(videoSize.width * scale, minimumContentSize.width),
            height: max(videoSize.height * scale + controlBarHeight, minimumContentSize.height)
        )
    }

    package static func origin(forFrameSize size: CGSize, centeredOn current: CGRect, within available: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(current.midX - size.width / 2, available.minX), available.maxX - size.width),
            y: min(max(current.midY - size.height / 2, available.minY), available.maxY - size.height)
        )
    }
}
