//
//  VLETimeLineRenderTrackView.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/9/16.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import UIKit
import VideoLab

protocol VLETimeLineRenderTrackViewDelegate: NSObjectProtocol {
    func showDragSortRenderTrackSegmentView(with selectedIndex: Int)
    func startDragSortRenderTrackSegmentView(with sender: UILongPressGestureRecognizer)
    func continuedDragSortRenderTrackSegmentView(with sender: UILongPressGestureRecognizer)
    func endDragSortRenderTrackSegmentView(with sender: UILongPressGestureRecognizer)
    func showRenderTrackDragView(with sourceView: VLETimeLineRenderTrackSegmentView, index: Int)
}

class VLETimeLineRenderTrackView: UIView {
    
    var segmentViewArray: [VLETimeLineRenderTrackSegmentView] = []
    weak var delegate: VLETimeLineRenderTrackViewDelegate?

    init(delegate: VLETimeLineRenderTrackViewDelegate) {
        self.delegate = delegate
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
    }
    
    @objc func longGressGestureRecognizerAction(longGress: UILongPressGestureRecognizer) {
        switch longGress.state {
        case .began:
            let selectedIndex = segmentViewArray.firstIndex(of: longGress.view! as! VLETimeLineRenderTrackSegmentView)
            
            // ✅ FIX: Add validation
            guard let safeIndex = selectedIndex, safeIndex < segmentViewArray.count else {
                print("❌ Invalid long press index")
                return
            }
            
            // ✅ FIX: Only trigger drag sort with intentional gesture
            let location = longGress.location(in: longGress.view)
            let viewBounds = longGress.view!.bounds
            
            // Check if long press is in center area (not near edges where resize handles are)
            let centerArea = CGRect(x: viewBounds.width * 0.2,
                                   y: 0,
                                   width: viewBounds.width * 0.6,
                                   height: viewBounds.height)
            
            if centerArea.contains(location) {
                self.delegate?.showDragSortRenderTrackSegmentView(with: safeIndex)
                self.delegate?.startDragSortRenderTrackSegmentView(with: longGress)
            } else {
                print("⚠️ Long press too close to edge, ignoring to prevent accidental drag sort")
            }
        case .changed:
            self.delegate?.continuedDragSortRenderTrackSegmentView(with: longGress)
        case .ended:
            self.delegate?.endDragSortRenderTrackSegmentView(with: longGress)
        default:
            print("Long press gesture state: \(longGress.state.rawValue)")
        }
    }

    
    @objc func tapGestureRecognizerAction(tapGesture: UITapGestureRecognizer) {
        let view = tapGesture.view as! VLETimeLineRenderTrackSegmentView
        let index = segmentViewArray.firstIndex(of: view)
        
        // ✅ FIX: Add safety check
        guard let safeIndex = index, safeIndex < segmentViewArray.count else {
            print("❌ Invalid tap gesture index")
            return
        }
        
        self.delegate?.showRenderTrackDragView(with: view, index: safeIndex)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func removeAllSegmentView() {
        for item in segmentViewArray {
            item.removeFromSuperview()
        }
        segmentViewArray.removeAll()
    }

    func refreshSegmentViewWith(itemModelArray: [VLETimeLineItemModel]) {
        guard !itemModelArray.isEmpty else {
            return
        }
        removeAllSegmentView()
        var second: CGFloat = 0
        var width: CGFloat = 0
        var frontSegmentView: VLETimeLineRenderTrackSegmentView?
        for item in itemModelArray {
            second = CGFloat(item.source.selectedTimeRange.duration.value)/CGFloat(item.source.selectedTimeRange.duration.timescale)
            width = VLETimeLineConfig.convertToPt(value: Float(second))
            let segmentView = generateSegmentView(with: item)
            if frontSegmentView == nil {
                segmentView.snp.makeConstraints { make in
                    make.height.top.left.equalToSuperview()
                    make.width.equalTo(width)
                }
            } else {
                segmentView.snp.makeConstraints { make in
                    make.height.top.equalToSuperview()
                    make.width.equalTo(width)
                    make.left.equalTo(frontSegmentView!.snp.right)
                }
            }
            var count = Int(width/self.bounds.height)
            if width.truncatingRemainder(dividingBy: self.bounds.height) > 0 {
                count += 1
            }
            item.isSeparateRenderTrack = false
            segmentView.refreshThumbnailImageView(count: count)
            frontSegmentView = segmentView
        }
    }

    func generateSegmentView(with itemModel: VLETimeLineItemModel) -> VLETimeLineRenderTrackSegmentView {
        let segmentView = VLETimeLineRenderTrackSegmentView.init(with: itemModel)
        let longGress = UILongPressGestureRecognizer.init()
        longGress.addTarget(self, action: #selector(longGressGestureRecognizerAction(longGress:)))
        segmentView.addGestureRecognizer(longGress)
        let tapGuesture = UITapGestureRecognizer.init()
        tapGuesture.addTarget(self, action: #selector(tapGestureRecognizerAction(tapGesture:)))
        segmentView.addGestureRecognizer(tapGuesture)
        segmentViewArray.append(segmentView)
        self.addSubview(segmentView)
        return segmentView
    }
}
