//
//  VLETimeLineItemModel.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/10/7.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import VideoLab
import CoreMedia
import AVFoundation

enum VLETimeLineItemType {
    case image
    case audio
    case video
    case text
    case sticker
}

class VLETimeLineItemModel {
    var source: Source
    var type: VLETimeLineItemType
    var renderLayer: RenderLayer
    var globalStartTime: CMTime = CMTime.zero
    var thumbnailImageArray: [UIImage] = []
    var isSeparateRenderTrack: Bool = false
    
    init(with source: Source, type: VLETimeLineItemType) {
        self.source = source
        self.type = type
        self.renderLayer = RenderLayer.init(timeRange: source.selectedTimeRange, source: source)
    }

    func recomputeSelectedStartTimeOf(originalTime: CMTime, offset: CGFloat) {
        let offsetSecond = VLETimeLineConfig.convertToSecond(value: abs(offset))
        let offsetValue = offsetSecond * Float(originalTime.timescale)
        let offsetTime = CMTime.init(value: CMTimeValue.init(offsetValue), timescale: originalTime.timescale)
        if offset < 0 {
            self.source.selectedTimeRange.start = CMTimeSubtract(originalTime, offsetTime)
        } else {
            self.source.selectedTimeRange.start = CMTimeAdd(originalTime, offsetTime)
        }
    }

    // ✅ REPLACE EXISTING METHOD
    func recomputeSelectedDurationOf(originalDuration: CMTime, offset: CGFloat) -> Bool {
        let offsetSecond = VLETimeLineConfig.convertToSecond(value: abs(offset))
        let offsetValue = offsetSecond * Float(originalDuration.timescale)
        let offsetTime = CMTime(value: CMTimeValue(offsetValue), timescale: originalDuration.timescale)
        
        var newDuration: CMTime
        if offset < 0 {
            newDuration = CMTimeSubtract(originalDuration, offsetTime)
        } else {
            newDuration = CMTimeAdd(originalDuration, offsetTime)
        }
        
        // ✅ IMPROVED VALIDATION
        let minDuration = CMTime(seconds: 0.1, preferredTimescale: 600)  // Minimum 0.1 seconds
        let maxDuration = self.source.duration  // Cannot exceed source duration
        
        // ✅ DETAILED LOGGING
        if newDuration < minDuration {
            print("❌ Duration too short: \(CMTimeGetSeconds(newDuration))s, minimum: \(CMTimeGetSeconds(minDuration))s")
            return false
        }
        
        if newDuration > maxDuration && self.type != .image {
            print("❌ Duration too long: \(CMTimeGetSeconds(newDuration))s, maximum: \(CMTimeGetSeconds(maxDuration))s")
            return false
        }
        
        if newDuration < CMTime.zero {
            print("❌ Negative duration: \(CMTimeGetSeconds(newDuration))s")
            return false
        }
        
        // ✅ SUCCESS
        self.source.selectedTimeRange.duration = newDuration
        self.renderLayer.timeRange.duration = newDuration
        print("✅ Duration updated: \(CMTimeGetSeconds(newDuration))s")
        return true
    }

    func recomputeGlobalStartTimeOf(originalTime: CMTime, offset: CGFloat) {
        let offsetSecond = VLETimeLineConfig.convertToSecond(value: abs(offset))
        let offsetValue = offsetSecond * Float(originalTime.timescale)
        let offsetTime = CMTime.init(value: CMTimeValue.init(offsetValue), timescale: originalTime.timescale)
        if offset < 0 {
            self.globalStartTime = CMTimeSubtract(originalTime, offsetTime)
        } else {
            self.globalStartTime = CMTimeAdd(originalTime, offsetTime)
        }
        self.renderLayer.timeRange.start = self.globalStartTime
    }

    func generateThumbnails(with count: Int, completion: @escaping (NSError?) -> Void) {
        if self.source is PHAssetVideoSource {
            if self.thumbnailImageArray.isEmpty == false {
                self.thumbnailImageArray.removeAll()
            }
            let phSource = self.source as! PHAssetVideoSource
            var times: [NSValue] = []
            let increment : Float = Float(self.source.duration.value) / Float(count)
            var currentValue : Float = 2 * Float(self.source.duration.timescale)
            let zeroTime = CMTime.init(value: 0, timescale: self.source.duration.timescale)
            times.append(NSValue.init(time: zeroTime))
            while currentValue < Float(self.source.duration.value) {
                let time = CMTime.init(value: CMTimeValue.init(currentValue), timescale: self.source.duration.timescale)
                times.append(NSValue.init(time: time))
                currentValue += increment
            }

            phSource.thumbnails(for: times, maximumSize: CGSize.init(width: 720, height: 720)) { requestedTime, imageRef, actualTime, result, _ in
                if result == AVAssetImageGenerator.Result.succeeded {
                    DispatchQueue.main.async {
                        let image = UIImage.init(cgImage: imageRef!)
                        self.thumbnailImageArray.append(image)
                        if self.thumbnailImageArray.count == count {
                            completion(nil)
                        }
                    }
                }
            }
        } else if self.source is PHAssetImageSource {
            let phSource = self.source as! PHAssetImageSource
            var imageCount = 0
            let increment : Float = Float(self.source.duration.value) / Float(count)
            var currentValue : Float = 2 * Float(self.source.duration.timescale)
            while currentValue < Float(self.source.duration.value) {
                imageCount += 1
                currentValue += increment
            }
            let image = UIImage.init(cgImage: (phSource.texture(at: CMTime.zero)?.texture.toImage())!)
            self.thumbnailImageArray.append(image)
            completion(nil)
        }
    }
}
