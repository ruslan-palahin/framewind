import AppKit
import AVKit

@MainActor
final class PlayerContentView: NSView {
    private let videoArea = NSView()
    private let playerView = AVPlayerView()
    private let spinner = NSProgressIndicator()
    private let messageLabel = NSTextField(wrappingLabelWithString: "")
    private let controlBar: ControlBar

    init(player: AVPlayer, controlBar: ControlBar) {
        self.controlBar = controlBar
        super.init(frame: .zero)
        configureViews(player: player)
        layOutViews()
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

    private func configureViews(player: AVPlayer) {
        videoArea.wantsLayer = true
        videoArea.layer?.backgroundColor = NSColor.black.cgColor
        videoArea.appearance = NSAppearance(named: .darkAqua)

        playerView.player = player
        playerView.controlsStyle = .none
        playerView.videoGravity = .resizeAspect

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
            videoArea.bottomAnchor.constraint(equalTo: controlBar.topAnchor),

            controlBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            controlBar.bottomAnchor.constraint(equalTo: bottomAnchor),

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
