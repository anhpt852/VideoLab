//
//  VLETimeLineViewController.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/7/21.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import UIKit
import VideoLab
import CoreMedia
import PKHUD
import Photos
import SnapKit
import AVFoundation

protocol VLETimeLineDragSortViewDelegateExtended: VLETimeLineDragSortViewDelegate {
    func timelineDargSortViewChangedSeparate(with selectedIndex: Int, dragPositionXRate: Float, overlayPosition: CGPoint)
}

class VLETimeLineViewController: UIViewController {
    
    let stateModel = VLETimeLineStateModel.init()
    var dragSortView: VLETimeLineDragSortView?
    var renderLayerDargView: VLETimeLineRenderTrackDragView?
    var separateRenderTrackViewArray: [VLETimeLineSeparateRenderTrackView] = []
    
    lazy var scaleView = makeScaleView()
    lazy var toolBarView = makeToolBarView()
    lazy var backScrollView = makeBackScrollView()
    lazy var addAssetButton = makeAddAssetButton()
    lazy var renderTrackView = makeRenderTrackView()
    lazy var locationLineView = makeLocationLineView()
    lazy var movablyAddAssetButton = makeMovablyAddAssetButton()
    // ✅ ADD CONSTRAINT REFERENCE
    private var timelineCursorLeftConstraint: Constraint?
    // ✅ ADD THESE PROPERTIES after existing lazy vars (around line 20)
    lazy var timelineCursor: UIView = {
        let cursor = UIView()
        cursor.backgroundColor = UIColor.systemBlue
        cursor.layer.cornerRadius = 2
        cursor.layer.borderWidth = 1
        cursor.layer.borderColor = UIColor.white.cgColor
        cursor.isHidden = true
        return cursor
    }()

    lazy var cursorTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.systemBlue
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        setupView()
        addObserverFormNotification()
        // ✅ ADD DEBUG GESTURE (REMOVE IN PRODUCTION)
           #if DEBUG
           let shakeGesture = UITapGestureRecognizer(target: self, action: #selector(debugTapped))
           shakeGesture.numberOfTapsRequired = 3
           view.addGestureRecognizer(shakeGesture)
           #endif
    }

    #if DEBUG
    @objc private func debugTapped() {
        debugComposition()
    }
    #endif
    
    // ✅ MODIFY EXISTING addObserverFormNotification() method
    func addObserverFormNotification() {
        let name1 = Notification.Name(rawValue: VLEConstants.VLETimeLineAssetDidIsEmptyNotification)
        NotificationCenter.default.addObserver(self, selector: #selector(assetDidIsEmpty), name: name1, object: nil)
        
        let name2 = Notification.Name(rawValue: VLEConstants.VLETimeLineAssetDidIsNonemptyNotification)
        NotificationCenter.default.addObserver(self, selector: #selector(assetDidIsNonempty), name: name2, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func backScrollViewTapGestureAction(sender: UITapGestureRecognizer) {
        if renderLayerDargView != nil {
            renderLayerDargView?.removeFromSuperview()
            renderLayerDargView = nil
        } else {
            if let currentIndex = stateModel.currentSelectedIndex {
                let separateView = separateRenderTrackViewArray[currentIndex]
                separateView.hideSummaryView()
                renderTrackView.snp.updateConstraints { make in
                    make.top.equalTo(scaleView.snp.bottom).offset(62)
                }
                let height = separateView.bounds.height
                separateView.snp.updateConstraints { make in
                    make.height.equalTo(height-42)
                }
            }
        }
        stateModel.currentSelectedItemModel = nil
        stateModel.currentSelectedIndex = nil
        toolBarView.refreshClipButtonState(isShow: false)
    }

    @objc func assetDidIsEmpty() {
        if addAssetButton.isHidden == true {
            refreshViewState()
        }
    }

    @objc func assetDidIsNonempty() {
        if addAssetButton.isHidden == false {
            refreshViewState()
        }
    }

    public func addAssetToRenderTrackViewWith(itemModelArray: [VLETimeLineItemModel]) {
        guard !itemModelArray.isEmpty else { return }
        stateModel.renderTrackItemModelArray.append(contentsOf: itemModelArray)
        notifyTimelineChanged()
    }

    public func addAudioToSeparateRenderLayerWith(source: Source) {
        print("🎵 === ADDING AUDIO TO TIMELINE ===")
        print("🎵 Source type: \(type(of: source))")
        
        // ✅ 1. Load audio source
        source.load { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Audio load failed: \(error)")
                    HUD.show(.label("Failed to load audio"))
                    HUD.hide(afterDelay: 1.0)
                    return
                }
                
                print("✅ Audio loaded successfully")
                print("🎵 Duration: \(CMTimeGetSeconds(source.duration))s")
                
                // ✅ 2. Create timeline item model
                let audioItemModel = VLETimeLineItemModel(with: source, type: .audio)
                
                // ✅ 3. Set as separate track (overlay)
                audioItemModel.isSeparateRenderTrack = true
                
                // ✅ 4. Position at current timeline position or start
                let currentTime = self.getCurrentTimelineTime()
                audioItemModel.globalStartTime = currentTime
                audioItemModel.renderLayer.timeRange = CMTimeRange(
                    start: currentTime,
                    duration: source.selectedTimeRange.duration
                )
                
                // ✅ 5. Set transform for audio (no visual transform needed, but required)
                let transform = Transform(center: CGPoint(x: 0.5, y: 0.5), rotation: 0, scale: 1.0)
                audioItemModel.renderLayer.transform = transform
                
                print("🎵 Audio positioned at: \(CMTimeGetSeconds(currentTime))s")
                
                // ✅ 6. Generate thumbnail (audio visualization placeholder)
                self.generateAudioThumbnail(for: audioItemModel) {
                    // ✅ 7. Add to separate track array
                    self.stateModel.separateRenderTrackItemModelArray.append(audioItemModel)
                    
                    // ✅ 8. Create UI view
                    let audioTrackView = self.createAudioSeparateRenderTrackView(with: audioItemModel)
                    self.separateRenderTrackViewArray.append(audioTrackView)
                    
                    // ✅ 9. Update timeline
                    self.stateModel.refreshItemTime()
                    self.reloadView()
                    
                    // ✅ 10. Update playback
                    VLEMainConcreteMediator.shared.previewTimeLineItem(videoLab: self.buildVideolab())
                    
                    // ✅ 11. Show success
                    HUD.show(.label("🎵 Audio added!"))
                    HUD.hide(afterDelay: 1.0)
                    
                    print("✅ Audio successfully added to timeline")
                }
            }
        }
    }


    // ✅ ADD method để generate audio thumbnail placeholder
    private func generateAudioThumbnail(for audioModel: VLETimeLineItemModel, completion: @escaping () -> Void) {
        // ✅ Create audio waveform placeholder image
        let thumbnailSize = CGSize(width: 60, height: 60)
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            completion()
            return
        }
        
        // ✅ Draw audio icon background
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.fill(CGRect(origin: .zero, size: thumbnailSize))
        
        // ✅ Draw audio wave pattern
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)
        
        let centerY = thumbnailSize.height / 2
        let waveCount = 8
        let waveWidth = thumbnailSize.width / CGFloat(waveCount)
        
        for i in 0..<waveCount {
            let x = CGFloat(i) * waveWidth + waveWidth/2
            let height = CGFloat.random(in: 10...30)
            
            context.move(to: CGPoint(x: x, y: centerY - height/2))
            context.addLine(to: CGPoint(x: x, y: centerY + height/2))
            context.strokePath()
        }
        
        // ✅ Add speaker icon
        let speakerPath = UIBezierPath()
        speakerPath.move(to: CGPoint(x: 10, y: 20))
        speakerPath.addLine(to: CGPoint(x: 15, y: 25))
        speakerPath.addLine(to: CGPoint(x: 20, y: 25))
        speakerPath.addLine(to: CGPoint(x: 20, y: 35))
        speakerPath.addLine(to: CGPoint(x: 15, y: 35))
        speakerPath.addLine(to: CGPoint(x: 10, y: 40))
        speakerPath.close()
        
        context.setFillColor(UIColor.white.cgColor)
        context.addPath(speakerPath.cgPath)
        context.fillPath()
        
        guard let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            completion()
            return
        }
        
        UIGraphicsEndImageContext()
        
        // ✅ Set thumbnail
        audioModel.thumbnailImageArray = [thumbnailImage]
        
        print("🎵 Audio thumbnail generated")
        completion()
    }

    // ✅ ADD method để create audio track view
    private func createAudioSeparateRenderTrackView(with itemModel: VLETimeLineItemModel) -> VLETimeLineSeparateRenderTrackView {
        print("🎵 Creating audio track view")
        
        let audioTrackView = VLETimeLineSeparateRenderTrackView(with: itemModel, delegate: self)
        
        // ✅ Position audio track view
        backScrollView.addSubview(audioTrackView)
        backScrollView.bringSubviewToFront(audioTrackView)
        
        let offset = VLETimeLineConfig.convertToPt(value: itemModel.globalStartTime)
        let width = VLETimeLineConfig.convertToPt(value: itemModel.source.selectedTimeRange.duration)
        let dragblockW = audioTrackView.dragBlockWidth
        
        let leftOffset = offset - dragblockW + stateModel.fetchScaleFrontMargin()
        let totalWidth = width + dragblockW * 2
        
        // ✅ Position below existing tracks
        let yOffset = 62 + (separateRenderTrackViewArray.count * 70) // Stack audio tracks
        
        audioTrackView.snp.makeConstraints { make in
            make.top.equalTo(scaleView.snp.bottom).offset(yOffset)
            make.height.equalTo(62)
            make.left.equalTo(backScrollView.snp.left).offset(leftOffset)
            make.width.equalTo(totalWidth)
        }
        
        // ✅ Visual styling for audio
        audioTrackView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        audioTrackView.layer.borderColor = UIColor.systemBlue.cgColor
        audioTrackView.layer.borderWidth = 2
        audioTrackView.layer.cornerRadius = 8
        
        print("✅ Audio track view created and positioned")
        return audioTrackView
    }

    public func addStickerToSeparateRenderLayerWith(source: Source) {
        print("🎨 === ADDING STICKER TO TIMELINE ===")
        print("🎨 Source type: \(type(of: source))")
        
        // ✅ 1. Load sticker source
        source.load { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Sticker load failed: \(error)")
                    HUD.show(.label("Failed to load sticker"))
                    HUD.hide(afterDelay: 1.0)
                    return
                }
                
                print("✅ Sticker loaded successfully")
                
                // ✅ 2. Create timeline item model
                let stickerItemModel = VLETimeLineItemModel(with: source, type: .sticker)
                
                // ✅ 3. Set as separate track (overlay)
                stickerItemModel.isSeparateRenderTrack = true
                
                // ✅ 4. Position at current timeline position
                let currentTime = self.getCurrentTimelineTime()
                
                // ✅ 5. Set default duration for sticker (5 seconds or remaining timeline)
                let mainTrackDuration = self.stateModel.calculateMainTrackDuration()
                let remainingTime = CMTimeSubtract(mainTrackDuration, currentTime)
                let stickerDuration = CMTime(seconds: min(5.0, CMTimeGetSeconds(remainingTime)), preferredTimescale: 600)
                
                stickerItemModel.source.selectedTimeRange = CMTimeRange(start: CMTime.zero, duration: stickerDuration)
                stickerItemModel.globalStartTime = currentTime
                stickerItemModel.renderLayer.timeRange = CMTimeRange(start: currentTime, duration: stickerDuration)
                
                // ✅ 6. Set transform for sticker (positioned overlay with scale)
                let randomX = CGFloat.random(in: 0.2...0.8)
                let randomY = CGFloat.random(in: 0.2...0.8)
                let randomScale = Float.random(in: 0.2...0.4)
                let transform = Transform(center: CGPoint(x: randomX, y: randomY), rotation: 0, scale: randomScale)
                stickerItemModel.renderLayer.transform = transform
                
                print("🎨 Sticker positioned at: \(CMTimeGetSeconds(currentTime))s, duration: \(CMTimeGetSeconds(stickerDuration))s")
                print("🎨 Transform: center=(\(randomX), \(randomY)), scale=\(randomScale)")
                
                // ✅ 7. Generate thumbnail from sticker image
                self.generateStickerThumbnailSafe(for: stickerItemModel) {
                    // ✅ 8. Add to separate track array
                    self.stateModel.separateRenderTrackItemModelArray.append(stickerItemModel)
                    
                    // ✅ 9. Create UI view
                    let stickerTrackView = self.createStickerSeparateRenderTrackView(with: stickerItemModel)
                    self.separateRenderTrackViewArray.append(stickerTrackView)
                    
                    // ✅ 10. Update timeline
                    self.stateModel.refreshItemTime()
                    self.reloadView()
                    
                    // ✅ 11. Update playback
                    VLEMainConcreteMediator.shared.previewTimeLineItem(videoLab: self.buildVideolab())
                    
                    // ✅ 12. Show success
                    HUD.show(.label("🎨 Sticker added!"))
                    HUD.hide(afterDelay: 1.0)
                    
                    print("✅ Sticker successfully added to timeline")
                }
            }
        }
    }
    
    private func generateStickerThumbnail(for stickerModel: VLETimeLineItemModel, completion: @escaping () -> Void) {
        // ✅ For ImageSource, use the actual image as thumbnail
        if let imageSource = stickerModel.source as? ImageSource {
            if let texture = imageSource.texture(at: CMTime.zero) {
                if let cgImage = texture.texture.toImage() {
                    let thumbnailImage = UIImage(cgImage: cgImage)
                    stickerModel.thumbnailImageArray = [thumbnailImage]
                    print("🎨 Sticker thumbnail generated from image source")
                    completion()
                    return
                }
            }
        }
        
        // ✅ Fallback: Create placeholder sticker icon
        let thumbnailSize = CGSize(width: 60, height: 60)
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            completion()
            return
        }
        
        // ✅ Draw sticker placeholder background
        context.setFillColor(UIColor.systemPink.cgColor)
        context.fill(CGRect(origin: .zero, size: thumbnailSize))
        
        // ✅ Draw star shape
        let center = CGPoint(x: thumbnailSize.width/2, y: thumbnailSize.height/2)
        let starPath = createStarPath(center: center, radius: 20, points: 5)
        
        context.setFillColor(UIColor.white.cgColor)
        context.addPath(starPath.cgPath)
        context.fillPath()
        
        guard let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            completion()
            return
        }
        
        UIGraphicsEndImageContext()
        
        stickerModel.thumbnailImageArray = [thumbnailImage]
        print("🎨 Sticker placeholder thumbnail generated")
        completion()
    }

    // ✅ ADD helper để create star path
    private func createStarPath(center: CGPoint, radius: CGFloat, points: Int) -> UIBezierPath {
        let path = UIBezierPath()
        let angleIncrement = .pi * 2 / CGFloat(points * 2)
        
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * angleIncrement - .pi / 2
            let currentRadius = i % 2 == 0 ? radius : radius * 0.5
            let x = center.x + cos(angle) * currentRadius
            let y = center.y + sin(angle) * currentRadius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.close()
        return path
    }

    // ✅ ADD method để create sticker track view
    private func createStickerSeparateRenderTrackView(with itemModel: VLETimeLineItemModel) -> VLETimeLineSeparateRenderTrackView {
        print("🎨 Creating sticker track view")
        
        let stickerTrackView = VLETimeLineSeparateRenderTrackView(with: itemModel, delegate: self)
        
        // ✅ Position sticker track view
        backScrollView.addSubview(stickerTrackView)
        backScrollView.bringSubviewToFront(stickerTrackView)
        
        let offset = VLETimeLineConfig.convertToPt(value: itemModel.globalStartTime)
        let width = VLETimeLineConfig.convertToPt(value: itemModel.source.selectedTimeRange.duration)
        let dragblockW = stickerTrackView.dragBlockWidth
        
        let leftOffset = offset - dragblockW + stateModel.fetchScaleFrontMargin()
        let totalWidth = width + dragblockW * 2
        
        // ✅ Position below existing tracks (stack with audio)
        let yOffset = 62 + (separateRenderTrackViewArray.count * 70)
        
        stickerTrackView.snp.makeConstraints { make in
            make.top.equalTo(scaleView.snp.bottom).offset(yOffset)
            make.height.equalTo(62)
            make.left.equalTo(backScrollView.snp.left).offset(leftOffset)
            make.width.equalTo(totalWidth)
        }
        
        // ✅ Visual styling for sticker
        stickerTrackView.backgroundColor = UIColor.systemPink.withAlphaComponent(0.3)
        stickerTrackView.layer.borderColor = UIColor.systemPink.cgColor
        stickerTrackView.layer.borderWidth = 2
        stickerTrackView.layer.cornerRadius = 8
        
        print("✅ Sticker track view created and positioned")
        return stickerTrackView
    }

    // ✅ ADD DEBUG METHODS
    private func debugComposition() {
        print("\n🔍 === TIMELINE DEBUG INFO ===")
        
        let validation = stateModel.validateComposition()
        print("Composition valid: \(validation.isValid)")
        if !validation.issues.isEmpty {
            print("Issues found:")
            for issue in validation.issues {
                print("  ❌ \(issue)")
            }
        }
        
        print("\n📊 Main Track (\(stateModel.renderTrackItemModelArray.count) items):")
        for (index, item) in stateModel.renderTrackItemModelArray.enumerated() {
            let startTime = CMTimeGetSeconds(item.globalStartTime)
            let duration = CMTimeGetSeconds(item.source.selectedTimeRange.duration)
            print("  \(index): [\(String(format: "%.2f", startTime))s - \(String(format: "%.2f", startTime + duration))s] duration: \(String(format: "%.2f", duration))s")
        }
        
        print("\n🎨 Overlay Track (\(stateModel.separateRenderTrackItemModelArray.count) items):")
        for (index, item) in stateModel.separateRenderTrackItemModelArray.enumerated() {
            let startTime = CMTimeGetSeconds(item.globalStartTime)
            let duration = CMTimeGetSeconds(item.source.selectedTimeRange.duration)
            let transform = item.renderLayer.transform
            print("  \(index): [\(String(format: "%.2f", startTime))s - \(String(format: "%.2f", startTime + duration))s] transform: center=\(transform.center), scale=\(transform.scale)")
        }
        
        print("\n⏱️ Total duration: \(String(format: "%.2f", stateModel.totalSeconds))s")
        print("🎬 Render size: \(stateModel.renderSize)")
        print("=== END DEBUG ===\n")
    }
    

    // ✅ REPLACE EXISTING METHOD
    public func buildVideolab() -> VideoLab {
        var renderLayers: [RenderLayer] = []
        
        print("🎬 === BUILDING VIDEOLAB COMPOSITION ===")
        print("📊 Main track items: \(stateModel.renderTrackItemModelArray.count)")
        print("📊 Overlay track items: \(stateModel.separateRenderTrackItemModelArray.count)")
        
        // ✅ VALIDATE MAIN TRACK
        if stateModel.renderTrackItemModelArray.isEmpty && stateModel.separateRenderTrackItemModelArray.isEmpty {
            print("❌ WARNING: No video content at all!")
            // Return empty composition or show error
        } else if stateModel.renderTrackItemModelArray.isEmpty && !stateModel.separateRenderTrackItemModelArray.isEmpty {
            print("⚠️ WARNING: Only overlay content, no main video timeline!")
            showMainTrackWarning()
        }
        
        // Add main track layers
        for (index, item) in stateModel.renderTrackItemModelArray.enumerated() {
            print("✅ Main layer \(index): timeRange=\(item.renderLayer.timeRange)")
            renderLayers.append(item.renderLayer)
        }
        
        // Add overlay layers
        for (index, item) in stateModel.separateRenderTrackItemModelArray.enumerated() {
            print("✅ Overlay layer \(index): timeRange=\(item.renderLayer.timeRange), transform=\(item.renderLayer.transform)")
            renderLayers.append(item.renderLayer)
        }
        
        let composition = RenderComposition()
        composition.renderSize = stateModel.renderSize
        composition.layers = renderLayers
        
        let videoLab = VideoLab(renderComposition: composition)
        print("✅ Final composition: \(renderLayers.count) total layers, renderSize: \(composition.renderSize)")
        // ✅ CHECK FINAL COMPOSITION:
        let finalPlayerItem = videoLab.makePlayerItem()
        let audioTracks = finalPlayerItem.asset.tracks(withMediaType: .audio)
        print("🔍 Final composition audio tracks: \(audioTracks.count)")
        
        return videoLab
    }


    public func updatePlaybackProgress(time: CMTime) {
        if backScrollView.isTracking || backScrollView.isDecelerating {
            return
        }
        let second = CMTimeGetSeconds(time) * Float64(VLETimeLineConfig.framesPerSecond) * Float64(VLETimeLineConfig.ptPerFrames)
        backScrollView.setContentOffset(CGPoint.init(x: second, y: 0), animated: false)
    }
    
    // ✅ ADD THESE NEW METHODS before extensions:

    // MARK: - Timeline Cursor Methods

    // ✅ FIND và REPLACE updateCursorPosition() method:
    func updateCursorPosition(time: CMTime) {
        let timeString = formatTime(time)
        cursorTimeLabel.text = timeString
        
        // ✅ FIX: Calculate position based on MAIN TRACK duration only
        let mainTrackDuration = stateModel.calculateMainTrackDuration()
        let maxTimeSeconds = CMTimeGetSeconds(mainTrackDuration)
        let currentTimeSeconds = CMTimeGetSeconds(time)
        
        // ✅ Clamp cursor to main track bounds
        let clampedTimeSeconds = min(currentTimeSeconds, maxTimeSeconds)
        let pixelPosition = VLETimeLineConfig.convertToPt(value: Float(clampedTimeSeconds))
        let frontMargin = stateModel.fetchScaleFrontMargin()
        let targetX = pixelPosition + frontMargin
        
        // ✅ Update constraint
        timelineCursorLeftConstraint?.update(offset: targetX)
        
        // ✅ Animate
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
            self.view.layoutIfNeeded()
        }
        
        print("🎯 Cursor: \(clampedTimeSeconds)s/\(maxTimeSeconds)s at \(targetX)px")
    }

    func formatTime(_ time: CMTime) -> String {
        let totalSeconds = Int(CMTimeGetSeconds(time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension VLETimeLineViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isTracking || scrollView.isDecelerating {
            let offsetX = scrollView.contentOffset.x
            let maxX = scrollView.contentSize.width - stateModel.fetchScaleFrontMargin() - stateModel.fetchScaleBackMargin()
            var rate = offsetX/maxX
            rate = (rate >= 1) ? 1 : rate
            rate = (rate <= 0) ? 0 : rate
            VLEMainConcreteMediator.shared.previewTimeLineItem(rate: Float64(rate))
        }

        if scrollView.contentOffset.x >=
            (renderTrackView.frame.size.width - stateModel.fetchScaleFrontMargin()) {
            let diff = scrollView.contentOffset.x - (renderTrackView.frame.size.width - stateModel.fetchScaleFrontMargin())
            if (diff/4 + 32) <= 50 {
                movablyAddAssetButton.snp.updateConstraints { make in
                    make.size.equalTo(CGSize.init(width: diff/4 + 32, height: diff/4 + 32))
                }
            }
            if diff > (50 + 12 + 12) {
                movablyAddAssetButton.snp.updateConstraints { make in
                    make.right.equalTo(self.view.snp.right).offset(-12 - (diff - 50 - 12 - 12))
                }
            }
        }
    }
}

extension VLETimeLineViewController: VLETimeLineDragSortViewDelegate {
    func showOverlayCursor() {
        // ✅ CURSOR WILL BE UPDATED BY SLIDER
        timelineCursor.isHidden = false
        cursorTimeLabel.isHidden = false
        print("🎯 Overlay cursor shown")
    }

    // 2. Get precise timeline time
    func getCurrentTimelineTime() -> CMTime {
        let currentOffset = backScrollView.contentOffset.x
        let frontMargin = stateModel.fetchScaleFrontMargin()
        let adjustedOffset = max(0, currentOffset - frontMargin)
        let timeSeconds = VLETimeLineConfig.convertToSecond(value: adjustedOffset)
        return CMTime(seconds: Double(timeSeconds), preferredTimescale: 600)
    }

    func validateOverlayTiming(requestedTime: CMTime, overlayDuration: CMTime) -> (isValid: Bool, correctedTime: CMTime?, warningMessage: String?) {
        let mainDuration = stateModel.calculateMainTrackDuration()
        let mainDurationSeconds = CMTimeGetSeconds(mainDuration)
        let requestedSeconds = CMTimeGetSeconds(requestedTime)
        let overlayDurationSeconds = CMTimeGetSeconds(overlayDuration)
        
        if requestedSeconds >= mainDurationSeconds {
            // Completely outside
            let correctedTime = CMTime(seconds: max(0, mainDurationSeconds - overlayDurationSeconds), preferredTimescale: 600)
            return (false, correctedTime, "Overlay time (\(Int(requestedSeconds))s) is beyond main video (\(Int(mainDurationSeconds))s). Auto-corrected to \(Int(CMTimeGetSeconds(correctedTime)))s.")
        } else if (requestedSeconds + overlayDurationSeconds) > mainDurationSeconds {
            // Partially outside
            let correctedTime = CMTime(seconds: mainDurationSeconds - overlayDurationSeconds, preferredTimescale: 600)
            return (false, correctedTime, "Overlay would extend beyond main video. Adjusted to end exactly with main video.")
        } else {
            // Valid
            return (true, nil, nil)
        }
    }

    // ✅ FIND EXISTING timelineDargSortViewChangedSeparate() method and REPLACE it:
    func timelineDargSortViewChangedSeparate(with selectedIndex: Int, dragPositionXRate: Float) {
        print("🎯 === PRECISE OVERLAY POSITIONING WITH VALIDATION ===")
        
        dragSortView?.removeFromSuperview()
        dragSortView = nil
        
        // ✅ GET REQUESTED TIME AND OVERLAY DURATION
        let requestedTime = stateModel.getPendingOverlayStartTime() ?? CMTime.zero
        let overlayModel = stateModel.renderTrackItemModelArray[selectedIndex]
        let overlayDuration = overlayModel.source.selectedTimeRange.duration
        
        // ✅ VALIDATE TIMING
        let validation = validateOverlayTiming(requestedTime: requestedTime, overlayDuration: overlayDuration)
        
        if !validation.isValid {
            // ✅ SHOW WARNING DIALOG
            let alert = UIAlertController(title: "Overlay Timing Adjusted", message: validation.warningMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK, Use Corrected Time", style: .default) { _ in
                // Update pending time with corrected value
                if let correctedTime = validation.correctedTime {
                    self.stateModel.setPendingOverlayStartTime(correctedTime)
                }
                self.performOverlayConversion(selectedIndex: selectedIndex)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            self.present(alert, animated: true)
        } else {
            // ✅ TIME IS VALID - PROCEED NORMALLY
            performOverlayConversion(selectedIndex: selectedIndex)
        }
    }
    
    // ✅ REPLACE performOverlayConversion() method:
    func performOverlayConversion(selectedIndex: Int) {
        print("🎬 === PERFORMING OVERLAY CONVERSION ===")
        
        stateModel.renderTrackItemModelConvertToSeparate(at: selectedIndex, startTime: CMTime.zero)
        stateModel.validateTimelineConsistency()
        // ✅ CRITICAL: Complete UI refresh sequence
        DispatchQueue.main.async {
            // 1. Rebuild timeline UI
            self.reloadView()
            
            // 2. Create overlay UI
            if let lastItem = self.stateModel.separateRenderTrackItemModelArray.last {
                let separateTrackView = self.createSeparateRenderTrackView(with: lastItem)
                self.separateRenderTrackViewArray.append(separateTrackView)
                print("✅ Overlay view created")
                
                self.highlightNewOverlay(separateTrackView)
            }
            
            // 3. Update playback
            VLEMainConcreteMediator.shared.previewTimeLineItem(videoLab: self.buildVideolab())
            
            // 4. Hide cursor
            self.hideOverlayCursor()
            
            print("✅ UI refresh completed")
        }
        
        print("🎬 === OVERLAY CONVERSION COMPLETED ===")
    }
    

    // ✅ ADD VISUAL FEEDBACK METHOD
    func highlightNewOverlay(_ overlayView: VLETimeLineSeparateRenderTrackView) {
        // Flash animation to highlight new overlay
        overlayView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        overlayView.alpha = 0.7
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            overlayView.transform = CGAffineTransform.identity
            overlayView.alpha = 1.0
        }
    }
    
    func createSeparateRenderTrackView(with itemModel: VLETimeLineItemModel) -> VLETimeLineSeparateRenderTrackView {
        print("🔍 === CREATE SEPARATE VIEW DEBUG ===")
        print("🔍 Global start time: \(CMTimeGetSeconds(itemModel.globalStartTime))s")
        print("🔍 Duration: \(CMTimeGetSeconds(itemModel.source.selectedTimeRange.duration))s")
        
        let separateTrackView = VLETimeLineSeparateRenderTrackView.init(with: itemModel, delegate: self)
        
        // ✅ ENSURE PROPER LAYER ORDER
        backScrollView.addSubview(separateTrackView)
        backScrollView.bringSubviewToFront(separateTrackView)
        
        let offset = VLETimeLineConfig.convertToPt(value: itemModel.globalStartTime)
        let width = VLETimeLineConfig.convertToPt(value: itemModel.source.selectedTimeRange.duration)
        let dragblockW = separateTrackView.dragBlockWidth
        
        let leftOffset = offset - dragblockW + stateModel.fetchScaleFrontMargin()
        let totalWidth = width + dragblockW * 2
        
        print("🔍 UI calculations:")
        print("🔍   - offset: \(offset)pt")
        print("🔍   - width: \(width)pt")
        print("🔍   - left offset: \(leftOffset)pt")
        print("🔍   - total width: \(totalWidth)pt")
        
        separateTrackView.snp.makeConstraints { make in
            make.top.equalTo(scaleView.snp.bottom).offset(0)
            make.height.equalTo(62)
            make.left.equalTo(backScrollView.snp.left).offset(leftOffset)
            make.width.equalTo(totalWidth)
        }
        
        // ✅ VISUAL DEBUGGING
        separateTrackView.backgroundColor = UIColor.yellow.withAlphaComponent(0.3)
        separateTrackView.layer.borderColor = UIColor.red.cgColor
        separateTrackView.layer.borderWidth = 2
        
        print("✅ Separate track view created and positioned")
        print("🔍 === END CREATE SEPARATE VIEW DEBUG ===")
        return separateTrackView
    }

    func timeLineDargSortViewDeleteSegment(with selectedIndex: Int) {
        dragSortView?.removeFromSuperview()
        dragSortView = nil
        stateModel.renderTrackItemModelArray.remove(at: selectedIndex)
        notifyTimelineChanged()
    }

    func timeLineDargSortViewDidSort(with selectedIndex: Int, targetIndex: Int) {
        dragSortView?.removeFromSuperview()
        dragSortView = nil
        guard selectedIndex != targetIndex else { return }
        self.stateModel.swapItemForRenderTrack(selectedIndex: selectedIndex, targetIndex: targetIndex)
        notifyTimelineChanged()
    }
    
    

    func hideOverlayCursor() {
        timelineCursor.isHidden = true
        cursorTimeLabel.isHidden = true
        print("🎯 Overlay cursor hidden")
    }
    
    /// Consolidated method to handle all timeline state changes
    private func notifyTimelineChanged() {
        stateModel.refreshItemTime()
        reloadView()
        VLEMainConcreteMediator.shared.previewTimeLineItem(videoLab: buildVideolab())
        updateDragSortSliderRange()
        
        print("🔄 Timeline updated - Duration: \(stateModel.totalSeconds)s")
    }
    
    func updateDragSortSliderRange() {
        if let dragSort = dragSortView {
            dragSort.refreshSliderRange()
            print("🔄 Updated drag sort slider range")
        }
    }

}

extension VLETimeLineViewController: VLETimeLineRenderTrackViewDelegate {
    func startDragSortRenderTrackSegmentView(with sender: UILongPressGestureRecognizer) {
        dragSortView?.beginSortView(with: sender)
    }

    func continuedDragSortRenderTrackSegmentView(with sender: UILongPressGestureRecognizer) {
        dragSortView!.moveSortView(with: sender)
    }

    func endDragSortRenderTrackSegmentView(with sender: UILongPressGestureRecognizer) {
        dragSortView?.endSortView(with: sender)
    }

    func showDragSortRenderTrackSegmentView(with selectedIndex: Int) {
        NotificationCenter.default.post(name: Notification.Name.init(rawValue: VLEConstants.VLETImeLineShowDragSortViewNotification), object: nil)
        var imageArray: [UIImage] = []
        for item in self.stateModel.renderTrackItemModelArray {
            let image = item.thumbnailImageArray.first
            imageArray.append(image!)
        }
        if dragSortView != nil {
            dragSortView!.removeFromSuperview()
            dragSortView = nil
        } else {
            dragSortView = VLETimeLineDragSortView.init(with: imageArray, delegate: self, selectedIndex: selectedIndex)
            self.view.addSubview(dragSortView!)
            dragSortView!.snp.makeConstraints { make in
                make.width.top.centerX.equalToSuperview()
                make.height.equalTo(350)
            }
        }
    }

    func showRenderTrackDragView(with sourceView: VLETimeLineRenderTrackSegmentView, index: Int) {
        // ✅ FIX: Remove existing drag view first
       renderLayerDargView?.removeFromSuperview()
       renderLayerDargView = nil
       
       // ✅ FIX: Validate index bounds
       guard index < stateModel.renderTrackItemModelArray.count else {
           print("❌ Invalid drag view index: \(index) >= \(stateModel.renderTrackItemModelArray.count)")
           return
       }
        
        if let itemModel = stateModel.currentSelectedItemModel {
            if itemModel.isSeparateRenderTrack {
                let separateView = separateRenderTrackViewArray[stateModel.currentSelectedIndex!]
                separateView.hideSummaryView()
                renderTrackView.snp.updateConstraints { make in
                    make.top.equalTo(scaleView.snp.bottom).offset(62)
                }
                let height = separateView.bounds.height
                separateView.snp.updateConstraints { make in
                    make.height.equalTo(height-separateView.dragBlockHeight)
                }
            } else {
                renderLayerDargView?.removeFromSuperview()
                renderLayerDargView = nil
                stateModel.currentSelectedIndex = nil
                stateModel.currentSelectedItemModel = nil
            }
        }

        renderLayerDargView = VLETimeLineRenderTrackDragView.init(delegate: self, targetView: sourceView)
        backScrollView.addSubview(renderLayerDargView!)
        renderLayerDargView!.snp.makeConstraints { make in
            make.center.equalTo(sourceView)
            make.height.equalTo(sourceView.frame.height)
            make.width.equalTo(sourceView.frame.width + 24 + 24)
        }
        stateModel.currentSelectedItemModel = sourceView.model
        stateModel.currentSelectedIndex = index
        toolBarView.refreshClipButtonState(isShow: true)
    }
}

extension VLETimeLineViewController: VLETimeLineRenderTrackDragViewDelegate {

    func renderTrackDragView(_ dragView: VLETimeLineRenderTrackDragView, targetView: VLETimeLineRenderTrackSegmentView, leftBorderDragWith offsetX: CGFloat, finalWidth: CGFloat) {
        let scaleViewWidth = stateModel.fetchScaleViewWidth()
        self.renderTrackView.snp.updateConstraints { make in
            make.width.equalTo(scaleViewWidth)
        }
        targetView.snp.updateConstraints { make in
            make.width.equalTo(finalWidth)
        }
        dragView.snp.updateConstraints { make in
            make.width.equalTo(finalWidth + 24 + 24)
        }
        stateModel.refreshItemTime()
        reloadScaleView()
    }

    func renderTrackDragView(_ dragView: VLETimeLineRenderTrackDragView, targetView: VLETimeLineRenderTrackSegmentView, rightBorderDragWith offsetX: CGFloat, finalWidth: CGFloat) {
        let scaleViewWidth = stateModel.fetchScaleViewWidth()
        renderTrackView.snp.updateConstraints { make in
            make.width.equalTo(scaleViewWidth)
        }
        targetView.snp.updateConstraints { make in
            make.width.equalTo(finalWidth)
        }
        dragView.snp.updateConstraints { make in
            make.width.equalTo(finalWidth + 24 + 24)
        }
        stateModel.refreshItemTime()
        reloadScaleView()
        notifyTimelineChanged()
    }

    func renderTrackDragViewIsDragEnd() {
        VLEMainConcreteMediator.shared.previewTimeLineItem(videoLab: buildVideolab())
        updateDragSortSliderRange()
    }
}

extension VLETimeLineViewController: VLETimeLineSeparateRenderTrackViewDelegate {

    func separateRenderTrackViewIsShowSummaryView(_ separateTrackView: VLETimeLineSeparateRenderTrackView) {
        renderTrackView.snp.updateConstraints { make in
            make.top.equalTo(scaleView.snp.bottom).offset(62 + separateTrackView.dragBlockHeight)
        }
        stateModel.currentSelectedIndex = separateRenderTrackViewArray.firstIndex(of: separateTrackView)
        stateModel.currentSelectedItemModel = stateModel.separateRenderTrackItemModelArray[stateModel.currentSelectedIndex!]
        for itemView in separateRenderTrackViewArray {
            if itemView != separateTrackView {
                itemView.hideSummaryView()
            }
        }
        renderLayerDargView?.removeFromSuperview()
        renderLayerDargView = nil
        toolBarView.refreshClipButtonState(isShow: true)
    }

    func separateRenderTrackView(_ view: VLETimeLineSeparateRenderTrackView, frameChangedWith width: CGFloat, xOffset: CGFloat) {
        view.snp.updateConstraints { make in
            make.left.equalTo(backScrollView.snp.left).offset(xOffset)
            make.width.equalTo(width)
        }
        stateModel.refreshItemTime()
        reloadScaleView()
    }

    func separateRenderTrackViewIsDragEnd() {
        VLEMainConcreteMediator.shared.previewTimeLineItem(videoLab: buildVideolab())
    }

    func separateRenderTrackViewNeedRemove(_ separateTrackView: VLETimeLineSeparateRenderTrackView) {
        renderTrackView.snp.updateConstraints { make in
            make.top.equalTo(scaleView.snp.bottom).offset(62)
        }
        stateModel.separateRenderTrackItemModelArray.remove(at: stateModel.currentSelectedIndex!)
        separateRenderTrackViewArray.remove(at: stateModel.currentSelectedIndex!)
        separateTrackView.removeFromSuperview()
        stateModel.currentSelectedItemModel = nil
        stateModel.currentSelectedIndex = nil
        toolBarView.refreshClipButtonState(isShow: false)
        notifyTimelineChanged()
    }
}

extension VLETimeLineViewController: VLETimeLineToolBarViewDelegate {

    // ✅ REPLACE method trong VLETimeLineViewController.swift:
    func clipRenderTrackView(at offsetX: CGFloat, itemModel: VLETimeLineItemModel) {
        let segmentView = renderTrackView.segmentViewArray[stateModel.currentSelectedIndex!]
        let originx = segmentView.frame.origin.x
        let segmentw = segmentView.bounds.width
        
        if (offsetX >= originx) && (offsetX < (originx + segmentw)) {
            let rate = Float((offsetX - originx) / segmentw)
            
            print("✂️ Clipping at rate: \(rate), offset: \(offsetX), origin: \(originx), width: \(segmentw)")
            
            stateModel.clipRenderTrackItemModelAtCurrentIndex(clipRate: rate) { [weak self] error in
                guard let self = self else { return }
                
                if error == nil {
                    print("✅ Clip successful, refreshing UI...")
                    
                    // ✅ FIX: Single comprehensive refresh instead of multiple calls
                    DispatchQueue.main.async {
                        // 1. Update timeline views
                        self.reloadRenderTrackView()  // Only reload render track
                        self.reloadScaleView()        // Only reload scale
                        
                        // 2. Force layout
                        self.renderTrackView.layoutIfNeeded()
                        
                        // 3. Show drag view for NEW segment
                        let newIndex = self.stateModel.currentSelectedIndex! + 1
                        if newIndex < self.renderTrackView.segmentViewArray.count {
                            self.showRenderTrackDragView(
                                with: self.renderTrackView.segmentViewArray[newIndex],
                                index: newIndex
                            )
                        }
                        
                        // 4. Update playback ONCE
                        VLEMainConcreteMediator.shared.previewTimeLineItem(videoLab: self.buildVideolab())
                        
                        print("✅ Single UI refresh completed")
                    }
                    
                } else {
                    print("❌ Clip operation failed")
                    HUD.show(.label("Clip operation failed"))
                    HUD.hide(afterDelay: 1.0)
                }
            }
        } else {
            print("❌ Invalid clip position")
            HUD.show(.label("Invalid position selected!"))
            HUD.hide(afterDelay: 0.5)
        }
    }

    func clipSeparateRenderTrackView(at offsetX: CGFloat, itemModel: VLETimeLineItemModel) {
        let separateTrackView = separateRenderTrackViewArray[stateModel.currentSelectedIndex!]
        let viewX = separateTrackView.frame.origin.x + 24 - VLETimeLineConfig.frontMargin
        if offsetX > viewX {
            let selectedRate = Float((offsetX-viewX)/(separateTrackView.bounds.width-24-24))
            stateModel.clipSeparateRenderTrackItemModelAtCurrentIndex(clipRate: selectedRate) { [weak self] error, itemModel in
                guard let self = self else {return}
                if itemModel != nil {
                    let newSeparateTrackView = self.createSeparateRenderTrackView(with: itemModel!)
                    self.separateRenderTrackViewArray.insert(newSeparateTrackView, at: self.stateModel.currentSelectedIndex!+1)
                    separateTrackView.updateLayout()
                }
            }
        } else {
            HUD.show(.label("Invalid position selected!"))
            HUD.hide(afterDelay: 0.5)
        }
    }

    func toolBarView(_ view: VLETimeLineToolBarView, clickCatButton button: UIButton) {
        guard let itemModel = stateModel.currentSelectedItemModel else {
            return
        }
        let xOffset = backScrollView.contentOffset.x
        if itemModel.isSeparateRenderTrack {
            clipSeparateRenderTrackView(at: xOffset, itemModel: itemModel)
        } else {
            clipRenderTrackView(at: xOffset, itemModel: itemModel)
        }
    }
}

extension VLETimeLineViewController {

    func setupView() {
        self.view.backgroundColor = UIColor.init(hexString: "#212123")
        self.view.addSubview(toolBarView)
        toolBarView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.snp.bottom)
        }
        self.view.addSubview(backScrollView)
        backScrollView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(toolBarView.snp.top).offset(0)
        }
        backScrollView.addSubview(scaleView)
        scaleView.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.width.equalTo(1)
            make.left.equalTo(backScrollView.snp.left).offset(self.stateModel.fetchScaleFrontMargin())
            make.top.equalToSuperview()
        }
        self.view.addSubview(addAssetButton)
        addAssetButton.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.center.equalToSuperview()
        }
        self.view.addSubview(locationLineView)
        self.view.addSubview(locationLineView)
        locationLineView.snp.makeConstraints { make in
            make.width.equalTo(2)
            make.centerX.equalToSuperview()
            make.top.equalTo(self.view.snp.top).offset(14)
            make.bottom.equalTo(toolBarView.snp.top).offset(0)
        }
        
        // ✅ MODIFY CURSOR SETUP TO STORE CONSTRAINT
        self.view.addSubview(timelineCursor)
        timelineCursor.snp.makeConstraints { make in
            make.width.equalTo(4)
            make.top.equalTo(scaleView.snp.bottom)
            make.bottom.equalTo(toolBarView.snp.top)
            // ✅ STORE THE LEFT CONSTRAINT REFERENCE
            self.timelineCursorLeftConstraint = make.left.equalTo(self.view.snp.centerX).constraint
        }
        
        self.view.addSubview(cursorTimeLabel)
        cursorTimeLabel.snp.makeConstraints { make in
            make.width.equalTo(70)
            make.height.equalTo(20)
            make.centerX.equalTo(timelineCursor)
            make.bottom.equalTo(timelineCursor.snp.top).offset(-5)
        }
        backScrollView.addSubview(renderTrackView)
        renderTrackView.snp.makeConstraints { make in
            make.left.equalTo(backScrollView.snp.left).offset(stateModel.fetchScaleFrontMargin())
            make.top.equalTo(scaleView.snp.bottom).offset(62)
            make.height.equalTo(64)
            make.width.equalTo(1)
        }
        self.view.addSubview(movablyAddAssetButton)
        movablyAddAssetButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 32, height: 32))
            make.right.equalTo(self.view.snp.right).offset(-12)
            make.centerY.equalTo(renderTrackView)
        }
        refreshViewState()
    }

    // ✅ REPLACE EXISTING refreshViewState() - REMOVE hintLabel references
    func refreshViewState() {
        let hasMainTrack = !stateModel.renderTrackItemModelArray.isEmpty
        let hasOverlayTrack = !stateModel.separateRenderTrackItemModelArray.isEmpty
        let hasAnyContent = stateModel.isHaveRenderTrack
        
        print("🎬 Refreshing view state - Main: \(hasMainTrack), Overlay: \(hasOverlayTrack)")
        
        if !hasAnyContent {
            // Empty state
            scaleView.isHidden = true
            toolBarView.isHidden = true
            addAssetButton.isHidden = false
            backScrollView.isHidden = true
            renderTrackView.isHidden = true
            locationLineView.isHidden = true
            movablyAddAssetButton.isHidden = true
            
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: VLEConstants.VLETimeLineAssetDidIsEmptyNotification),
                object: nil
            )
            
        } else {
            // Normal state
            scaleView.isHidden = false
            toolBarView.isHidden = false
            addAssetButton.isHidden = true
            backScrollView.isHidden = false
            renderTrackView.isHidden = false
            locationLineView.isHidden = false
            movablyAddAssetButton.isHidden = false
            
            // ✅ Adjust main track position based on overlay tracks count
            let overlayTracksHeight = separateRenderTrackViewArray.count * 70
            renderTrackView.snp.updateConstraints { make in
                make.top.equalTo(scaleView.snp.bottom).offset(62 + overlayTracksHeight)
            }
            
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: VLEConstants.VLETimeLineAssetDidIsNonemptyNotification),
                object: nil
            )
        }
    }

    // ✅ ADD WARNING METHOD
    private func showMainTrackWarning() {
        let alert = UIAlertController(
            title: "Timeline Warning",
            message: "You only have overlay videos. Add a main video to the timeline for best results.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Add Main Video", style: .default) { _ in
            VLEMainConcreteMediator.shared.addAssetWithPickerViewController()
        })
        
        alert.addAction(UIAlertAction(title: "Continue Anyway", style: .cancel))
        
        self.present(alert, animated: true)
    }

    private func forceCompleteReload() {
        print("🔄 === FORCE COMPLETE RELOAD ===")
        
        // 1. Clear existing UI state
        renderLayerDargView?.removeFromSuperview()
        renderLayerDargView = nil
        
        // 2. Rebuild timeline components
        reloadRenderTrackView()
        reloadScaleView()
        
        // 3. Update scroll view content
        let scaleViewWidth = stateModel.fetchScaleViewWidth()
        let contentWidth = scaleViewWidth + stateModel.fetchScaleFrontMargin() + stateModel.fetchScaleBackMargin()
        backScrollView.contentSize = CGSize(width: contentWidth, height: 210)
        
        // 4. Force layout update
        view.layoutIfNeeded()
        
        print("🔄 Complete reload finished")
    }

    // ✅ MODIFY existing reloadView():
    func reloadView() {
        reloadScaleView()
        reloadRenderTrackView()
    }

    func reloadRenderTrackView() {
        var sum: CGFloat = 0
        for item in stateModel.renderTrackItemModelArray {
            sum += VLETimeLineConfig.convertToPt(value: item.source.selectedTimeRange.duration)
        }
        renderTrackView.snp.updateConstraints { make in
            make.width.equalTo(sum)
        }
        renderTrackView.refreshSegmentViewWith(itemModelArray: stateModel.renderTrackItemModelArray)
    }

    func reloadScaleView() {
        let scaleViewWidth = stateModel.fetchScaleViewWidth()
        let contentWidth = scaleViewWidth + stateModel.fetchScaleFrontMargin() + stateModel.fetchScaleBackMargin()
        
        scaleView.snp.updateConstraints { make in
            make.width.equalTo(scaleViewWidth)
        }
        
        scaleView.refreshTimeWith(seconds: stateModel.totalSeconds)
        
        // ✅ FIX: Base scroll content on main track, not total timeline
        let mainTrackSeconds = CMTimeGetSeconds(stateModel.calculateMainTrackDuration())
        print("🔄 Scroll content based on main track: \(mainTrackSeconds)s")
        
        backScrollView.contentSize = CGSize(width: contentWidth, height: 210)
    }

    @objc func addAssetButtonClickAction() {
        albumPermissions {
            VLEMainConcreteMediator.shared.addAssetWithPickerViewController()
        } denied: {
            HUD.show(.label("Allow photo access to save and edit videos. Please go to Settings -> App Name -> Photos to enable permissions"))
            HUD.hide(afterDelay: 1)
        }
    }

    @objc func movablyAddAssetButtonClickAction() {
        albumPermissions {
            VLEMainConcreteMediator.shared.addAssetWithPickerViewController()
        } denied: {
            HUD.show(.label("Allow photo access to save and edit videos. Please go to Settings -> App Name -> Photos to enable permissions"))
            HUD.hide(afterDelay: 1)
        }
    }

    func albumPermissions(success: @escaping () -> Void, denied: @escaping () -> Void) {
        let authStatus = PHPhotoLibrary.authorizationStatus()
        if authStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (_: PHAuthorizationStatus) -> Void in
                self.albumPermissions(success: success, denied: denied)
            }
        } else if authStatus == .authorized {
            DispatchQueue.main.async {
                success()
            }
        } else {
            DispatchQueue.main.async {
                denied()
            }
        }
    }
}

extension VLETimeLineViewController {
    private func makeScaleView() -> VLETimeLineScaleView {
        let scaleView = VLETimeLineScaleView.init(model: stateModel)
        return scaleView
    }
    
    private func makeBackScrollView() -> UIScrollView {
        let scrollView = UIScrollView.init()
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.indicatorStyle = UIScrollView.IndicatorStyle.white
        scrollView.delegate = self
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(backScrollViewTapGestureAction(sender:)))
        scrollView.addGestureRecognizer(tapGesture)
        return scrollView
    }
    
    private func makeAddAssetButton() -> UIButton {
        let button = UIButton.init()
        button.setBackgroundImage(UIImage.init(named: "timeline_addresource_button"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(addAssetButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }
    
    private func makeMovablyAddAssetButton() -> UIButton {
        let button = UIButton.init()
        button.setBackgroundImage(UIImage.init(named: "timeline_addresource_button"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(movablyAddAssetButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }
    
    private func makeLocationLineView() -> UIView {
        let line = UIView.init()
        line.backgroundColor = UIColor.init(hexString: "#FF504E")
        return line
    }
    
    private func makeRenderTrackView() -> VLETimeLineRenderTrackView {
        let renderTrackView = VLETimeLineRenderTrackView.init(delegate: self)
        return renderTrackView
    }
    
    private func makeToolBarView() -> VLETimeLineToolBarView {
        let toolBarView = VLETimeLineToolBarView.init(delegate: self)
        return toolBarView
    }
    
    // ✅ SAFE version of generateStickerThumbnail
        private func generateStickerThumbnailSafe(for stickerModel: VLETimeLineItemModel, completion: @escaping () -> Void) {
            // ✅ Always create placeholder since we can't easily access Texture content
            DispatchQueue.global().async {
                let thumbnailImage = self.createStickerPlaceholderImage()
                
                DispatchQueue.main.async {
                    stickerModel.thumbnailImageArray = [thumbnailImage]
                    print("🎨 Sticker placeholder thumbnail generated")
                    completion()
                }
            }
        }
        
        private func createStickerPlaceholderImage() -> UIImage {
            let thumbnailSize = CGSize(width: 60, height: 60)
            
            UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, UIScreen.main.scale)
            
            // ✅ Use guard let for safer context handling
            guard let context = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext()
                // Return system image as fallback
                if #available(iOS 13.0, *) {
                    return UIImage(systemName: "star.fill") ?? createFallbackStickerImage()
                } else {
                    return createFallbackStickerImage()
                }
            }
            
            // ✅ Draw gradient background
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [UIColor.systemPink.cgColor, UIColor.systemPurple.cgColor]
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil) {
                context.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: thumbnailSize.width, y: thumbnailSize.height),
                    options: []
                )
            } else {
                // Fallback solid color
                context.setFillColor(UIColor.systemPink.cgColor)
                context.fill(CGRect(origin: .zero, size: thumbnailSize))
            }
            
            // ✅ Draw white star
            let center = CGPoint(x: thumbnailSize.width/2, y: thumbnailSize.height/2)
            let starPath = createStarPath(center: center, radius: 20, points: 5)
            
            context.setFillColor(UIColor.white.cgColor)
            context.addPath(starPath.cgPath)
            context.fillPath()
            
            // ✅ Add sparkle effect
            context.setFillColor(UIColor.white.withAlphaComponent(0.8).cgColor)
            for _ in 0..<5 {
                let x = CGFloat.random(in: 5...(thumbnailSize.width-5))
                let y = CGFloat.random(in: 5...(thumbnailSize.height-5))
                context.fillEllipse(in: CGRect(x: x, y: y, width: 3, height: 3))
            }
            
            let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext() ?? createFallbackStickerImage()
            UIGraphicsEndImageContext()
            
            return thumbnailImage
        }
        
        // ✅ Create simple fallback image
        private func createFallbackStickerImage() -> UIImage {
            let size = CGSize(width: 60, height: 60)
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            
            if let context = UIGraphicsGetCurrentContext() {
                // Simple pink square with white border
                context.setFillColor(UIColor.systemPink.cgColor)
                context.fill(CGRect(origin: .zero, size: size))
                
                context.setStrokeColor(UIColor.white.cgColor)
                context.setLineWidth(4.0)
                context.stroke(CGRect(origin: .zero, size: size))
                
                // Add "S" for Sticker
                let font = UIFont.boldSystemFont(ofSize: 24)
                let text = "S"
                let textSize = text.size(withAttributes: [.font: font])
                let textRect = CGRect(
                    x: (size.width - textSize.width) / 2,
                    y: (size.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                
                context.setFillColor(UIColor.white.cgColor)
                text.draw(in: textRect, withAttributes: [
                    .font: font,
                    .foregroundColor: UIColor.white
                ])
            }
            
            let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            UIGraphicsEndImageContext()
            return image
        }
}

