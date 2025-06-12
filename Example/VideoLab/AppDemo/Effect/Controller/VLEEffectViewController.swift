//
//  VLEEffectViewController.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/7/21.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import VideoLab
import PhotosUI

class VLEEffectViewController: UIViewController{
    
    let model: VLEEffectItemModel = VLEEffectItemModel.init()
    lazy var firstLevelView: VLEEffectFirstLevelView = {
        let view = VLEEffectFirstLevelView.init(with: model)
        return view
    }()
    var onPush: ((UIViewController) -> Void)?
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.init(hexString: "#212123")
        self.view.addSubview(firstLevelView)
        firstLevelView.snp.makeConstraints { make in
            make.height.equalTo(52)
            make.width.top.left.equalToSuperview()
        }
        
        firstLevelView.onSelectFeature = { [weak self] feature in

            let captureVC = CaptureFrameViewController()
            self?.onPush?(captureVC)
        }
        
        firstLevelView.onCanvasUpdated = { [weak self] size, bgColor in
            // 🔧 Tùy cấu trúc project, bạn cần truyền đúng videoLab
            // 1. Layer 1
//            let url = Bundle.main.url(forResource: "video1", withExtension: "MOV")
//            let asset = AVAsset(url: url!)
//            let source = AVAssetSource(asset: asset)
//            source.selectedTimeRange = CMTimeRange(start: CMTime.zero, duration: asset.duration)
//            let timeRange = source.selectedTimeRange
//            let renderLayer1 = RenderLayer(timeRange: timeRange, source: source)
//            
//            // 2. Composition
//            let composition = RenderComposition()
//            composition.renderSize = size
//            composition.layers = [renderLayer1]
//
//            
//            composition.renderSize = size
//            composition.backgroundColor = Color.red
//            
//            // 3. VideoLab
//            let videoLab = VideoLab(renderComposition: composition)
//            
//            let playerItem = videoLab.makePlayerItem()
//            playerItem.seekingWaitsForVideoCompositionRendering = true
//            let controller = VLEPlayerViewController(videoLab: videoLab)
//            controller.player = AVPlayer(playerItem: playerItem)
//            
//            if let synchronizedLayer = self?.makeSynchronizedLayer(playerItem: playerItem, videoLab: videoLab) {
//                controller.view.layer.addSublayer(synchronizedLayer)
//            }
            let captureVC = CaptureFrameViewController()
            self?.onPush?(captureVC)
        }
        
        addObserverFromNotification()
    }
    
    func presentVideoPicker() {
        if #available(iOS 14.0, *) {
            var config = PHPickerConfiguration()
            config.selectionLimit = 1
            config.filter = .videos

            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self.present(picker, animated: true)
        } else {
            // Fallback on earlier versions
        }
        
    }

    func loadVideoToVideoLab(from url: URL) {
        let asset = AVAsset(url: url)
        let source = AVAssetSource(asset: asset)
        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        source.selectedTimeRange = timeRange
        let renderLayer = RenderLayer(timeRange: timeRange, source: source)
        
        let composition = RenderComposition()
        composition.renderSize = CGSize(width: 1280, height: 720)
        composition.layers = [renderLayer]
        
        let videoLab = VideoLab(renderComposition: composition)
        let playerItem = videoLab.makePlayerItem()
        playerItem.seekingWaitsForVideoCompositionRendering = true
        let controller = VLEPlayerViewController(videoLab: videoLab)
        controller.player = AVPlayer(playerItem: playerItem)
        if let synchronizedLayer = self.makeSynchronizedLayer(playerItem: playerItem, videoLab: videoLab) {
            controller.view.layer.addSublayer(synchronizedLayer)
        }
        
        self.onPush?(controller)
    }
    
    func makeSynchronizedLayer(playerItem: AVPlayerItem, videoLab: VideoLab) -> CALayer? {
        guard let animationLayer = videoLab.renderComposition.animationLayer else {
            return nil
        }

        let synchronizedLayer = AVSynchronizedLayer(playerItem: playerItem)
        synchronizedLayer.addSublayer(animationLayer)
        synchronizedLayer.zPosition = 999
        let videoSize = videoLab.renderComposition.renderSize
        synchronizedLayer.frame = CGRect(origin: CGPoint.zero, size: videoSize)
        
        let screenSize = UIScreen.main.bounds.size
        let videoRect = AVMakeRect(aspectRatio: videoSize, insideRect: CGRect(origin: CGPoint.zero, size: screenSize))
        synchronizedLayer.position = CGPoint(x: videoRect.midX, y: videoRect.midY)
        let scale = fminf(Float(screenSize.width / videoSize.width), Float(screenSize.height / videoSize.height))
        synchronizedLayer.setAffineTransform(CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale)))
        return synchronizedLayer
    }
    
    func addObserverFromNotification() {
        let name1 = Notification.Name.init(rawValue: VLEConstants.VLETImeLineShowDragSortViewNotification)
        NotificationCenter.default.addObserver(self, selector: #selector(showDragSortViewAction), name: name1, object: nil)
        let name2 = Notification.Name.init(rawValue: VLEConstants.VLETimeLineRemoveDragSortViewNotification)
        NotificationCenter.default.addObserver(self, selector: #selector(removeDragSortViewAction), name: name2, object: nil)
    }
    
    @objc func showDragSortViewAction() {
        self.view.isHidden = true
    }
    
    @objc func removeDragSortViewAction() {
        self.view.isHidden = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension VLEEffectViewController: PHPickerViewControllerDelegate {
    @available(iOS 14.0, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first,
              result.itemProvider.hasItemConformingToTypeIdentifier("public.movie") else { return }

        result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, error in
            guard let url = url else { return }

            // ✅ Copy file vào thư mục tạm
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: tempURL)

            DispatchQueue.main.async {
                self.loadVideoToVideoLab(from: tempURL)
            }
        }
    }
}
