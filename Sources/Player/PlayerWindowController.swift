import AppKit
import AVFoundation
import PlayerCore

@MainActor
final class PlayerWindowController: NSWindowController {
    private static let loaderDuration: Duration = .milliseconds(500)
    private static let maxScreenShare: CGFloat = 0.8

    private let player: AVPlayer
    private let controlBar: ControlBar
    private let contentView: PlayerContentView

    private var rules = PlaybackRules()
    private var loadTask: Task<Void, Never>?
    private var endObserver: NSObjectProtocol?
    private var timeObserver: Any?
    private var playbackObservation: NSKeyValueObservation?

    init() {
        let player = AVPlayer()
        let controlBar = ControlBar()
        self.player = player
        self.controlBar = controlBar
        contentView = PlayerContentView(player: player, controlBar: controlBar)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 450 + ControlBar.height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = Bundle.main.displayName
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 680, height: 240)
        window.collectionBehavior = [.fullScreenPrimary]
        window.contentView = contentView
        window.center()
        super.init(window: window)

        connectControls()
        controlBar.showEndBehavior(rules.endBehavior)
        observePlayer()
        contentView.showMessage(String(localized: "message.openHint"))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func open(_ url: URL) {
        loadTask?.cancel()
        player.pause()
        player.replaceCurrentItem(with: nil)
        removeEndObserver()
        rules.didOpenNewVideo()

        window?.title = url.lastPathComponent
        controlBar.setVideoLoaded(false)
        controlBar.showTime(current: 0, duration: 0)
        contentView.showLoading()

        loadTask = Task { [weak self] in
            await self?.load(url)
        }
    }

    private func load(_ url: URL) async {
        let loaderEnd = ContinuousClock.now + Self.loaderDuration
        let asset = AVURLAsset(url: url)
        let videoSize: CGSize?
        do {
            let isPlayable = try await asset.load(.isPlayable)
            guard !Task.isCancelled else { return }
            guard isPlayable else {
                contentView.showMessage(String(localized: "message.unplayable \(url.lastPathComponent)"))
                return
            }
            videoSize = try await displaySize(of: asset)
        } catch {
            guard !Task.isCancelled else { return }
            contentView.showMessage(String(localized: "message.openFailed \(url.lastPathComponent) \(error.localizedDescription)"))
            return
        }

        try? await Task.sleep(until: loaderEnd)
        guard !Task.isCancelled else { return }

        let item = AVPlayerItem(asset: asset)
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleEnd() }
        }
        player.replaceCurrentItem(with: item)
        if let videoSize {
            fitWindow(to: videoSize)
        }

        contentView.showVideo()
        controlBar.setVideoLoaded(true)
        player.play()
    }

    private func displaySize(of asset: AVURLAsset) async throws -> CGSize? {
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { return nil }
        let (naturalSize, transform) = try await track.load(.naturalSize, .preferredTransform)
        return VideoGeometry.displaySize(naturalSize: naturalSize, transform: transform)
    }

    private func handleEnd() {
        switch rules.videoDidEnd() {
        case .stayOnLastFrame:
            break
        case .playFromStart:
            player.seek(to: .zero)
            player.play()
        case .rewindToStart:
            player.seek(to: .zero)
        }
    }

    @objc private func togglePlayPause() {
        guard player.currentItem != nil else { return }
        if player.timeControlStatus != .paused {
            player.pause()
            return
        }
        if rules.startPlayback() == .fromBeginning {
            player.seek(to: .zero)
        }
        player.play()
    }

    @objc private func scrub(_ sender: NSSlider) {
        rules.didSeek()
        let target = CMTime(seconds: sender.doubleValue, preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    @objc private func changeEndBehavior(_ sender: NSSegmentedControl) {
        rules.endBehavior = controlBar.selectedEndBehavior
    }

    private func observePlayer() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 30),
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshTime() }
        }
        playbackObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self?.refreshPlayButton() }
            }
        }
    }

    private func refreshTime() {
        let current = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 0
        controlBar.showTime(
            current: current.isFinite ? current : 0,
            duration: duration.isFinite ? duration : 0
        )
    }

    private func refreshPlayButton() {
        controlBar.showPlaying(player.timeControlStatus != .paused)
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }

    private func fitWindow(to videoSize: CGSize) {
        guard let window,
              !window.styleMask.contains(.fullScreen),
              let screen = window.screen ?? NSScreen.main,
              videoSize.width > 0, videoSize.height > 0
        else { return }

        let available = screen.visibleFrame
        let contentSize = WindowFitting.contentSize(
            forVideo: videoSize,
            available: available,
            controlBarHeight: ControlBar.height,
            minimumContentSize: window.contentMinSize,
            maxScreenShare: Self.maxScreenShare
        )
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize))
        frame.origin = WindowFitting.origin(forFrameSize: frame.size, centeredOn: window.frame, within: available)
        window.setFrame(frame, display: true)
    }

    private func connectControls() {
        controlBar.playButton.target = self
        controlBar.playButton.action = #selector(togglePlayPause)
        controlBar.slider.target = self
        controlBar.slider.action = #selector(scrub(_:))
        controlBar.endBehaviorControl.target = self
        controlBar.endBehaviorControl.action = #selector(changeEndBehavior(_:))
    }
}
