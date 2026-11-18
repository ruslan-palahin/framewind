import CoreGraphics

package enum VideoGeometry {
    package static func displaySize(naturalSize: CGSize, transform: CGAffineTransform) -> CGSize {
        let rotated = CGRect(origin: .zero, size: naturalSize).applying(transform)
        return CGSize(width: abs(rotated.width), height: abs(rotated.height))
    }
}
