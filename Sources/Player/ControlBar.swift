import AppKit
import PlayerCore

@MainActor
final class ControlBar: NSView {
    static let height: CGFloat = 44

    let playButton = NSButton(title: String(localized: "control.play"), target: nil, action: nil)
    let slider = ScrubSlider(value: 0, minValue: 0, maxValue: 1, target: nil, action: nil)
    let endBehaviorControl = NSSegmentedControl(
        labels: EndBehavior.allCases.map(\.label),
        trackingMode: .selectOne,
        target: nil,
        action: nil
    )
    private let currentTimeLabel = NSTextField(labelWithString: "0:00")
    private let durationLabel = NSTextField(labelWithString: "0:00")
    private let endBehaviorLabel = NSTextField(labelWithString: String(localized: "control.endBehavior.label"))

    init() {
        super.init(frame: .zero)

        playButton.bezelStyle = .push
        playButton.imagePosition = .imageLeading

        slider.isContinuous = true
        slider.toolTip = String(localized: "control.slider.toolTip")

        for label in [currentTimeLabel, durationLabel] {
            label.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }
        currentTimeLabel.toolTip = String(localized: "control.currentTime.toolTip")
        durationLabel.toolTip = String(localized: "control.duration.toolTip")

        let endBehaviorHint = String(localized: "control.endBehavior.toolTip")
        endBehaviorLabel.toolTip = endBehaviorHint
        endBehaviorControl.toolTip = endBehaviorHint
        for (index, behavior) in EndBehavior.allCases.enumerated() {
            endBehaviorControl.setToolTip(behavior.toolTip, forSegment: index)
        }

        let stack = NSStackView(views: [
            playButton, currentTimeLabel, slider, durationLabel, endBehaviorLabel, endBehaviorControl,
        ])
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.setCustomSpacing(20, after: durationLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        slider.setContentHuggingPriority(.defaultLow, for: .horizontal)
        for view in [playButton, currentTimeLabel, durationLabel, endBehaviorLabel, endBehaviorControl] {
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.height),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
            slider.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
        ])

        showPlaying(false)
        setVideoLoaded(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func showPlaying(_ isPlaying: Bool) {
        playButton.title = isPlaying ? String(localized: "control.pause") : String(localized: "control.play")
        playButton.image = NSImage(
            systemSymbolName: isPlaying ? "pause.fill" : "play.fill",
            accessibilityDescription: nil
        )
        playButton.toolTip = isPlaying
            ? String(localized: "control.pause.toolTip")
            : String(localized: "control.play.toolTip")
    }

    func showTime(current: Double, duration: Double) {
        currentTimeLabel.stringValue = PlaybackTime.format(current)
        durationLabel.stringValue = PlaybackTime.format(duration)
        slider.maxValue = duration
        if !slider.isScrubbing {
            slider.doubleValue = current
        }
    }

    var selectedEndBehavior: EndBehavior {
        EndBehavior.allCases[endBehaviorControl.selectedSegment]
    }

    func showEndBehavior(_ behavior: EndBehavior) {
        endBehaviorControl.selectedSegment = EndBehavior.allCases.firstIndex(of: behavior) ?? 0
    }

    func setVideoLoaded(_ isLoaded: Bool) {
        playButton.isEnabled = isLoaded
        slider.isEnabled = isLoaded
    }
}
