//
//  VLEPickerViewController.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/7/21.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import UIKit
import PKHUD
import VideoLab
import CoreMedia
import Photos

enum VLEPickerItemType {
    case album
    case sticker
    case audio
}

class VLEPickerViewController: UIViewController {
    
    let itemType: VLEPickerItemType
    lazy var bottomView: VLEPickerBottomView = makeBottomView()
    lazy var audioListView: VLEPickerAudioListView = makeAudioListView()
    lazy var navigatorView: VLEPickerNavigatorView = makeNavigatorView()
    lazy var albumListView: VLEPickerAlbumListView = makeAlbumListView()
    lazy var albumListModel: VLEPickerAlbumListModel = makeAlbumListModel()
    lazy var audioListModel: VLEPickerAudioListModel = makeAudioListModel()
    lazy var stickerListView: VLEPickerStickerListView = makeStickerListView()
    lazy var albumSwitchView: VLEPickerAlbumSwitchView = makeAlbumSwitchView()
    lazy var stickerListModel: VLEPickerStickerListModel = makeStickerListModel()
   
    init(type: VLEPickerItemType) {
        self.itemType = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("")
    }

    override func viewDidLoad() {
        setupView()
    }

    private func setupView() {
        self.view.backgroundColor = UIColor.init(hexString: "#212123")
        self.view.addSubview(navigatorView)
        navigatorView.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalTo(self.view.snp.top)
        }

        switch itemType {
        case .album:
            setupAlbumView()
        case .audio:
            setupAudioView()
        case .sticker:
            setupStickerView()
        }
        handlePickerViewEvent()
    }

    func setupStickerView() {
        self.view.addSubview(stickerListView)
        stickerListView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalTo(navigatorView.snp.bottom).offset(0)
            make.bottom.equalToSuperview()
        }
        handleStickerListViewEvent()
    }
    
    func setupAudioView() {
        self.view.addSubview(audioListView)
        audioListView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalTo(navigatorView.snp.bottom).offset(0)
            make.bottom.equalToSuperview()
        }
        handleAudioListViewEvent()
    }
    
    func setupAlbumView() {
        self.view.addSubview(bottomView)
        self.view.addSubview(albumSwitchView)
        self.view.addSubview(albumListView)
        bottomView.snp.makeConstraints { make in
            make.height.equalTo(70)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.snp.bottom).offset(0)
        }
        albumSwitchView.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalTo(navigatorView.snp.bottom)
        }
        albumListView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalTo(albumSwitchView.snp.bottom).offset(0)
            make.bottom.equalTo(bottomView.snp.top).offset(0)
        }
        loadAsset()
        handleAlbumViewEvent()
    }

    func loadAsset() {
        guard albumListModel.models.isEmpty else {
            return
        }
        DispatchQueue.global().async {
            self.albumListModel.refetchPhotos()
            DispatchQueue.main.async {
                self.albumListView.pushModel(model: self.albumListModel.models)
                self.albumListView.reload()
            }
        }
    }
    
    func handleAlbumViewEvent() {
        bottomView.clickAddButtonBlock = { [weak self] in
            guard let self = self else { return }
            let array = self.albumListView.pullAssetDataForSelected()
            if array.isEmpty {
                HUD.show(.label("未选择资源，请选择！"))
                HUD.hide(afterDelay: 0.5)
                return
            }

            let queue = DispatchQueue.global(qos: .background)
            let semaphore = DispatchSemaphore.init(value: 1)
            var sourceArray: [VLETimeLineItemModel] = []
            for item in array {
                switch item.type {
                case .video:
                    queue.async {
                        semaphore.wait()
                        let source = PHAssetVideoSource.init(phAsset: item.asset)
                    source.load { error in
                            if error == nil {
                                source.selectedTimeRange = CMTimeRange.init(start: CMTime.zero, duration: source.duration)
                                let itemModel = VLETimeLineItemModel.init(with: source, type: .video)
                                sourceArray.append(itemModel)
                                if sourceArray.count == array.count {
                                    DispatchQueue.main.async {
                                        self.dismiss(animated: true) {
                                            VLEMainConcreteMediator.shared.addAssetToRenderTrackWith(itemModelArray: sourceArray)
                                        }
                                    }
                                }
                            }
                            semaphore.signal()
                        }
                    }
                case .image, .livePhoto:
                    queue.async {
                        semaphore.wait()
                        let source = PHAssetImageSource.init(phAsset: item.asset)
                        source.load { error in
                            if error == nil {
                                let itemModel = VLETimeLineItemModel.init(with: source, type: .image)
                                sourceArray.append(itemModel)
                                if sourceArray.count == array.count {
                                    DispatchQueue.main.async {
                                        self.dismiss(animated: true) {
                                            VLEMainConcreteMediator.shared.addAssetToRenderTrackWith(itemModelArray: sourceArray)
                                        }
                                    }
                                }
                            }
                            semaphore.signal()
                        }
                    }
                default:
                        continue
                }
            }
        }

        bottomView.clickPreViewButtonBlock = {
            HUD.show(.label("Not yet available"))
            HUD.hide(afterDelay: 0.5)
        }
        albumSwitchView.clickLocalAlbumButtonBlock = {}
        albumSwitchView.clickOnlineMaterialButtonBlock = {
            HUD.show(.label("Not yet available"))
            HUD.hide(afterDelay: 0.5)
        }
    }

    func handlePickerViewEvent() {
        navigatorView.clickCloseButtonBlock = { [weak self] in
            self?.dismiss(animated: true)
        }
        navigatorView.clickSetButtonBlock = {
            HUD.show(.label("Not yet available"))
            HUD.hide(afterDelay: 0.5)
        }
    }

    func handleStickerListViewEvent() {
        stickerListView.selectedStickerBlock = { [weak self] image in
            self?.dismiss(animated: true)
            let source = ImageSource.init(cgImage: image.cgImage)
            VLEMainConcreteMediator.shared.addStickerToSeparateTrackWith(source: source)
        }
    }

    func handleAudioListViewEvent() {
        audioListView.selectedAudioBlock = { [weak self] model in
            guard let self = self else { return }
            
            // ✅ Show audio options dialog before adding
            self.showAudioOptionsDialog(for: model)
        }
    }
    
    private func showAudioOptionsDialog(for audioModel: VLEPickerAudioItemModel) {
        let alertController = UIAlertController(
            title: "🎵 Audio Options",
            message: "How would you like to add this audio?",
            preferredStyle: .actionSheet
        )
        
        // ✅ Option 1: Mix with video audio
        alertController.addAction(
            UIAlertAction(title: "🎤 Mix with Video Audio", style: .default) { _ in
                self.addAudioWithMixing(audioModel: audioModel, replaceVideoAudio: false)
            }
        )
        
        // ✅ Option 2: Replace video audio (mute original)
        alertController.addAction(
            UIAlertAction(title: "🔇 Replace Video Audio", style: .default) { _ in
                self.addAudioWithMixing(audioModel: audioModel, replaceVideoAudio: true)
            }
        )
        
        // ✅ Option 3: Cancel
        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        
        // ✅ iPad support
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        self.present(alertController, animated: true)
    }
    
    
    private func addAudioWithMixing(audioModel: VLEPickerAudioItemModel, replaceVideoAudio: Bool) {
        self.dismiss(animated: true) {
            let source = AVAssetSource(asset: audioModel.asset)
            
            // ✅ Add audio track to timeline
            VLEMainConcreteMediator.shared.addAudioToSeparateTrackWith(source: source)
            
            // ✅ Handle video audio muting if requested
            if replaceVideoAudio {
                VLEMainConcreteMediator.shared.muteVideoAudio()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    HUD.show(.label("🔇 Video audio muted, new audio added"))
                    HUD.hide(afterDelay: 2.0)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    HUD.show(.label("🎤 Audio mixed with video"))
                    HUD.hide(afterDelay: 2.0)
                }
            }
        }
    }
}

extension VLEMainConcreteMediator {
    
    func muteVideoAudio() {
            guard let timelineVC = timelineViewController else {
                print("❌ Cannot access timeline for audio muting")
                return
            }
            
            print("🔇 === MUTING VIDEO AUDIO ===")
            timelineVC.stateModel.isVideoAudioMuted = true
            
            // ✅ Rebuild với video audio muted
            refreshAudioMixing()
            
            print("✅ Video audio muted, added audio still playing")
        }
        
        func unmuteVideoAudio() {
            guard let timelineVC = timelineViewController else {
                print("❌ Cannot access timeline for audio unmuting")
                return
            }
            
            print("🔊 === UNMUTING VIDEO AUDIO ===")
            timelineVC.stateModel.isVideoAudioMuted = false
            
            // ✅ Rebuild với balanced mixing
            refreshAudioMixing()
            
            print("✅ Video audio unmuted, both audios now playing")
        }
    
    func refreshAudioMixing() {
            guard let timelineVC = timelineViewController,
                  let playbackVC = playbackViewController else {
                return
            }
            
            // ✅ Rebuild VideoLab với proper audio balance
            let videoLab = timelineVC.buildVideolab()
            playbackVC.previewItem(with: videoLab)
        }
    }
    
    

extension VLEPickerViewController {
    private func makeBottomView() -> VLEPickerBottomView {
        let bottomView = VLEPickerBottomView.init()
        return bottomView
    }

    private func makeNavigatorView() -> VLEPickerNavigatorView {
        let navView = VLEPickerNavigatorView.init()
        return navView
    }

    private func makeAlbumListView() -> VLEPickerAlbumListView {
        let albumlistView = VLEPickerAlbumListView.init()
        return albumlistView
    }

    private func makeAlbumSwitchView() -> VLEPickerAlbumSwitchView {
        let switchView = VLEPickerAlbumSwitchView.init()
        return switchView
    }
    
    private func makeAudioListView() -> VLEPickerAudioListView {
        let view = VLEPickerAudioListView.init(model: self.audioListModel)
        return view
    }
    
    private func makeAudioListModel() -> VLEPickerAudioListModel {
        let model = VLEPickerAudioListModel.init()
        return model
    }
    
    private func makeStickerListView() -> VLEPickerStickerListView {
        let view = VLEPickerStickerListView.init(model: self.stickerListModel)
        return view
    }
    
    private func makeStickerListModel() -> VLEPickerStickerListModel {
        let model = VLEPickerStickerListModel.init()
        return model
    }
    
    private func makeAlbumListModel() -> VLEPickerAlbumListModel {
        guard let model = VLEPickerFetchAssetManager.fetchAlbums() else {
            fatalError("Không tìm thấy album Camera Roll. Đảm bảo quyền truy cập ảnh đã được cấp.")
        }
        return model
    }
}

extension RenderLayer {
    private static var userDataKey: UInt8 = 0
    
    var userData: Any? {
        get {
            return objc_getAssociatedObject(self, &RenderLayer.userDataKey)
        }
        set {
            objc_setAssociatedObject(self, &RenderLayer.userDataKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
