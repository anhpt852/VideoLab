//
//  VLEExportViewController.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/9/22.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import UIKit
import Photos
import PKHUD

class VLEExportViewController: UIViewController {

    var exportSession: AVAssetExportSession?
    lazy var saveView = makeSaveView()
    lazy var shareView = makeShareView()
    lazy var navigatorView = makeNavigatorView()
    lazy var configResolutionView = makeConfigResolutionView()
    lazy var configFrameDurationView = makeConfigFrameDurationView()
    
    override func viewDidLoad() {
        setupView()
        handleSubviewClickEvent()
    }

    func setupView() {
        self.view.backgroundColor = UIColor.init(hexString: "#212123")
        self.view.addSubview(navigatorView)
        navigatorView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        let backScrollView = UIScrollView.init()
        backScrollView.showsVerticalScrollIndicator = true
        backScrollView.showsHorizontalScrollIndicator = true
        backScrollView.isScrollEnabled = true
        self.view.addSubview(backScrollView)
        backScrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigatorView.snp.bottom)
        }
        backScrollView.addSubview(saveView)
        saveView.snp.makeConstraints { make in
            make.top.width.left.equalToSuperview()
            make.height.equalTo(100)
        }
        backScrollView.addSubview(configResolutionView)
        configResolutionView.snp.makeConstraints { make in
            make.left.width.equalToSuperview()
            make.top.equalTo(saveView.snp.bottom)
            make.height.equalTo(166)
        }
        backScrollView.addSubview(configFrameDurationView)
        configFrameDurationView.snp.makeConstraints { make in
            make.left.width.equalToSuperview()
            make.top.equalTo(configResolutionView.snp.bottom)
            make.height.equalTo(165)
        }
        backScrollView.addSubview(shareView)
        shareView.snp.makeConstraints { make in
            make.left.width.equalToSuperview()
            make.top.equalTo(configFrameDurationView.snp.bottom)
            make.height.equalTo(109)
        }
        shareView.isHidden = true
        let height = 100 + 166 + 165 + 109
        backScrollView.contentSize = CGSize.init(width: self.view.bounds.width, height: CGFloat(height))
    }

    func handleSubviewClickEvent() {
        navigatorView.clickCloseButtonBlock = { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
    }
}

extension VLEExportViewController: VLEExportSaveViewDelegate {
    func exportSaveViewClickSaveButton(_ button: UIButton) {
        self.requestLibraryAuthorization { [weak self] (_) in
            guard let self = self else { return }
            self.exportVideo()
        }
    }
}

extension VLEExportViewController {

    func exportVideo() {
        print("🎬 === STARTING EXPORT PROCESS ===")
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Cannot access document directory")
            HUD.hide()
            HUD.show(.label("Cannot access document directory")) // was: "无法访问文档目录"
            HUD.hide(afterDelay: 2.0)
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let outputURL = documentDirectory.appendingPathComponent("exported_video_\(timestamp).mp4")
        
        // ✅ Cleanup existing file
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
                print("✅ Cleaned up existing file")
            } catch {
                print("⚠️ Could not remove existing file: \(error)")
            }
        }

        // ✅ Build VideoLab composition
        guard let videoLab = VLEMainConcreteMediator.shared.buildCurrentTimeLineItemToExport() else {
            print("❌ Cannot build VideoLab composition")
            HUD.hide()
            HUD.show(.label("Cannot build video composition")) // was: "无法构建视频组合"
            HUD.hide(afterDelay: 2.0)
            return
        }
        
        print("✅ VideoLab composition built successfully")
        
        // ✅ Debug composition
        let composition = videoLab.renderComposition
        print("🔍 Composition layers: \(composition.layers.count)")
        print("🔍 Render size: \(composition.renderSize)")
        print("🔍 Has animation layer: \(composition.animationLayer != nil)")
        
        // ✅ Check if composition is valid
        if composition.layers.isEmpty {
            print("❌ Empty composition - no layers to export")
            HUD.hide()
            HUD.show(.label("No content to export")) // was: "没有内容可导出"
            HUD.hide(afterDelay: 2.0)
            return
        }

        // ✅ Create export session
        self.exportSession = videoLab.makeExportSession(
            presetName: AVAssetExportPresetMediumQuality, // ← Use Medium instead of Highest for better compatibility
            outputURL: outputURL
        )
        
        guard let exportSession = self.exportSession else {
            print("❌ Cannot create export session")
            HUD.hide()
            HUD.show(.label("Cannot create export session")) // was: "无法创建导出会话"
            HUD.hide(afterDelay: 2.0)
            return
        }
        
        // ✅ Configure export session
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        print("🎬 Export session created")
        print("📁 Output URL: \(outputURL)")
        print("🎛️ Preset: \(exportSession.presetName)")
        
        // ✅ Show progress HUD
        HUD.show(.label("Exporting video...")) // was: "正在导出视频..."
        
        // ✅ Start export with timeout protection
        let exportStartTime = Date()
        
        exportSession.exportAsynchronously { [weak self] in
            guard let self = self else { return }
            
            let exportDuration = Date().timeIntervalSince(exportStartTime)
            print("⏱️ Export completed in \(exportDuration) seconds")
            
            DispatchQueue.main.async {
                HUD.hide()
                
                switch exportSession.status {
                case .completed:
                    print("✅ EXPORT SUCCESSFUL!")
                    print("📁 Final file: \(outputURL)")
                    
                    // ✅ Verify file exists and has content
                    if FileManager.default.fileExists(atPath: outputURL.path) {
                        do {
                            let fileSize = try FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64 ?? 0
                            print("📦 File size: \(fileSize) bytes")
                            
                            if fileSize > 0 {
                                // ✅ Save to Photos Library
                                self.saveToPhotosLibrary(outputURL) { success in
                                    if success {
                                        HUD.show(.label("✅ Export successful! Saved to Photos")) // was: "✅ 导出成功！已保存到相册"
                                        HUD.hide(afterDelay: 2.0) {_ in
                                            self.dismiss(animated: true)
                                        }
                                    } else {
                                        HUD.show(.label("⚠️ Export successful, but failed to save to Photos")) // was: "⚠️ 导出成功，但保存到相册失败"
                                        HUD.hide(afterDelay: 2.0)
                                    }
                                }
                            } else {
                                print("❌ Export file is empty")
                                HUD.show(.label("❌ Export file is empty")) // was: "❌ 导出文件为空"
                                HUD.hide(afterDelay: 2.0)
                            }
                        } catch {
                            print("❌ Cannot check file attributes: \(error)")
                            HUD.show(.label("❌ Cannot verify export file")) // was: "❌ 无法验证导出文件"
                            HUD.hide(afterDelay: 2.0)
                        }
                    } else {
                        print("❌ Export file does not exist")
                        HUD.show(.label("❌ Export file does not exist")) // was: "❌ 导出文件不存在"
                        HUD.hide(afterDelay: 2.0)
                    }
                    
                case .failed:
                    print("❌ EXPORT FAILED!")
                    if let error = exportSession.error {
                        print("❌ Export error: \(error.localizedDescription)")
                        print("❌ Error domain: \(error._domain)")
                        print("❌ Error code: \(error._code)")
                    }
                    HUD.show(.label("❌ Export failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")) // was: "❌ 导出失败: \(exportSession.error?.localizedDescription ?? "未知错误")"
                    HUD.hide(afterDelay: 3.0)
                    
                case .cancelled:
                    print("⚠️ EXPORT CANCELLED")
                    HUD.show(.label("⚠️ Export cancelled")) // was: "⚠️ 导出已取消"
                    HUD.hide(afterDelay: 1.0)
                    
                default:
                    print("🔍 Export status: \(exportSession.status.rawValue)")
                    HUD.show(.label("🔍 Unknown export status")) // was: "🔍 导出状态未知"
                    HUD.hide(afterDelay: 2.0)
                }
            }
        }
        
        // ✅ Add timeout protection (30 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if exportSession.status == .exporting {
                print("⏰ Export timeout - cancelling")
                exportSession.cancelExport()
                HUD.hide()
                HUD.show(.label("⏰ Export timeout")) // was: "⏰ 导出超时"
                HUD.hide(afterDelay: 2.0)
            }
        }
        
        print("🎬 === EXPORT PROCESS STARTED ===")
    }
    
    private func saveToPhotosLibrary(_ videoURL: URL, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { (saved, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Save to Photos failed: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ Video saved to Photos successfully")
                    completion(true)
                }
            }
        }
    }

    func requestLibraryAuthorization(_ handler: @escaping (PHAuthorizationStatus) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            handler(status)
        } else {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    handler(status)
                }
            }
        }
    }

    func saveFileToAlbum(_ fileURL: URL, handler: ((Bool, Error?) -> Void)? = nil) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { (saved, error) in
            if let handler = handler {
                handler(saved, error)
            }
        }
    }
}

extension VLEExportViewController {
    private func makeNavigatorView() -> VLEExportNavigatorView {
        let view = VLEExportNavigatorView.init()
        return view
    }

    private func makeShareView() -> VLEExportShareView {
        let view = VLEExportShareView.init()
        return view
    }
    
    private func makeConfigResolutionView() -> VLEExportConfigResolutionView {
        let view = VLEExportConfigResolutionView.init()
        return view
    }
    
    private func makeConfigFrameDurationView() -> VLEExportConfigFrameDurationView {
        let view = VLEExportConfigFrameDurationView.init()
        return view
    }
    
    private func makeSaveView() -> VLEExportSaveView {
        let view = VLEExportSaveView.init(delegate: self)
        return view
    }
}
