//
//  VLEMainMediator.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/9/23.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import SwiftUI
import VideoLab
import CoreMedia

protocol VLEMainMediator {
    // picker
    func addAssetToRenderTrackWith(itemModelArray: [VLETimeLineItemModel])
    func addAudioToSeparateTrackWith(source: Source)
    func addStickerToSeparateTrackWith(source: Source)
    // export
    func buildCurrentTimeLineItemToExport() -> VideoLab?
    // timeline
    func addAssetWithPickerViewController()
    func addAudioWithPickerViewController()
    func addStickerWithPickerViewController()
    // playback
    func previewTimeLineItem(videoLab: VideoLab)
    func previewTimeLineItem(rate: Float64)
    func prepareTimeLineItemForPlayback()
    func playbackProgressValueDidChanged(currentTime: CMTime)
}

class VLEMainConcreteMediator: VLEMainMediator {

    weak var playbackViewController: VLEPlaybackViewController?
    weak var timelineViewController: VLETimeLineViewController?
    weak var effectViewController: VLEEffectViewController?
    weak var navViewController: VLENavViewController?
    weak var mainViewController: VLEMainViewController?
    static let shared = VLEMainConcreteMediator()
    
    private init() {}
    
    func addAssetWithPickerViewController() {
        let controller = VLEPickerViewController.init(type: VLEPickerItemType.album)
        self.mainViewController?.present(controller, animated: true)
    }
    
    func addAudioWithPickerViewController() {
        let controller = VLEPickerViewController.init(type: VLEPickerItemType.audio)
        self.mainViewController?.present(controller, animated: true)
    }
    
    func addStickerWithPickerViewController() {
        let controller = VLEPickerViewController.init(type: VLEPickerItemType.sticker)
        self.mainViewController?.present(controller, animated: true)
    }

    func addAssetToRenderTrackWith(itemModelArray: [VLETimeLineItemModel]){
        self.timelineViewController?.addAssetToRenderTrackViewWith(itemModelArray: itemModelArray)
    }

    func addAudioToSeparateTrackWith(source: Source) {
        self.timelineViewController?.addAudioToSeparateRenderLayerWith(source: source)
    }

    func addStickerToSeparateTrackWith(source: Source) {
        self.timelineViewController?.addStickerToSeparateRenderLayerWith(source: source)
    }

    func previewTimeLineItem(videoLab: VideoLab) {
        self.playbackViewController?.previewItem(with: videoLab)
    }

    func previewTimeLineItem(rate: Float64) {
        self.playbackViewController?.previewItem(with: rate)
    }

    func prepareTimeLineItemForPlayback() {
        if let videoLab = self.timelineViewController?.buildVideolab() {
            self.playbackViewController?.playbackItem(with: videoLab)
        }
    }
    
    func playbackProgressValueDidChanged(currentTime: CMTime) {
        self.timelineViewController?.updatePlaybackProgress(time: currentTime)
    }
    
    func buildCurrentTimeLineItemToExport() -> VideoLab? {
        return self.timelineViewController?.buildVideolab()
    }
    
    // ✅ ADD DEBUG HELPER
    #if DEBUG
    func debugCurrentState() {
        guard let timelineVC = timelineViewController else {
            print("❌ No timeline controller")
            return
        }
        
        print("\n🔍 === MEDIATOR DEBUG ===")
        print("Timeline loaded: \(timelineVC.isViewLoaded)")
        print("Playback loaded: \(playbackViewController?.isViewLoaded ?? false)")
        print("Effects loaded: \(effectViewController?.isViewLoaded ?? false)")
        
        if let videoLab = timelineVC.buildVideolab() {
            let composition = videoLab.renderComposition
            print("Composition layers: \(composition.layers.count)")
            print("Render size: \(composition.renderSize)")
        }
        print("=== END MEDIATOR DEBUG ===\n")
    }
    #endif
}
