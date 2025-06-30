//
//  VLETimeLineRenderTrackDragView.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/10/12.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia

protocol VLETimeLineRenderTrackDragViewDelegate: NSObjectProtocol {
    func renderTrackDragView(_ dragView: VLETimeLineRenderTrackDragView, targetView: VLETimeLineRenderTrackSegmentView, leftBorderDragWith offsetX: CGFloat, finalWidth: CGFloat)
    func renderTrackDragView(_ dragView: VLETimeLineRenderTrackDragView, targetView: VLETimeLineRenderTrackSegmentView, rightBorderDragWith offsetX: CGFloat, finalWidth: CGFloat)
    func renderTrackDragViewIsDragEnd()
}

class VLETimeLineRenderTrackDragView: UIView {
    
    var viewW: CGFloat = 0
    var targetViewW: CGFloat = 0
    var panGestureOriginX: CGFloat = 0
    let targetView: VLETimeLineRenderTrackSegmentView
    var originalSelectedDurtaion: CMTime = CMTime.zero
    var originalGlobalStartTime: CMTime = CMTime.zero
    var originalSelectedStartTime: CMTime = CMTime.zero
    weak var delegate: VLETimeLineRenderTrackDragViewDelegate?
    
    lazy var leftDragBlockView: UIView = {
        let view = UIView.init()
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(leftDragBlockViewGestureAction(sender:)))
        view.addGestureRecognizer(gesture)
        view.backgroundColor = UIColor.clear
        return view
    }()

    lazy var rightDragBlockView: UIView = {
        let view = UIView.init()
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(rightDragBlockViewGestureAction(sender:)))
        view.addGestureRecognizer(gesture)
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var middleAreaView: UIView = {
        let view = UIView.init()
        let gesture = UITapGestureRecognizer.init(target: self, action: #selector(middleAreaViewTapGestureAction(sender:)))
        view.addGestureRecognizer(gesture)
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        return view
    }()

    init(delegate: VLETimeLineRenderTrackDragViewDelegate, targetView: VLETimeLineRenderTrackSegmentView) {
        self.targetView = targetView
        self.delegate = delegate
        super.init(frame: CGRect.zero)
        self.addSubview(leftDragBlockView)
        self.addSubview(rightDragBlockView)
        self.addSubview(middleAreaView)
        leftDragBlockView.snp.makeConstraints { make in
            make.left.top.height.equalToSuperview()
            make.width.equalTo(24)
        }
        rightDragBlockView.snp.makeConstraints { make in
            make.right.top.height.equalToSuperview()
            make.width.equalTo(24)
        }
        middleAreaView.snp.makeConstraints { make in
            make.top.height.equalToSuperview()
            make.left.equalTo(leftDragBlockView.snp.right).offset(0)
            make.right.equalTo(rightDragBlockView.snp.left).offset(0)
        }
        addDragBlockRoundCornerLayer(isLeft: true)
        addDragBlockRoundCornerLayer(isLeft: false)
        addDragBlockArrowLayer(isLeft: true)
        addDragBlockArrowLayer(isLeft: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("")
    }
    
    @objc func middleAreaViewTapGestureAction(sender: UITapGestureRecognizer) {
    }

    // ✅ MODIFY EXISTING METHOD
    @objc func leftDragBlockViewGestureAction(sender: UIPanGestureRecognizer) {
        let point = sender.location(in: self.superview)
        
        if sender.state == .began {
            panGestureOriginX = point.x
            targetViewW = targetView.bounds.width
            viewW = self.bounds.width
            originalSelectedDurtaion = targetView.model.source.selectedTimeRange.duration
            originalGlobalStartTime = targetView.model.globalStartTime
            originalSelectedStartTime = targetView.model.source.selectedTimeRange.start
            
            print("🎬 Left drag started - Original duration: \(CMTimeGetSeconds(originalSelectedDurtaion))s")
        } else if sender.state == .changed {
            let offset = point.x - panGestureOriginX
            
            let minWidth: CGFloat = 10
            
            if offset >= 0 {
                if (targetViewW - offset) < minWidth {
                    print("⚠️ Left drag blocked: segment would be too small")
                    return
                }
            } else {
                // ✅ SIMPLIFIED: Direct check
                let offsetSeconds = VLETimeLineConfig.convertToSecond(value: abs(offset))
                let newStartTimeSeconds = CMTimeGetSeconds(originalGlobalStartTime) - Double(offsetSeconds)
                
                if newStartTimeSeconds < 0 {
                    print("⚠️ Left drag blocked: would go before timeline start")
                    return
                }
            }
            
            if offset >= 0 {
                // Moving start forward (shorten)
                if targetView.model.recomputeSelectedDurationOf(originalDuration: originalSelectedDurtaion, offset: -offset) == false {
                    print("❌ Left drag validation failed (forward)")
                    return
                }
                targetView.model.recomputeGlobalStartTimeOf(originalTime: originalGlobalStartTime, offset: offset)
                targetView.model.recomputeSelectedStartTimeOf(originalTime: originalSelectedStartTime, offset: offset)
                self.delegate?.renderTrackDragView(self, targetView: targetView, leftBorderDragWith: offset, finalWidth: targetViewW - offset)
            } else {
                // Moving start backward (extend)
                if targetView.model.recomputeSelectedDurationOf(originalDuration: originalSelectedDurtaion, offset: abs(offset)) == false {
                    print("❌ Left drag validation failed (backward)")
                    return
                }
                targetView.model.recomputeGlobalStartTimeOf(originalTime: originalGlobalStartTime, offset: offset) // offset is negative
                targetView.model.recomputeSelectedStartTimeOf(originalTime: originalSelectedStartTime, offset: offset)
                self.delegate?.renderTrackDragView(self, targetView: targetView, leftBorderDragWith: offset, finalWidth: targetViewW + abs(offset))
            }
        } else if sender.state == .ended {
            print("✅ Left drag completed")
            self.delegate?.renderTrackDragViewIsDragEnd()
        }
    }

    @objc func rightDragBlockViewGestureAction(sender: UIPanGestureRecognizer) {
        let point = sender.location(in: self.superview)
        
        if sender.state == .began {
            panGestureOriginX = point.x
            targetViewW = targetView.bounds.width
            viewW = self.bounds.width
            originalSelectedDurtaion = targetView.model.source.selectedTimeRange.duration
            
            print("🎬 Right drag started - Original duration: \(CMTimeGetSeconds(originalSelectedDurtaion))s")
        } else if sender.state == .changed {
            let offset = point.x - panGestureOriginX
            
            // ✅ Prevent overlay trigger
            let maxExtension = targetViewW * 2.0
            if offset > maxExtension {
                print("⚠️ Right drag blocked: extension too large, would trigger overlay mode")
                return
            }
            
            // ✅ Minimum width check
            if abs(offset) > (targetViewW - 10) {
                print("⚠️ Right drag blocked: segment would be too small")
                return
            }
            
            // ✅ SIMPLIFIED: Source duration check
            let offsetSeconds = VLETimeLineConfig.convertToSecond(value: offset)
            let newDurationSeconds = CMTimeGetSeconds(originalSelectedDurtaion) + Double(offsetSeconds)
            let sourceDurationSeconds = CMTimeGetSeconds(targetView.model.source.duration)
            
            if newDurationSeconds > sourceDurationSeconds {
                print("⚠️ Right drag blocked: would exceed source duration")
                return
            }
            
            if targetView.model.recomputeSelectedDurationOf(originalDuration: originalSelectedDurtaion, offset: offset) == false {
                print("❌ Right drag validation failed")
                return
            }
            
            self.delegate?.renderTrackDragView(self, targetView: targetView, rightBorderDragWith: offset, finalWidth: targetViewW + offset)
        } else if sender.state == .ended {
            print("✅ Right drag completed")
            self.delegate?.renderTrackDragViewIsDragEnd()
        }
    }

    func addDragBlockRoundCornerLayer(isLeft: Bool) {
        let path = UIBezierPath.init(roundedRect: CGRect.init(x: 0, y: 0, width: 24, height: targetView.frame.size.height), byRoundingCorners: isLeft ? [UIRectCorner.bottomLeft, UIRectCorner.topLeft] : [UIRectCorner.topRight, UIRectCorner.bottomRight], cornerRadii: CGSize.init(width: 10, height: 10))
        let layer = CAShapeLayer.init()
        layer.path = path.cgPath
        layer.fillColor = UIColor.white.cgColor
        if isLeft {
            leftDragBlockView.layer.addSublayer(layer)
        } else {
            rightDragBlockView.layer.addSublayer(layer)
        }
    }

    func addDragBlockArrowLayer(isLeft: Bool) {
        let weight = CGFloat.init(24)
        let height = targetView.frame.size.height
        let point0 = CGPoint.init(x: isLeft ? weight/3*2 : weight/3, y: height/3)
        let point1 = CGPoint.init(x: isLeft ? weight/3 : weight/3*2, y: height/3/2+height/3)
        let point2 = CGPoint.init(x: isLeft ? weight/3*2 : weight/3, y: height/3*2)
        let path = UIBezierPath.init()
        path.move(to: point0)
        path.addLine(to: point1)
        path.addLine(to: point2)
        path.close()
        let layer = CAShapeLayer.init()
        layer.path = path.cgPath
        layer.fillColor = UIColor.gray.cgColor
        if isLeft {
            leftDragBlockView.layer.addSublayer(layer)
        } else {
            rightDragBlockView.layer.addSublayer(layer)
        }
    }
}

extension VLETimeLineConfig {
    
    // ✅ Safe pixel to CMTime conversion
    class func convertToCMTime(fromPixels pixels: CGFloat) -> CMTime {
        let seconds = convertToSecond(value: pixels)
        return CMTime(seconds: Double(seconds), preferredTimescale: 600)
    }
    
    // ✅ Safe CMTime to pixel conversion
    class func convertToPixels(fromCMTime time: CMTime) -> CGFloat {
        let seconds = Float(CMTimeGetSeconds(time))
        return convertToPt(value: seconds)
    }
    
    // ✅ Safe offset calculation for drag operations
    class func pixelOffsetToTimeOffset(_ pixelOffset: CGFloat) -> CMTime {
           let offsetSeconds = convertToSecond(value: abs(pixelOffset))
           let timeValue = pixelOffset < 0 ? -Double(offsetSeconds) : Double(offsetSeconds)
           return CMTime(seconds: timeValue, preferredTimescale: 600)
       }
}
