//
//  VLECapturePreviewViewController.swift
//  VideoLab_Example
//
//  Created by Your Name on Date
//  Copyright © 2023 Chocolate. All rights reserved.
//

import UIKit
import Photos
import PKHUD

class VLECapturePreviewViewController: UIViewController {
    
    let capturedImage: UIImage
    let captureTime: CMTime
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        return imageView
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✕", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("💾 Save to Gallery", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("📤 Share", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemGreen
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        return button
    }()
    
    init(capturedImage: UIImage, captureTime: CMTime) {
        self.capturedImage = capturedImage
        self.captureTime = captureTime
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        displayCapturedImage()
    }
    
    private func setupView() {
        view.backgroundColor = .black
        
        // Image view
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Close button
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.width.height.equalTo(40)
        }
        
        // Time label
        view.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(32)
            make.width.equalTo(100)
        }
        
        // Save button
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
            make.left.equalToSuperview().offset(30)
            make.right.equalTo(view.snp.centerX).offset(-10)
            make.height.equalTo(50)
        }
        
        // Share button
        view.addSubview(shareButton)
        shareButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
            make.left.equalTo(view.snp.centerX).offset(10)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(50)
        }
    }
    
    private func displayCapturedImage() {
        imageView.image = capturedImage
        
        let totalSeconds = Int(CMTimeGetSeconds(captureTime))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        requestPhotoLibraryPermission { [weak self] granted in
            if granted {
                self?.saveImageToGallery()
            } else {
                self?.showPermissionAlert()
            }
        }
    }
    
    @objc private func shareButtonTapped() {
        let activityVC = UIActivityViewController(activityItems: [capturedImage], applicationActivities: nil)
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    private func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized)
                }
            }
        default:
            completion(false)
        }
    }
    
    private func saveImageToGallery() {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: self.capturedImage)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    HUD.show(.label("✅ Saved to Gallery!"))
                    HUD.hide(afterDelay: 2.0)
                } else {
                    HUD.show(.label("❌ Save failed"))
                    HUD.hide(afterDelay: 2.0)
                    print("Save error: \(String(describing: error))")
                }
            }
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Permission Required",
            message: "Please allow access to Photos in Settings to save images.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
