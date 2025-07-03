//
//  VLEPlaybackViewController.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/7/21.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit
import VideoLab

class VLEPlaybackViewController: UIViewController {

    lazy var playbackControlView: VLEPlaybackControlView = {
        let view = VLEPlaybackControlView.init(delegate: self)
        return view
    }()

    lazy var playbackView: VLEPlaybackView = {
        let view = VLEPlaybackView.init()
        return view
    }()

    lazy var hintLabel: UILabel = {
        let label = UILabel.init()
        label.text = "Tap the + below to add media"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = UIColor.init(hexString: "#FFFFFF")
        return label
    }()

    var player: AVPlayer?
    var playLayer: AVPlayerLayer?

    // ✅ ADD: Track observer state
    private var isObservingPlayerRate = false
    private var currentPlayerItem: AVPlayerItem?

    private var activeTextOverlays: [UILabel] = []
    private var textPreviewTimeObserver: Any?

    override func viewDidLoad() {

        self.view.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.snp.bottom).offset(-20)
        }

        self.view.addSubview(playbackView)
        playbackView.snp.makeConstraints({ make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        })

        self.view.addSubview(playbackControlView)
        playbackControlView.snp.makeConstraints({ make in
            make.height.equalTo(40)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.snp_bottomMargin)
        })

        playbackView.isHidden = true
        playbackControlView.isHidden = true
        addObserverFromNotification()
    }

    // ✅ MODIFY EXISTING addObserverFromNotification() method
    func addObserverFromNotification() {
        let name1 = Notification.Name(
            rawValue: VLEConstants.VLETimeLineAssetDidIsEmptyNotification)
        let name2 = Notification.Name(
            rawValue: VLEConstants.VLETimeLineAssetDidIsNonemptyNotification)
        NotificationCenter.default.addObserver(
            self, selector: #selector(assetDidIsEmpty), name: name1, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(assetDidIsNonempty), name: name2,
            object: nil)

        let name3 = Notification.Name(
            rawValue: VLEConstants.VLETimeLineOverlayOnlyWarningNotification)
        NotificationCenter.default.addObserver(
            self, selector: #selector(showOverlayOnlyWarning), name: name3,
            object: nil)
    }

    deinit {
        print("🗑️ VLEPlaybackViewController deinit started")

        clearAllTextOverlays()

        if let observer = textPreviewTimeObserver {
            player?.removeTimeObserver(observer)
            textPreviewTimeObserver = nil
        }

        // ✅ Safe KVO removal
        removePlayerObservers()

        // ✅ Safe notification removal
        NotificationCenter.default.removeObserver(self)

        print("🗑️ VLEPlaybackViewController cleaned up successfully")
    }

    private func removePlayerObservers() {
        // ✅ Remove KVO observer safely
        if isObservingPlayerRate, let player = self.player {
            do {
                player.removeObserver(self, forKeyPath: "rate")
                isObservingPlayerRate = false
                print("✅ KVO observer removed successfully")
            } catch {
                print("⚠️ KVO observer was not registered: \(error)")
            }
        }

        // ✅ Remove notification observer safely
        if let currentItem = currentPlayerItem {
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: currentItem
            )
            currentPlayerItem = nil
            print("✅ Notification observer removed successfully")
        }
    }

    private func addPlayerObservers() {
        guard let player = self.player else {
            print("⚠️ Cannot add observers: player is nil")
            return
        }

        // ✅ Remove existing observers first
        removePlayerObservers()

        // ✅ Add KVO observer safely
        if !isObservingPlayerRate {
            do {
                player.addObserver(
                    self, forKeyPath: "rate", options: [.new, .old],
                    context: nil)
                isObservingPlayerRate = true
                print("✅ KVO observer added successfully")
            } catch {
                print("❌ Failed to add KVO observer: \(error)")
            }
        }

        // ✅ Add notification observer safely
        if let playerItem = player.currentItem {
            currentPlayerItem = playerItem
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerItem
            )
            print("✅ Notification observer added successfully")
        }
    }

    // ✅ MODIFY EXISTING assetDidIsEmpty() method
    @objc func assetDidIsEmpty() {
        if hintLabel.isHidden == true {
            hintLabel.isHidden = false
            playbackView.isHidden = true
            playbackControlView.isHidden = true

            // ✅ UPDATE HINT TEXT
            hintLabel.text = "Tap the + below to add media"
            hintLabel.textColor = UIColor(hexString: "#FFFFFF")
        }
    }

    // ✅ MODIFY EXISTING assetDidIsNonempty() method
    @objc func assetDidIsNonempty() {
        if hintLabel.isHidden == false {
            hintLabel.isHidden = true
            playbackView.isHidden = false
            playbackControlView.isHidden = false
        }
    }

    // ✅ ADD NEW METHOD FOR OVERLAY WARNING
    @objc func showOverlayOnlyWarning() {
        if hintLabel.isHidden == true {
            hintLabel.isHidden = false
            hintLabel.text = "⚠️ 仅有浮层视频，建议添加主时间线视频"
            hintLabel.textColor = UIColor(hexString: "#FFB84D")  // Orange warning

            // Auto hide after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.hintLabel.isHidden = true
            }
        }
    }

    func previewItem(with rate: Float64) {
        if let duration = self.player?.currentItem?.duration {
            let seekTime = CMTimeMultiplyByFloat64(duration, multiplier: rate)
            self.player?.currentItem?.cancelPendingSeeks()
            self.player?.seek(
                to: seekTime, toleranceBefore: CMTime.zero,
                toleranceAfter: CMTime.zero)
        }
    }

    func previewItem(with videoLab: VideoLab) {
        let playerItem = videoLab.makePlayerItem()
        playerItem.seekingWaitsForVideoCompositionRendering = true

        if self.player != nil {
            // ✅ Safe cleanup before replacing
            removePlayerObservers()
            self.player?.replaceCurrentItem(with: playerItem)
        } else {
            self.player = AVPlayer(playerItem: playerItem)
            self.player?.volume = 1.0
            self.player?.isMuted = false

            let avplayerLayer = AVPlayerLayer.init(player: self.player)
            avplayerLayer.videoGravity = .resizeAspect
            let bounds = playbackView.bounds
            avplayerLayer.frame = bounds
            playbackView.layer.addSublayer(avplayerLayer)

            let time = CMTime.init(seconds: 0.1, preferredTimescale: 600)
            self.player?.addPeriodicTimeObserver(
                forInterval: time, queue: DispatchQueue.main,
                using: { [weak self] time in
                    guard let self = self else { return }
                    self.playbackControlView.timeLabel.text =
                        self.convertSecond(for: time)
                    VLEMainConcreteMediator.shared
                        .playbackProgressValueDidChanged(currentTime: time)
                    self.updateTextOverlaysForTime(time)
                })
        }

        // ✅ Setup observers after player is ready
        addPlayerObservers()

        // Apply audio mixing
        applyBalancedAudioMixing(to: playerItem)
        setupTextPreviewTracking(for: videoLab)

        let audioTracks = playerItem.asset.tracks(withMediaType: .audio)
        print("🔍 Total audio tracks in composition: \(audioTracks.count)")

        self.player?.seek(to: CMTime.init(seconds: 0, preferredTimescale: 600))
    }

    @objc private func playerDidFinishPlaying() {
        DispatchQueue.main.async {
            self.playbackControlView.updateForPaused()
            print("🏁 Playback finished - button reset to play")
        }
    }

    private func applyBalancedAudioMixing(to playerItem: AVPlayerItem) {
        createSmartAudioMix(for: playerItem)
    }

    private func setupTextPreviewTracking(for videoLab: VideoLab) {
        // Clear existing text overlays
        clearAllTextOverlays()

        let composition = videoLab.renderComposition
        guard let animationLayer = composition.animationLayer else {
            print("🎭 No animation layer to preview")
            return
        }

        // Create text preview overlay
        if let textLayer = animationLayer as? TextOpacityAnimationLayer {
            createPersistentTextOverlay(from: textLayer)
        } else if let textLayer = animationLayer as? TextAnimationLayer {
            createPersistentTextOverlay(from: textLayer)
        }
    }

    private func createPersistentTextOverlay(from textLayer: TextAnimationLayer)
    {
        // Same implementation as TextOpacityAnimationLayer
        print("🎭 Creating persistent text overlay from TextAnimationLayer...")

        let previewLabel = UILabel()
        previewLabel.attributedText = textLayer.attributedText
        previewLabel.numberOfLines = 0
        previewLabel.tag = 9999
        previewLabel.alpha = 0

        // Same positioning code...
        let videoSize = CGSize(width: 1280, height: 720)
        let playbackViewSize = self.view.bounds.size
        let scale = min(
            playbackViewSize.width / videoSize.width,
            playbackViewSize.height / videoSize.height)

        let videoLabPosition = textLayer.position
        let uiKitX = videoLabPosition.x * scale
        let uiKitY = videoLabPosition.y * scale

        let scaledVideoWidth = videoSize.width * scale
        let scaledVideoHeight = videoSize.height * scale
        let xOffset = (playbackViewSize.width - scaledVideoWidth) / 2
        let yOffset = (playbackViewSize.height - scaledVideoHeight) / 2

        let finalX = uiKitX + xOffset
        let finalY = uiKitY + yOffset

        let textBounds = textLayer.bounds
        let scaledWidth = textBounds.width * scale
        let scaledHeight = textBounds.height * scale

        previewLabel.frame = CGRect(
            x: finalX - scaledWidth / 2,
            y: finalY - scaledHeight / 2,
            width: scaledWidth,
            height: scaledHeight
        )

        previewLabel.layer.shadowColor = UIColor.black.cgColor
        previewLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        previewLabel.layer.shadowOpacity = 0.8
        previewLabel.layer.shadowRadius = 2
        previewLabel.layer.borderColor =
            UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        previewLabel.layer.borderWidth = 1
        previewLabel.layer.cornerRadius = 4

        self.view.addSubview(previewLabel)
        activeTextOverlays.append(previewLabel)
    }

    private func updateTextOverlaysForTime(_ currentTime: CMTime) {
        let currentSeconds = CMTimeGetSeconds(currentTime)

        // For now, show text throughout the video
        // In the future, can add time-based visibility based on text timing
        for overlay in activeTextOverlays {
            if overlay.alpha == 0 && currentSeconds > 0.5 {  // Show after 0.5s
                UIView.animate(withDuration: 0.3) {
                    overlay.alpha = 1.0
                }
            }
        }
    }

    func clearAllTextOverlays() {
        activeTextOverlays.forEach { overlay in
            overlay.removeFromSuperview()
        }
        activeTextOverlays.removeAll()
        print("🗑️ All text overlays cleared from playback view")
    }
    func playbackItem(with videoLab: VideoLab) {
        self.player?.play()
    }

    func convertSecond(for time: CMTime) -> String {
        let origSecond = Int(CMTimeGetSeconds(time))
        switch origSecond {
        case 0..<60:
            return String(format: "00:%02d", origSecond)
        case 60..<3600:
            let minute = origSecond / 60
            let second = origSecond % 60
            return String(format: "%02d:%02d", minute, second)
        case 3600...:
            let hour = origSecond / 3600
            let minute = (origSecond % 3600) / 60
            let second = origSecond % 60
            return String(format: "%02d:%02d:%02d", hour, minute, second)
        default:
            return ""
        }
    }

    private func applyAudioStateToPlayer() {
        guard
            let timelineVC = VLEMainConcreteMediator.shared
                .timelineViewController,
            let player = self.player,
            let playerItem = player.currentItem
        else {
            return
        }

        if timelineVC.stateModel.isVideoAudioMuted {
            createPlayerLevelAudioMix(for: playerItem)
            print("🔇 Applied player-level audio muting")
        } else {
            playerItem.audioMix = nil
            print("🔊 Removed player-level audio muting")
        }
    }

    private func createPlayerLevelAudioMix(for playerItem: AVPlayerItem) {
        let asset = playerItem.asset
        let audioTracks = asset.tracks(withMediaType: .audio)

        guard !audioTracks.isEmpty else { return }

        let audioMix = AVMutableAudioMix()
        var inputParameters: [AVMutableAudioMixInputParameters] = []

        for audioTrack in audioTracks {
            let audioInputParams = AVMutableAudioMixInputParameters(
                track: audioTrack)
            audioInputParams.setVolume(0.0, at: CMTime.zero)
            inputParameters.append(audioInputParams)
        }

        audioMix.inputParameters = inputParameters
        playerItem.audioMix = audioMix
    }

    private func createSmartAudioMix(for playerItem: AVPlayerItem) {
        guard
            let timelineVC = VLEMainConcreteMediator.shared
                .timelineViewController
        else { return }

        let asset = playerItem.asset
        let audioTracks = asset.tracks(withMediaType: .audio)
        let composition = asset as? AVMutableComposition

        guard !audioTracks.isEmpty else {
            print("⚠️ No audio tracks to mix")
            return
        }

        print("🎛️ === SMART AUDIO MIXING ===")
        print("🎛️ Total audio tracks: \(audioTracks.count)")

        let isVideoMuted = timelineVC.stateModel.isVideoAudioMuted
        let mainTrackDuration = timelineVC.stateModel
            .calculateMainTrackDuration()
        let mainDurationSeconds = CMTimeGetSeconds(mainTrackDuration)

        print("🎛️ Main track duration: \(mainDurationSeconds)s")
        print("🎛️ Video audio muted: \(isVideoMuted)")

        // ✅ Calculate video track count and added audio info
        let videoTrackCount = timelineVC.stateModel.renderTrackItemModelArray
            .filter { $0.type == .video }.count
        let addedAudioItems = timelineVC.stateModel
            .separateRenderTrackItemModelArray.filter { $0.type == .audio }

        let audioMix = AVMutableAudioMix()
        var inputParameters: [AVMutableAudioMixInputParameters] = []

        // ✅ Process each audio track with smart volume management
        for (index, audioTrack) in audioTracks.enumerated() {
            let audioInputParams = AVMutableAudioMixInputParameters(
                track: audioTrack)

            if index < videoTrackCount {
                // ✅ Video audio track
                handleVideoAudioTrack(
                    audioInputParams, audioTrack: audioTrack,
                    isVideoMuted: isVideoMuted, mainDuration: mainTrackDuration,
                    addedAudioItems: addedAudioItems)
            } else {
                // ✅ Added audio track
                handleAddedAudioTrack(
                    audioInputParams, audioTrack: audioTrack,
                    trackIndex: index - videoTrackCount,
                    isVideoMuted: isVideoMuted, mainDuration: mainTrackDuration,
                    addedAudioItems: addedAudioItems)
            }

            inputParameters.append(audioInputParams)
        }

        audioMix.inputParameters = inputParameters
        playerItem.audioMix = audioMix

        print("✅ Smart audio mix applied!")
        print("🎛️ === END SMART MIXING ===")
    }

    private func handleVideoAudioTrack(
        _ params: AVMutableAudioMixInputParameters, audioTrack: AVAssetTrack,
        isVideoMuted: Bool, mainDuration: CMTime,
        addedAudioItems: [VLETimeLineItemModel]
    ) {

        if isVideoMuted {
            // ✅ REPLACE MODE: Mute video audio completely
            params.setVolume(0.0, at: CMTime.zero)
            print("🔇 Video audio: MUTED (replace mode)")
        } else if !addedAudioItems.isEmpty {
            // ✅ MIX MODE: Smart mixing based on added audio coverage
            let addedAudioDuration = calculateAddedAudioCoverage(
                addedAudioItems)
            let addedAudioSeconds = CMTimeGetSeconds(addedAudioDuration)
            let mainDurationSeconds = CMTimeGetSeconds(mainDuration)

            if addedAudioSeconds >= mainDurationSeconds {
                // ✅ Added audio covers full video - reduce video volume
                params.setVolume(0.4, at: CMTime.zero)  // 40% volume for balance
                print("🔉 Video audio: 40% volume (full coverage mix)")
            } else {
                // ✅ Added audio is shorter - variable mixing
                // Full mix during added audio period
                params.setVolume(0.4, at: CMTime.zero)
                // Return to full volume after added audio ends
                params.setVolume(1.0, at: addedAudioDuration)
                print(
                    "🔉 Video audio: 40% → 100% at \(addedAudioSeconds)s (partial coverage)"
                )
            }
        } else {
            // ✅ No added audio - full video volume
            params.setVolume(1.0, at: CMTime.zero)
            print("🔊 Video audio: FULL volume (no added audio)")
        }
    }

    private func handleAddedAudioTrack(
        _ params: AVMutableAudioMixInputParameters, audioTrack: AVAssetTrack,
        trackIndex: Int, isVideoMuted: Bool, mainDuration: CMTime,
        addedAudioItems: [VLETimeLineItemModel]
    ) {

        guard trackIndex < addedAudioItems.count else {
            params.setVolume(0.0, at: CMTime.zero)
            return
        }

        let audioItem = addedAudioItems[trackIndex]
        let audioDuration = audioItem.source.selectedTimeRange.duration
        let audioStartTime = audioItem.globalStartTime
        let audioEndTime = CMTimeAdd(audioStartTime, audioDuration)

        let mainDurationSeconds = CMTimeGetSeconds(mainDuration)
        let audioEndSeconds = CMTimeGetSeconds(audioEndTime)

        print(
            "🎵 Added audio \(trackIndex): \(CMTimeGetSeconds(audioStartTime))s - \(audioEndSeconds)s"
        )

        if isVideoMuted {
            // ✅ REPLACE MODE: Added audio at full volume
            params.setVolume(1.0, at: audioStartTime)
            params.setVolume(0.0, at: audioEndTime)  // Silence after audio ends
            print("🔊 Added audio: FULL volume (replace mode)")
        } else {
            // ✅ MIX MODE: Balanced volume
            params.setVolume(0.0, at: CMTime.zero)  // Start silent
            params.setVolume(0.7, at: audioStartTime)  // 70% during playback
            params.setVolume(0.0, at: audioEndTime)  // Silent after end
            print("🔉 Added audio: 0% → 70% → 0% (mix mode)")
        }
    }

    private func calculateAddedAudioCoverage(
        _ addedAudioItems: [VLETimeLineItemModel]
    ) -> CMTime {
        guard !addedAudioItems.isEmpty else { return CMTime.zero }

        var latestEndTime = CMTime.zero

        for audioItem in addedAudioItems {
            let audioEndTime = CMTimeAdd(
                audioItem.globalStartTime,
                audioItem.source.selectedTimeRange.duration)
            if CMTimeCompare(audioEndTime, latestEndTime) > 0 {
                latestEndTime = audioEndTime
            }
        }

        return latestEndTime
    }

    override func observeValue(
        forKeyPath keyPath: String?, of object: Any?,
        change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?
    ) {

        guard keyPath == "rate", let player = object as? AVPlayer else {
            super.observeValue(
                forKeyPath: keyPath, of: object, change: change,
                context: context)
            return
        }

        // ✅ Verify this is our player
        guard player === self.player else {
            print("⚠️ Received rate change from different player")
            return
        }

        DispatchQueue.main.async {
            if player.rate > 0 {
                self.playbackControlView.updateForPlaying()
                print("▶️ Player state: Playing (rate: \(player.rate))")
            } else {
                self.playbackControlView.updateForPaused()
                print("⏸️ Player state: Paused (rate: \(player.rate))")
            }
        }
    }
}

extension VLEPlaybackViewController: VLEPlaybackControlViewDelegate {

    func playbackControlView(
        _ view: VLEPlaybackControlView, clickPlaybackButton button: UIButton,
        action: VLEPlaybackAction
    ) {
        switch action {
        case .play:
            self.player?.play()
            view.updateForPlaying()
            print("▶️ Playback started")
        case .pause:
            self.player?.pause()
            view.updateForPaused()
            print("⏸️ Playback paused")
        }
    }
}
