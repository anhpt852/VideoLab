//
//  VLETimeLineRenderTrackSegmentView.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/9/16.
//  Copyright © 2022 Chocolate. All rights reserved.
//  UPDATED: Added linked segments visual feedback
//

import UIKit
import VideoLab
import AVFoundation
import Metal
import MetalKit

class VLETimeLineRenderTrackSegmentView: UIView {

    var thumbnailImageViewArray: [UIImageView] = []
    let model: VLETimeLineItemModel

    init(with model: VLETimeLineItemModel) {
        self.model = model
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1
        
        // 🆕 NEW: Add visual indicator cho linked segments
        if model.segmentIndex > 0 {
            addSegmentNumberIndicator()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshThumbnailImageView(count: Int) {
        if thumbnailImageViewArray.isEmpty {
            var idx = count
            while idx > 0 {
                let imageView = UIImageView.init()
                imageView.contentMode = UIView.ContentMode.scaleAspectFill
                imageView.isUserInteractionEnabled = false
                imageView.clipsToBounds = true
                thumbnailImageViewArray.append(imageView)
                self.addSubview(imageView)
                imageView.snp.makeConstraints { make in
                    make.width.height.equalTo(self.snp.height)
                    make.centerY.equalToSuperview()
                    make.left.equalTo(self.snp.left).offset(64 * CGFloat((count - idx)))
                }
                idx -= 1
            }

            self.model.generateThumbnails(with: count) { error in
                if error == nil {
                    DispatchQueue.main.async {
                        if self.model.source is PHAssetImageSource {
                            for imageView in self.thumbnailImageViewArray {
                                let image = self.model.thumbnailImageArray.first
                                imageView.image = image
                            }
                        } else {
                            var index = 0
                            for imageView in self.thumbnailImageViewArray {
                                let image = self.model.thumbnailImageArray[index]
                                imageView.image = image
                                index += 1
                            }
                        }
                    }
                }
            }
        } else {
            for item in thumbnailImageViewArray {
                item.removeFromSuperview()
            }
            thumbnailImageViewArray.removeAll()
        }
        
        // 🆕 NEW: Add segment info if this is a linked segment
        if model.segmentIndex > 0 {
            addSegmentInfoLabel()
        }
    }
    
    // 🆕 NEW: Visual feedback for linked segments
    func highlightAsLinked(isExpanding: Bool) {
        let highlightColor = isExpanding ? UIColor.systemGreen : UIColor.systemOrange
        
        UIView.animate(withDuration: 0.2) {
            self.layer.borderColor = highlightColor.cgColor
            self.layer.borderWidth = 3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIView.animate(withDuration: 0.2) {
                self.layer.borderColor = UIColor.white.cgColor
                self.layer.borderWidth = 1
            }
        }
    }
    
    // 🆕 NEW: Add segment number indicator
    private func addSegmentNumberIndicator() {
        let indicator = UILabel()
        indicator.text = "\(model.segmentIndex + 1)"
        indicator.textColor = UIColor.white
        indicator.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        indicator.font = UIFont.systemFont(ofSize: 8, weight: .bold)
        indicator.textAlignment = .center
        indicator.layer.cornerRadius = 6
        indicator.clipsToBounds = true
        
        self.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.width.height.equalTo(12)
            make.top.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-2)
        }
    }
    
    // 🆕 NEW: Add segment info label (called from refreshThumbnailImageView)
    private func addSegmentInfoLabel() {
        // Remove existing label if any
        for subview in self.subviews {
            if subview is UILabel && subview.tag == 999 {
                subview.removeFromSuperview()
            }
        }
        
        let infoLabel = UILabel()
        infoLabel.tag = 999 // Tag to identify this label
        infoLabel.text = "\(model.segmentIndex + 1)"
        infoLabel.textColor = UIColor.white
        infoLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        infoLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        infoLabel.textAlignment = .center
        infoLabel.layer.cornerRadius = 8
        infoLabel.clipsToBounds = true
        
        self.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.top.equalToSuperview().offset(4)
            make.left.equalToSuperview().offset(4)
        }
    }
    
    // 🆕 NEW: Add link indicator between segments
    private func addLinkIndicatorIfNeeded() {
        // Add small blue dot at bottom to indicate this is a linked segment
        if model.segmentIndex > 0 {
            let linkDot = UIView()
            linkDot.backgroundColor = UIColor.systemBlue
            linkDot.layer.cornerRadius = 2
            
            self.addSubview(linkDot)
            linkDot.snp.makeConstraints { make in
                make.width.height.equalTo(4)
                make.bottom.equalToSuperview().offset(-2)
                make.left.equalToSuperview().offset(4)
            }
        }
    }
    
    // 🆕 NEW: Convenience methods for linked segment states
    func showAsLinkedSegment() {
        addLinkIndicatorIfNeeded()
        if model.segmentIndex > 0 {
            addSegmentInfoLabel()
        }
    }
    
    func hideLinkedSegmentIndicators() {
        // Remove segment info label
        for subview in self.subviews {
            if subview.tag == 999 {
                subview.removeFromSuperview()
            }
        }
    }
    
    // 🆕 NEW: Update visual state based on segment properties
    func updateLinkedSegmentVisuals() {
        if model.segmentIndex > 0 || !model.originalSourceID.isEmpty {
            showAsLinkedSegment()
        } else {
            hideLinkedSegmentIndicators()
        }
    }
}
