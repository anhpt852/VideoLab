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

        // ✅ ADD NEW OBSERVER
        let name3 = Notification.Name(
            rawValue: VLEConstants.VLETimeLineOverlayOnlyWarningNotification)
        NotificationCenter.default.addObserver(
            self, selector: #selector(showOverlayOnlyWarning), name: name3,
            object: nil)
    }

    deinit {
        clearAllTextOverlays()
        if let observer = textPreviewTimeObserver {
            player?.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
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

                    // ✅ UPDATE TEXT OVERLAYS BASED ON TIME
                    self.updateTextOverlaysForTime(time)
                })
        }

        // ✅ SETUP TEXT PREVIEW TRACKING
        setupTextPreviewTracking(for: videoLab)

        let audioTracks = playerItem.asset.tracks(withMediaType: .audio)
        if !audioTracks.isEmpty {
            print("✅ Audio tracks found: \(audioTracks.count)")
            for (index, track) in audioTracks.enumerated() {
                print(
                    "🔍 Audio track \(index): enabled=\(track.isEnabled), volume=\(track.preferredVolume)"
                )
            }
        } else {
            print("❌ No audio tracks in video")
        }
        self.player?.seek(to: CMTime.init(seconds: 0, preferredTimescale: 600))
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
}

extension VLEPlaybackViewController: VLEPlaybackControlViewDelegate {

    func playbackControlView(
        _ view: VLEPlaybackControlView, clickPlaybackButton button: UIButton
    ) {
        self.player?.play()
    }
}
