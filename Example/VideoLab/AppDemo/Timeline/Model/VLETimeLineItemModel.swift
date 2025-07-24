//
//  VLETimeLineItemModel.swift
//  VideoLab_Example
//
//  UPDATED: Added linked segments support
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
    
    // 🆕 NEW: Properties để track linked segments
    var originalSourceID: String = ""         // ID của video gốc
    var segmentIndex: Int = 0                 // Thứ tự segment trong video gốc
    var originalSourceDuration: CMTime = CMTime.zero // Duration của video gốc
    var originalSourceStartTime: CMTime = CMTime.zero // Start time trong video gốc

    init(with source: Source, type: VLETimeLineItemType) {
        self.source = source
        self.type = type
        self.renderLayer = RenderLayer.init(timeRange: source.selectedTimeRange, source: source)
    }

    // 🆕 NEW: Method để tìm segment liền kề
    func findAdjacentSegments(in itemArray: [VLETimeLineItemModel]) -> (previous: VLETimeLineItemModel?, next: VLETimeLineItemModel?) {
        let sameSourceSegments = itemArray.filter { $0.originalSourceID == self.originalSourceID }
            .sorted { $0.segmentIndex < $1.segmentIndex }
        
        guard let currentIndex = sameSourceSegments.firstIndex(where: { $0 === self }) else {
            return (nil, nil)
        }
        
        let previous = currentIndex > 0 ? sameSourceSegments[currentIndex - 1] : nil
        let next = currentIndex < sameSourceSegments.count - 1 ? sameSourceSegments[currentIndex + 1] : nil
        
        return (previous, next)
    }
    
    // 🆕 NEW: Method chính để handle resize với linked segments
    func recomputeLinkedDuration(
        isLeftEdge: Bool,
        offset: CGFloat,
        adjacentSegments: (previous: VLETimeLineItemModel?, next: VLETimeLineItemModel?)
    ) -> Bool {
        let offsetSecond = VLETimeLineConfig.convertToSecond(value: abs(offset))
        let offsetValue = offsetSecond * Float(source.selectedTimeRange.duration.timescale)
        let offsetTime = CMTime(value: CMTimeValue(offsetValue), timescale: source.selectedTimeRange.duration.timescale)
        
        if isLeftEdge {
            return handleLeftEdgeResize(offset: offset, offsetTime: offsetTime, previousSegment: adjacentSegments.previous)
        } else {
            return handleRightEdgeResize(offset: offset, offsetTime: offsetTime, nextSegment: adjacentSegments.next)
        }
    }
    
    // 🆕 NEW: Handle left edge resize
    private func handleLeftEdgeResize(offset: CGFloat, offsetTime: CMTime, previousSegment: VLETimeLineItemModel?) -> Bool {
        let minDuration = CMTime(seconds: 0.1, preferredTimescale: 600)
        
        if offset > 0 { // Kéo sang phải - cắt ngắn đầu segment hiện tại
            // Kiểm tra không cắt quá ngắn
            let newDuration = CMTimeSubtract(source.selectedTimeRange.duration, offsetTime)
            guard newDuration > minDuration else { return false }
            
            // Cập nhật segment hiện tại
            let newStart = CMTimeAdd(source.selectedTimeRange.start, offsetTime)
            source.selectedTimeRange = CMTimeRange(start: newStart, duration: newDuration)
            originalSourceStartTime = CMTimeAdd(originalSourceStartTime, offsetTime)
            
            // Mở rộng segment trước đó (nếu có và linked)
            if let prevSegment = previousSegment {
                let newPrevDuration = CMTimeAdd(prevSegment.source.selectedTimeRange.duration, offsetTime)
                
                // Kiểm tra không vượt quá ranh giới
                let maxPrevEnd = originalSourceStartTime
                let currentPrevEnd = CMTimeAdd(prevSegment.originalSourceStartTime, newPrevDuration)
                guard currentPrevEnd <= maxPrevEnd else { return false }
                
                prevSegment.source.selectedTimeRange.duration = newPrevDuration
            }
            
        } else { // Kéo sang trái - khôi phục đầu segment hiện tại
            // Kiểm tra có thể khôi phục không
            let newOriginalStart = CMTimeSubtract(originalSourceStartTime, offsetTime)
            guard newOriginalStart >= CMTime.zero else { return false }
            
            // Cập nhật segment hiện tại
            let newDuration = CMTimeAdd(source.selectedTimeRange.duration, offsetTime)
            let newSourceStart = CMTimeSubtract(source.selectedTimeRange.start, offsetTime)
            source.selectedTimeRange = CMTimeRange(start: newSourceStart, duration: newDuration)
            originalSourceStartTime = newOriginalStart
            
            // Cắt ngắn segment trước đó (nếu có và linked)
            if let prevSegment = previousSegment {
                let newPrevDuration = CMTimeSubtract(prevSegment.source.selectedTimeRange.duration, offsetTime)
                guard newPrevDuration > minDuration else { return false }
                
                prevSegment.source.selectedTimeRange.duration = newPrevDuration
            }
        }
        
        return true
    }
    
    // 🆕 NEW: Handle right edge resize
    private func handleRightEdgeResize(offset: CGFloat, offsetTime: CMTime, nextSegment: VLETimeLineItemModel?) -> Bool {
        let minDuration = CMTime(seconds: 0.1, preferredTimescale: 600)
        
        if offset < 0 { // Kéo sang trái - cắt ngắn cuối segment hiện tại
            let newDuration = CMTimeSubtract(source.selectedTimeRange.duration, offsetTime)
            guard newDuration > minDuration else { return false }
            
            // Cập nhật segment hiện tại
            source.selectedTimeRange.duration = newDuration
            
            // Mở rộng segment tiếp theo (nếu có và linked)
            if let nextSeg = nextSegment {
                let newNextStart = CMTimeSubtract(nextSeg.originalSourceStartTime, offsetTime)
                let newNextDuration = CMTimeAdd(nextSeg.source.selectedTimeRange.duration, offsetTime)
                let newNextSourceStart = CMTimeSubtract(nextSeg.source.selectedTimeRange.start, offsetTime)
                
                nextSeg.source.selectedTimeRange = CMTimeRange(start: newNextSourceStart, duration: newNextDuration)
                nextSeg.originalSourceStartTime = newNextStart
            }
            
        } else { // Kéo sang phải - khôi phục cuối segment hiện tại
            // Kiểm tra có thể mở rộng không
            let currentEnd = CMTimeAdd(originalSourceStartTime, source.selectedTimeRange.duration)
            let newEnd = CMTimeAdd(currentEnd, offsetTime)
            
            if let nextSeg = nextSegment {
                // Không được vượt qua segment tiếp theo
                guard newEnd <= nextSeg.originalSourceStartTime else { return false }
            } else {
                // Không được vượt quá video gốc
                guard newEnd <= originalSourceDuration else { return false }
            }
            
            // Cập nhật segment hiện tại
            let newDuration = CMTimeAdd(source.selectedTimeRange.duration, offsetTime)
            source.selectedTimeRange.duration = newDuration
            
            // Cắt ngắn segment tiếp theo (nếu có và linked)
            if let nextSeg = nextSegment {
                let newNextStart = CMTimeAdd(nextSeg.originalSourceStartTime, offsetTime)
                let newNextDuration = CMTimeSubtract(nextSeg.source.selectedTimeRange.duration, offsetTime)
                let newNextSourceStart = CMTimeAdd(nextSeg.source.selectedTimeRange.start, offsetTime)
                
                guard newNextDuration > minDuration else { return false }
                
                nextSeg.source.selectedTimeRange = CMTimeRange(start: newNextSourceStart, duration: newNextDuration)
                nextSeg.originalSourceStartTime = newNextStart
            }
        }
        
        return true
    }

    // 🔄 KEEP EXISTING: Methods để compatibility với code cũ
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

    func recomputeSelectedDurationOf(originalDuration: CMTime, offset: CGFloat) -> Bool {
        let offsetSecond = VLETimeLineConfig.convertToSecond(value: abs(offset))
        let offsetValue = offsetSecond * Float(originalDuration.timescale)
        let offsetTime = CMTime.init(value: CMTimeValue.init(offsetValue), timescale: originalDuration.timescale)
        var tmpTime = CMTime.zero
        if offset < 0 {
            tmpTime = CMTimeSubtract(originalDuration, offsetTime)
        } else {
            tmpTime = CMTimeAdd(originalDuration, offsetTime)
        }
        if (tmpTime > self.source.duration) && (self.type != .image) {
            return false
        }
        if tmpTime < CMTime.zero {
            return false
        }
        self.source.selectedTimeRange.duration = tmpTime
        self.renderLayer.timeRange.duration = tmpTime
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
