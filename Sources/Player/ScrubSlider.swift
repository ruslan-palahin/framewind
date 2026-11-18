import AppKit

final class ScrubSlider: NSSlider {
    private(set) var isScrubbing = false

    override func mouseDown(with event: NSEvent) {
        isScrubbing = true
        super.mouseDown(with: event)
        isScrubbing = false
    }
}
