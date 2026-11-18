import AppKit
import AVKit

@MainActor
final class PlayerContentView: NSView {
    private static let controlsIdleDelay: Duration = .milliseconds(2500)
    private static let controlsSlideDuration: TimeInterval = 0.25

    let videoClick = NSClickGestureRecognizer()
    private let videoArea = NSView()
    private let playerView = AVPlayerView()
    private let spinner = NSProgressIndicator()
    private let messageLabel = NSTextField(wrappingLabelWithString: "")
    private let controlBar: ControlBar
    private lazy var videoAboveControls = videoArea.bottomAnchor.constraint(equalTo: controlBar.topAnchor)
    private lazy var videoUnderControls = videoArea.bottomAnchor.constraint(equalTo: bottomAnchor)
    private lazy var controlBarBottom = controlBar.bottomAnchor.constraint(equalTo: bottomAnchor)
    private var hidesIdleControls = false
    private var areControlsShown = true
    private var hideControlsTask: Task<Void, Never>?

    init(player: AVPlayer, controlBar: ControlBar) {
        self.controlBar = controlBar
        super.init(frame: .zero)
        configureViews(player: player)
        layOutViews()
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect], owner: self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func showLoading() {
        messageLabel.isHidden = true
        playerView.isHidden = true
        spinner.startAnimation(nil)
    }

    func showMessage(_ text: String) {
        spinner.stopAnimation(nil)
        playerView.isHidden = true
        messageLabel.stringValue = text
        messageLabel.isHidden = false
    }

    func showVideo() {
        spinner.stopAnimation(nil)
        playerView.isHidden = false
    }

    func setFullScreen(_ isFullScreen: Bool) {
        hidesIdleControls = isFullScreen
        if isFullScreen {
            NSLayoutConstraint.deactivate([videoAboveControls])
            NSLayoutConstraint.activate([videoUnderControls])
        } else {
            NSLayoutConstraint.deactivate([videoUnderControls])
            NSLayoutConstraint.activate([videoAboveControls])
            NSCursor.setHiddenUntilMouseMoves(false)
        }
        revealControls()
    }

    func revealControls() {
        slideControls(shown: true)
        hideControlsTask?.cancel()
        guard hidesIdleControls else { return }
        hideControlsTask = Task { [weak self] in
            try? await Task.sleep(for: Self.controlsIdleDelay)
            guard !Task.isCancelled else { return }
            self?.hideIdleControls()
        }
    }

    override func mouseMoved(with event: NSEvent) {
        revealControls()
    }

    private func hideIdleControls() {
        guard !isPointerOverControls else {
            revealControls()
            return
        }
        slideControls(shown: false)
        NSCursor.setHiddenUntilMouseMoves(true)
    }

    private var isPointerOverControls: Bool {
        guard let window else { return false }
        let pointer = controlBar.convert(window.mouseLocationOutsideOfEventStream, from: nil)
        return controlBar.bounds.contains(pointer)
    }

    private func slideControls(shown: Bool) {
        guard shown != areControlsShown else { return }
        areControlsShown = shown
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.controlsSlideDuration
            controlBarBottom.animator().constant = shown ? 0 : ControlBar.height
        }
    }

    private func configureViews(player: AVPlayer) {
        videoArea.wantsLayer = true
        videoArea.layer?.backgroundColor = NSColor.black.cgColor
        videoArea.appearance = NSAppearance(named: .darkAqua)

        playerView.player = player
        playerView.controlsStyle = .none
        playerView.videoGravity = .resizeAspect
        playerView.addGestureRecognizer(videoClick)

        spinner.style = .spinning
        spinner.isDisplayedWhenStopped = false

        messageLabel.alignment = .center
        messageLabel.textColor = .secondaryLabelColor
    }

    private func layOutViews() {
        for view in [videoArea, controlBar, playerView, spinner, messageLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        addSubview(videoArea)
        addSubview(controlBar)
        videoArea.addSubview(playerView)
        videoArea.addSubview(spinner)
        videoArea.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            videoArea.topAnchor.constraint(equalTo: topAnchor),
            videoArea.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoArea.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoAboveControls,

            controlBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            controlBarBottom,

            playerView.topAnchor.constraint(equalTo: videoArea.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: videoArea.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: videoArea.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: videoArea.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: videoArea.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: videoArea.centerYAnchor),

            messageLabel.centerXAnchor.constraint(equalTo: videoArea.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: videoArea.centerYAnchor),
            messageLabel.widthAnchor.constraint(lessThanOrEqualTo: videoArea.widthAnchor, constant: -40),
        ])
    }
}
