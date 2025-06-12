//
//  CaptureFrameViewController.swift
//  VideoLab
//
//  Created by PTA on 13/6/25.
//  Copyright © 2025 Chocolate. All rights reserved.
//


import UIKit
import AVFoundation
import VideoLab

class CaptureFrameViewController: UIViewController {

    let playerView = VideoPlayerView()
    let slider = UISlider()
    let playButton = UIButton()
    let captureButton = UIButton()

    var videoLab: VideoLab!
    var duration: CMTime = .zero
    var timeObserver: Any?
    var originalAsset: AVAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupVideoLab()
    }

    func setupUI() {
        view.backgroundColor = .black

        // Player view
        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)

        // Slider
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        view.addSubview(slider)

        // Play button
        playButton.setTitle("▶️", for: .normal)
        playButton.setTitleColor(.systemBlue, for: .normal)
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playButton)

        // Capture button
        captureButton.setTitle("📸 Capture", for: .normal)
        captureButton.setTitleColor(.systemGreen, for: .normal)
        captureButton.addTarget(self, action: #selector(captureFrame), for: .touchUpInside)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)

        // Auto Layout
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9.0/16.0),

            slider.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 20),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            playButton.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 20),
            playButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),

            captureButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            captureButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
    }


    func setupVideoLab() {

        let url = Bundle.main.url(forResource: "video1", withExtension: "MOV")
        let asset = AVAsset(url: url!)
        originalAsset = asset
        duration = asset.duration
        
        let source = AVAssetSource(asset: asset)
        source.selectedTimeRange = CMTimeRange(start: CMTime.zero, duration: asset.duration)
        let timeRange = source.selectedTimeRange
        let renderLayer1 = RenderLayer(timeRange: timeRange, source: source)
        
        // 1. Keyframe animation
        let keyTimes = [CMTime(seconds: 2, preferredTimescale: 600),
                        CMTime(seconds: 4, preferredTimescale: 600),
                        CMTime(seconds: 6, preferredTimescale: 600)]
        let animation = KeyframeAnimation(keyPath: "blendOpacity",
                                          values: [1.0, 0.2, 1.0],
                                          keyTimes: keyTimes, timingFunctions: [.linear, .linear])
        renderLayer1.animations = [animation]
        
        var transform = Transform.identity
        let animation1 = KeyframeAnimation(keyPath: "scale",
                                           values: [1.0, 1.3, 1.0],
                                           keyTimes: keyTimes, timingFunctions: [.quadraticEaseInOut, .quadraticEaseInOut])
        let animation2 = KeyframeAnimation(keyPath: "rotation",
                                           values: [0, Float.pi / 2.0, 0],
                                           keyTimes: keyTimes, timingFunctions: [.quadraticEaseInOut, .quadraticEaseInOut])
        transform.animations = [animation1, animation2]
        renderLayer1.transform = transform
        
        // 2. Composition
        let composition = RenderComposition()
        composition.renderSize = CGSize(width: 1280, height: 720)
        composition.layers = [renderLayer1]

        // 3. VideoLab
        videoLab = VideoLab(renderComposition: composition)

        let item = videoLab.makePlayerItem()
        item.seekingWaitsForVideoCompositionRendering = true

        let player = AVPlayer(playerItem: item)
        playerView.player = player

        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.slider.value = Float(time.seconds / self.duration.seconds)
        }

        player.play()
    }


    
    @objc func togglePlay() {
        guard let player = playerView.player else { return }
        if player.timeControlStatus == .paused {
            player.play()
        } else {
            player.pause()
        }
    }

    @objc func sliderChanged(_ sender: UISlider) {
        guard let player = playerView.player else { return }
        let newTime = Double(sender.value) * duration.seconds
        let time = CMTime(seconds: newTime, preferredTimescale: 600)
        player.seek(to: time)
    }


    @objc func captureFrame() {
        guard let asset = originalAsset else { return }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let time = playerView.player?.currentTime() ?? .zero

        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
            if let cgImage = cgImage {
                let image = UIImage(cgImage: cgImage)
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            } else {
                print("Error capturing image:", error ?? "unknown")
            }
        }
    }

    deinit {
        if let observer = timeObserver {
            playerView.player?.removeTimeObserver(observer)
        }
    }
}


class VideoPlayerView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
}
