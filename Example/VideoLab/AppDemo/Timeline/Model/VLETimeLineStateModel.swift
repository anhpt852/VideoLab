//
//  VLETimeLineStateModel.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/9/23.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import UIKit
import VideoLab
import CoreMedia

class VLETimeLineStateModel {
    
    var renderSize: CGSize
    var totalSeconds: Float = 0
    var totalDuration: CMTime = CMTime.zero
    var currentSelectedItemModel: VLETimeLineItemModel?
    var currentSelectedIndex: Int?
    
    private var pendingOverlayScale: Float?
    // ✅ ADD NEW PROPERTIES HERE
   private var pendingOverlayPosition: CGPoint?
   private var pendingOverlayStartTime: CMTime?
    var isHaveRenderTrack: Bool {
        if renderTrackItemModelArray.isEmpty && separateRenderTrackItemModelArray.isEmpty{
            return false
        } else {
            return true
        }
    }
    private var _renderTrackItemModelArray: [VLETimeLineItemModel] = []
    private var _separateRenderTrackItemModelArray: [VLETimeLineItemModel] = []
    public var renderTrackItemModelArray: [VLETimeLineItemModel] {
        get {
            return _renderTrackItemModelArray
        }
        set {
            _renderTrackItemModelArray = newValue
            if _renderTrackItemModelArray.isEmpty && _separateRenderTrackItemModelArray.isEmpty {
                NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: VLEConstants.VLETimeLineAssetDidIsEmptyNotification), object: self)
            } else {
                NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: VLEConstants.VLETimeLineAssetDidIsNonemptyNotification), object: self)
            }
        }
    }
    public var separateRenderTrackItemModelArray: [VLETimeLineItemModel] {
        get {
            return _separateRenderTrackItemModelArray
        }
        set {
            _separateRenderTrackItemModelArray = newValue
            if _renderTrackItemModelArray.isEmpty && _separateRenderTrackItemModelArray.isEmpty {
                NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: VLEConstants.VLETimeLineAssetDidIsEmptyNotification), object: self)
            } else {
                NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: VLEConstants.VLETimeLineAssetDidIsNonemptyNotification), object: self)
            }
        }
    }
    init() {
        self.renderSize = CGSize.init(width: 1280, height: 720)
    }
    
    public func setPendingOverlayScale(_ scale: Float) {
        pendingOverlayScale = scale
        print("🎯 Pending overlay scale set: \(scale)")
    }
    
    public func getPendingOverlayScale() -> Float? {
        return pendingOverlayScale
    }

    public func fetchScaleSpaceWidth() -> CGFloat {
        return CGFloat.init(VLETimeLineConfig.framesPerSpace) * VLETimeLineConfig.ptPerFrames
    }
    
    public func fetchScaleViewWidth() -> CGFloat {
        return calculateScaleWidth()
    }

    public func fetchScaleFrontMargin() -> CGFloat {
        return VLETimeLineConfig.frontMargin
    }
    
    public func fetchScaleBackMargin() -> CGFloat {
        return VLETimeLineConfig.backMargin
    }

    private func calculateScaleWidth() -> CGFloat {
        return CGFloat.init(totalSeconds*VLETimeLineConfig.framesPerSecond) * VLETimeLineConfig.ptPerFrames
    }

    // ✅ ADD NEW COMPUTED PROPERTIES
    var isValidComposition: Bool {
        return !renderTrackItemModelArray.isEmpty || !separateRenderTrackItemModelArray.isEmpty
    }

    var hasMainTrackOnly: Bool {
        return !renderTrackItemModelArray.isEmpty && separateRenderTrackItemModelArray.isEmpty
    }

    var hasOverlayOnly: Bool {
        return renderTrackItemModelArray.isEmpty && !separateRenderTrackItemModelArray.isEmpty
    }

    var hasCompleteTimeline: Bool {
        return !renderTrackItemModelArray.isEmpty && !separateRenderTrackItemModelArray.isEmpty
    }

    // ✅ ADD VALIDATION METHOD
    func validateComposition() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        if renderTrackItemModelArray.isEmpty && separateRenderTrackItemModelArray.isEmpty {
            issues.append("No video content")
        }
        
        if renderTrackItemModelArray.isEmpty && !separateRenderTrackItemModelArray.isEmpty {
            issues.append("Only overlay content, missing main timeline")
        }
        
        // Check for time overlaps in main track
        for i in 1..<renderTrackItemModelArray.count {
            let prev = renderTrackItemModelArray[i-1]
            let current = renderTrackItemModelArray[i]
            let prevEnd = CMTimeAdd(prev.globalStartTime, prev.source.selectedTimeRange.duration)
            
            if current.globalStartTime < prevEnd {
                issues.append("Time overlap detected between segments \(i-1) and \(i)")
            }
        }
        
        return (issues.isEmpty, issues)
    }
    
    // ✅ FINAL WORKING VERSION - no private access needed:
    public func renderTrackItemModelConvertToSeparate(at selectIndex: Int, startTime: CMTime) {
        print("🔍 === SEPARATE OPERATION DEBUG ===")
        print("🔍 Before separate - Main track count: \(renderTrackItemModelArray.count)")
        print("🔍 Separating index: \(selectIndex)")
        
        guard selectIndex < renderTrackItemModelArray.count else {
            print("❌ Invalid index for separation")
            return
        }
        
        // ✅ Store main track duration BEFORE separation
        let originalMainDuration = calculateMainTrackDuration()
        print("🔍 Original main duration: \(CMTimeGetSeconds(originalMainDuration))s")
        
        // ✅ Get item to separate
        let selectedModel = renderTrackItemModelArray.remove(at: selectIndex)
        print("✅ Removed item from main track")
        
        // ✅ CRITICAL: Immediately refresh main track to close gaps
        refreshItemTime()
        print("✅ Main track compacted after removal")
        
        // ✅ Calculate overlay timing
        let requestedTime: CMTime
        if let pendingTime = pendingOverlayStartTime {
            requestedTime = pendingTime
            pendingOverlayStartTime = nil
            print("🕐 Using user-selected time: \(CMTimeGetSeconds(requestedTime))s")
        } else {
            requestedTime = startTime
            print("🕐 Using provided time: \(CMTimeGetSeconds(requestedTime))s")
        }
        
        // ✅ Validate timing
        let requestedSeconds = CMTimeGetSeconds(requestedTime)
        let overlayDurationSeconds = CMTimeGetSeconds(selectedModel.source.selectedTimeRange.duration)
        let originalMainSeconds = CMTimeGetSeconds(originalMainDuration)
        
        var finalStartTime: CMTime
        
        if requestedSeconds >= originalMainSeconds {
            finalStartTime = CMTime(seconds: max(0, originalMainSeconds - overlayDurationSeconds), preferredTimescale: 600)
            print("⚠️ Overlay time outside original timeline, corrected to: \(CMTimeGetSeconds(finalStartTime))s")
        } else if (requestedSeconds + overlayDurationSeconds) > originalMainSeconds {
            finalStartTime = CMTime(seconds: originalMainSeconds - overlayDurationSeconds, preferredTimescale: 600)
            print("⚠️ Overlay extends beyond original timeline, corrected to: \(CMTimeGetSeconds(finalStartTime))s")
        } else {
            finalStartTime = requestedTime
            print("✅ Overlay timing valid: \(CMTimeGetSeconds(finalStartTime))s")
        }
        
        // ✅ Configure overlay item
        selectedModel.globalStartTime = finalStartTime
        selectedModel.isSeparateRenderTrack = true
        selectedModel.renderLayer.timeRange = CMTimeRange(start: finalStartTime, duration: selectedModel.source.selectedTimeRange.duration)
        
        // ✅ Position setup
        let center: CGPoint
        if let overlayPosition = pendingOverlayPosition {
            center = overlayPosition
            pendingOverlayPosition = nil
            print("✅ Using selected position: \(center)")
        } else {
            let randomX = CGFloat.random(in: 0.25...0.75)
            let randomY = CGFloat.random(in: 0.25...0.75)
            center = CGPoint(x: randomX, y: randomY)
            print("🎲 Using random position: \(center)")
        }
        
        // ✅ FIXED: Simple scale calculation without private properties
        let overlayScale = getOverlayScale()
        let transform = Transform(center: center, rotation: 0, scale: overlayScale)
        selectedModel.renderLayer.transform = transform
        
        separateRenderTrackItemModelArray.append(selectedModel)
        
        // ✅ Final refresh
        refreshItemTime()
        
        print("✅ Separate operation completed")
        print("📊 Final state - Main: \(renderTrackItemModelArray.count), Overlay: \(separateRenderTrackItemModelArray.count)")
        print("📊 New total duration: \(totalSeconds)s")
        print("🔍 === END SEPARATE DEBUG ===")
    }

    // ✅ SIMPLE helper method:
    private func getOverlayScale() -> Float {
        // ✅ Use pending scale if available
        if let pendingScale = pendingOverlayScale {
            pendingOverlayScale = nil
            print("🎯 Using user-selected scale: \(pendingScale)")
            return pendingScale
        }
        
        // ✅ Default to larger scale for better visibility
        return 0.35  // 35% - larger than before to show full frame
    }
    
    // ✅ REPLACE calculateOptimalOverlayScale method trong VLETimeLineStateModel.swift:
    private func calculateOptimalOverlayScale(for itemModel: VLETimeLineItemModel) -> Float {
        // ✅ Use pending scale if available
        if let pendingScale = pendingOverlayScale {
            pendingOverlayScale = nil  // Clear after use
            print("🎯 Using user-selected scale: \(pendingScale)")
            return pendingScale
        }
        
        // ✅ FIX: Use source duration and type instead of private asset
        let sourceDuration = CMTimeGetSeconds(itemModel.source.duration)
        let itemType = itemModel.type
        
        print("🎯 Calculating scale for type: \(itemType), duration: \(sourceDuration)s")
        
        // ✅ Scale based on content type and duration
        var optimalScale: Float
        
        switch itemType {
        case .video:
            // ✅ Video content - use medium scale
            if sourceDuration > 30 {
                optimalScale = 0.25  // Longer videos - smaller overlay
            } else {
                optimalScale = 0.35  // Shorter videos - larger overlay
            }
            
        case .image:
            // ✅ Image content - can be larger
            optimalScale = 0.4
            
        default:
            // ✅ Other content
            optimalScale = 0.3
        }
        
        print("🎯 Calculated optimal scale: \(optimalScale)")
        
        return optimalScale
    }
    
    public func clipSeparateRenderTrackItemModelAtCurrentIndex(clipRate rate: Float, completion: @escaping (NSError?, VLETimeLineItemModel?) -> Void) {
        guard let itemModel = currentSelectedItemModel else {
            return
        }
        let selectedDuration = self.calculateSelectedTime(at: Float(rate), sourceTime: itemModel.source.selectedTimeRange.duration)
        let newItemModel = VLETimeLineItemModel.init(with: itemModel.source, type: itemModel.type)
        newItemModel.isSeparateRenderTrack = true
        newItemModel.source = itemModel.source.copy()
        newItemModel.source.load { error in
            if error == nil {
                newItemModel.globalStartTime = CMTimeAdd(itemModel.globalStartTime, selectedDuration)
                newItemModel.source.selectedTimeRange.start = CMTimeAdd(itemModel.source.selectedTimeRange.start, selectedDuration)
                newItemModel.source.selectedTimeRange.duration = CMTimeSubtract(itemModel.source.selectedTimeRange.duration, selectedDuration)
                newItemModel.renderLayer.timeRange = CMTimeRange.init(start: newItemModel.globalStartTime, duration: newItemModel.source.selectedTimeRange.duration)
                itemModel.source.selectedTimeRange.duration = selectedDuration
                newItemModel.generateThumbnails(with: 1) { _ in}
                self.separateRenderTrackItemModelArray.insert(newItemModel, at: self.currentSelectedIndex!+1)
                completion(nil, newItemModel)
            } else {
                completion(NSError.init(), nil)
            }
        }
    }

    public func calculateSelectedTime(at rate: Float, sourceTime: CMTime) -> CMTime{
        let value = sourceTime.value * Int64(rate * 100) / 100
        let timescale = sourceTime.timescale
        return CMTime.init(value: value, timescale: timescale)
    }

    // ✅ REPLACE method trong VLETimeLineStateModel.swift:
    public func clipRenderTrackItemModelAtCurrentIndex(clipRate rate: Float, completion: @escaping (NSError?) -> Void) {
        guard let itemModel = currentSelectedItemModel else {
            print("❌ No current selected item for clipping")
            completion(NSError())
            return
        }
        
        print("✂️ === CLIP OPERATION DEBUG ===")
        print("✂️ Clip rate: \(rate)")
        print("✂️ Original duration: \(CMTimeGetSeconds(itemModel.source.selectedTimeRange.duration))s")
        
        let selectedDuration = calculateSelectedTime(at: Float(rate), sourceTime: itemModel.source.selectedTimeRange.duration)
        let remainingDuration = CMTimeSubtract(itemModel.source.selectedTimeRange.duration, selectedDuration)
        
        print("✂️ Selected duration: \(CMTimeGetSeconds(selectedDuration))s")
        print("✂️ Remaining duration: \(CMTimeGetSeconds(remainingDuration))s")
        
        let newItemModel = VLETimeLineItemModel.init(with: itemModel.source, type: itemModel.type)
        newItemModel.isSeparateRenderTrack = false
        newItemModel.source = itemModel.source.copy()
        
        newItemModel.source.load { [weak self] error in
            guard let self = self else { return }
            
            if error == nil {
                // ✅ Setup new item (right part)
                newItemModel.globalStartTime = CMTimeAdd(itemModel.globalStartTime, selectedDuration)
                newItemModel.source.selectedTimeRange.start = CMTimeAdd(itemModel.source.selectedTimeRange.start, selectedDuration)
                newItemModel.source.selectedTimeRange.duration = remainingDuration
                newItemModel.renderLayer.timeRange = CMTimeRange(start: newItemModel.globalStartTime, duration: remainingDuration)
                
                // ✅ Update original item (left part)
                itemModel.source.selectedTimeRange.duration = selectedDuration
                itemModel.renderLayer.timeRange.duration = selectedDuration
                
                print("✅ Original item updated: duration=\(CMTimeGetSeconds(selectedDuration))s")
                print("✅ New item created: start=\(CMTimeGetSeconds(newItemModel.globalStartTime))s, duration=\(CMTimeGetSeconds(remainingDuration))s")
                
                // ✅ CRITICAL: Generate thumbnails BEFORE inserting into array
                let thumbnailGroup = DispatchGroup()
                
                // Generate thumbnails for original item (may need refresh)
                thumbnailGroup.enter()
                itemModel.generateThumbnails(with: max(1, Int(CMTimeGetSeconds(selectedDuration) / 2))) { _ in
                    print("✅ Original item thumbnails updated")
                    thumbnailGroup.leave()
                }
                
                // Generate thumbnails for new item
                thumbnailGroup.enter()
                newItemModel.generateThumbnails(with: max(1, Int(CMTimeGetSeconds(remainingDuration) / 2))) { _ in
                    print("✅ New item thumbnails generated")
                    thumbnailGroup.leave()
                }
                
                // ✅ Wait for ALL thumbnails before proceeding
                thumbnailGroup.notify(queue: .main) {
                    // Insert new item AFTER thumbnails ready
                    self.renderTrackItemModelArray.insert(newItemModel, at: self.currentSelectedIndex! + 1)
                    self.refreshItemTime()
                    
                    print("✂️ === CLIP COMPLETED ===")
                    completion(nil)
                }
                
            } else {
                print("❌ Clip operation failed: \(String(describing: error))")
                completion(NSError())
            }
        }
    }

    public func refreshItemTime() {
        var sum: CMTime = CMTime.zero
        for item in renderTrackItemModelArray {
            item.globalStartTime = sum
            item.renderLayer.timeRange = CMTimeRange.init(start: sum, duration: item.source.selectedTimeRange.duration)
            sum = CMTimeAdd(sum, item.source.selectedTimeRange.duration)
        }
        for item in separateRenderTrackItemModelArray {
            let endTime = CMTimeAdd(item.globalStartTime, item.source.selectedTimeRange.duration)
            sum = CMTimeMaximum(sum, endTime)
        }
        self.totalDuration = sum
        self.totalSeconds = VLETimeLineConfig.convertToSecond(value: sum)
    }

    public func swapItemForRenderTrack(selectedIndex: Int, targetIndex: Int) {
        let selectedModel = renderTrackItemModelArray.remove(at: selectedIndex)
        renderTrackItemModelArray.insert(selectedModel, at: targetIndex)
    }
    
    // ✅ ADD THESE NEW METHODS:

    // MARK: - Pending Overlay State

    public func setPendingOverlayPosition(_ position: CGPoint) {
        pendingOverlayPosition = position
        print("🎯 Pending overlay position set: \(position)")
    }

    public func setPendingOverlayStartTime(_ time: CMTime) {
        pendingOverlayStartTime = time
        print("🕐 Pending overlay start time set: \(CMTimeGetSeconds(time))s")
    }

    public func getPendingOverlayStartTime() -> CMTime? {
        return pendingOverlayStartTime
    }

    func calculateMainTrackDuration() -> CMTime {
        guard !renderTrackItemModelArray.isEmpty else {
            return CMTime(seconds: 10, preferredTimescale: 600)  // 10 second minimum for empty timeline
        }
        
        var totalDuration = CMTime.zero
        for item in renderTrackItemModelArray {
            totalDuration = CMTimeAdd(totalDuration, item.source.selectedTimeRange.duration)
        }
        
        print("🔍 Main track duration calculated: \(CMTimeGetSeconds(totalDuration))s")
        return totalDuration
    }
    
    func validateTimelineConsistency() -> Bool {
        print("🔍 === TIMELINE VALIDATION ===")
        
        // Check main track continuity
        var expectedStart = CMTime.zero
        for (index, item) in renderTrackItemModelArray.enumerated() {
            if item.globalStartTime != expectedStart {
                print("❌ Gap detected at index \(index): expected \(CMTimeGetSeconds(expectedStart))s, got \(CMTimeGetSeconds(item.globalStartTime))s")
                return false
            }
            expectedStart = CMTimeAdd(expectedStart, item.source.selectedTimeRange.duration)
        }
        
        print("✅ Main track is continuous")
        print("📊 Main track duration: \(CMTimeGetSeconds(expectedStart))s")
        print("📊 Total timeline: \(totalSeconds)s")
        
        return true
    }
}
