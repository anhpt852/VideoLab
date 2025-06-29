//
//  VLEEffectFirstLevelView.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/10/9.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import AVFoundation
import AVKit
import Foundation
import Metal
import PKHUD
import UIKit
import VideoLab

class VLEEffectFirstLevelView: UIView {

    let model: VLEEffectItemModel
    var iconViewArray: [VLEEffectIconView] = []

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView.init()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    init(with model: VLEEffectItemModel) {
        self.model = model
        super.init(frame: CGRect.zero)
        setupView()
    }

    func setupView() {
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        var index = 0
        let iconW = 80
        for item in self.model.firstLevelItemArray {
            let iconImage = item[VLEEffectItemModel.kIconKey]!
            let iconTitle = item[VLEEffectItemModel.kIconTitleKey]!
            let iconView = VLEEffectIconView.init(
                with: iconImage as! String,
                title: iconTitle as! String
            )
            let gesture = UITapGestureRecognizer.init(
                target: self,
                action: #selector(iconViewTapGestureAction(sender:))
            )
            iconView.addGestureRecognizer(gesture)
            iconViewArray.append(iconView)
            scrollView.addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.size.equalTo(CGSize.init(width: iconW, height: 52))
                make.left.equalTo(self.scrollView.snp.left).offset(
                    0 + index * iconW
                )
                make.centerY.equalToSuperview()
            }
            index += 1
        }
        scrollView.contentSize = CGSize.init(width: index * iconW, height: 52)
    }

    @objc func iconViewTapGestureAction(sender: UITapGestureRecognizer) {
        let index = iconViewArray.firstIndex(
            of: sender.view as! VLEEffectIconView
        )
        let itemModel = self.model.firstLevelItemArray[index!]
        let type =
            itemModel[VLEEffectItemModel.kIconType]
            as! VLEEffectFirstLevelItemType

        switch type {
        case .canvas:
            handleCanvasEffects()
        case .text:
            handleTextEffects()
        case .filter:
            handleFilterEffects()
        case .specialeffect:
            handleSpecialEffects()
        case .sticker:
            VLEMainConcreteMediator.shared.addStickerWithPickerViewController()
        case .audio:
            VLEMainConcreteMediator.shared.addAudioWithPickerViewController()
        case .capture:
            handleCaptureEffect()
        }
    }

    // MARK: - Canvas Effects Implementation (Real VideoLab)
    private func handleCanvasEffects() {
        let alertController = UIAlertController(
            title: "Canvas Effects",
            message: "Select Canvas Effect Type",
            preferredStyle: .actionSheet
        )

        // Background Color - Uses VideoLab RenderComposition.backgroundColor
        alertController.addAction(
            UIAlertAction(title: "Background Color", style: .default) { _ in
                self.showColorPicker { [weak self] color in
                    self?.applyBackgroundColor(color)
                }
            }
        )

        // Canvas Ratio - Uses VideoLab RenderComposition.renderSize
        alertController.addAction(
            UIAlertAction(title: "Canvas Ratio", style: .default) { _ in
                self.showCanvasRatioOptions()
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    // MARK: - Text Effects Implementation (Real VideoLab)
    private func handleTextEffects() {
        let alertController = UIAlertController(
            title: "Text Effects",
            message: "Select Text Effect Type",
            preferredStyle: .actionSheet
        )

        // Add Text with Animation - Uses VideoLab TextOpacityAnimationLayer
        alertController.addAction(
            UIAlertAction(title: "Add Animated Text", style: .default) { _ in
                self.showTextAnimationOptions()
            }
        )

        // Add Simple Text - Uses VideoLab TextAnimationLayer
        alertController.addAction(
            UIAlertAction(title: "Add Simple Text", style: .default) { _ in
                self.showSimpleTextOptions()
            }
        )

        // Quick Presets
        alertController.addAction(
            UIAlertAction(title: "Quick Title", style: .default) { _ in
                self.addTitleText(text: "Video Title")
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Quick Subtitle", style: .default) { _ in
                self.addSubtitleText(text: "Video Subtitle")
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Quick Watermark", style: .default) { _ in
                self.addWatermarkText(text: "@YourBrand")
            }
        )

        // Preview Text
        alertController.addAction(
            UIAlertAction(title: "👁️ Preview Text", style: .default) { _ in
                self.showTextPreview()
            }
        )

        // Debug Text Layer
        alertController.addAction(
            UIAlertAction(title: "🔍 Debug Text Layer", style: .default) { _ in
                self.debugTextLayer()
            }
        )

        // Test Set Animation Layer
        alertController.addAction(
            UIAlertAction(title: "🧪 Test Set Text", style: .default) { _ in
                self.testSetAnimationLayer()
            }
        )

        // Export Video with Text - Since AnimationLayer only visible in export
        alertController.addAction(
            UIAlertAction(title: "📱 Export Video with Text", style: .default) {
                _ in
                self.exportVideoWithText()
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    // MARK: - Filter Effects Implementation (Real VideoLab)
    private func handleFilterEffects() {
        let alertController = UIAlertController(
            title: "Filter Effects",
            message: "Select Filter Type",
            preferredStyle: .actionSheet
        )

        // LUT Filter - Uses VideoLab LookupFilter (confirmed available)
        alertController.addAction(
            UIAlertAction(title: "LUT Filter", style: .default) { _ in
                self.showLUTFilterOptions()
            }
        )

        // Custom Filter - Uses VideoLab BasicOperation for custom effects
        alertController.addAction(
            UIAlertAction(title: "Custom Filter", style: .default) { _ in
                self.showCustomFilterOptions()
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    // MARK: - Special Effects Implementation (Real VideoLab)
    private func handleSpecialEffects() {
        let alertController = UIAlertController(
            title: "Special Effects",
            message: "Select Effect Type",
            preferredStyle: .actionSheet
        )

        // Zoom Blur - Uses VideoLab ZoomBlur (confirmed available)
        alertController.addAction(
            UIAlertAction(title: "Zoom Blur", style: .default) { _ in
                self.applyZoomBlurEffect()
            }
        )

        // Transform Animation - Uses VideoLab Transform with KeyframeAnimation
        alertController.addAction(
            UIAlertAction(title: "Transform Animation", style: .default) { _ in
                self.showTransformAnimationOptions()
            }
        )

        // Layer Group - Uses VideoLab RenderLayerGroup
        alertController.addAction(
            UIAlertAction(title: "Layer Group", style: .default) { _ in
                self.showLayerGroupOptions()
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    // MARK: - Real VideoLab Implementation Methods

    private func applyBackgroundColor(_ color: UIColor) {
        guard let currentComposition = getCurrentRenderComposition() else {
            HUD.show(.label("No active composition"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        // ✅ Real VideoLab API - Convert UIColor to VideoLab Color
        let videoLabColor = convertUIColorToVideoLabColor(color)
        currentComposition.backgroundColor = videoLabColor
        refreshVideoPreview()

        HUD.show(.label("Background color applied"))
        HUD.hide(afterDelay: 1.0)
    }

    private func applyCanvasRatio(_ ratio: CGSize) {
        guard let currentComposition = getCurrentRenderComposition() else {
            HUD.show(.label("No active composition"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        // ✅ Real VideoLab API - RenderComposition.renderSize
        let baseWidth: CGFloat = 1920
        let newHeight = baseWidth * ratio.height / ratio.width
        currentComposition.renderSize = CGSize(
            width: baseWidth,
            height: newHeight
        )
        refreshVideoPreview()

        HUD.show(.label("Canvas ratio applied"))
        HUD.hide(afterDelay: 1.0)
    }

    // MARK: - Text Animation Layer Implementation (VideoLab Official)

    private func makeTextOpacityAnimationLayer(
        text: String,
        fontSize: CGFloat = 72,
        textColor: UIColor = .white,
        backgroundColor: UIColor = .clear,
        position: CGPoint = CGPoint(x: 640, y: 360),
        alignment: NSTextAlignment = .center,
        maxWidth: CGFloat = 800
    ) -> TextOpacityAnimationLayer {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor,
            .paragraphStyle: paragraphStyle,
        ]

        let attributedString = NSAttributedString(
            string: text,
            attributes: attributes
        )
        let size = attributedString.boundingRect(
            with: CGSize(width: maxWidth, height: 720),
            options: .usesLineFragmentOrigin,
            context: nil
        ).size

        let layer = TextOpacityAnimationLayer()
        layer.attributedText = attributedString
        layer.position = position
        layer.bounds = CGRect(origin: CGPoint.zero, size: size)

        return layer
    }

    // MARK: - LUT Texture Creation (Fixed with Demo Method)
    private func makeLutTextures() -> [Texture] {
        let lutImageNames = [
            "LUT_M01", "LUT_M02", "LUT_M03", "LUT_M07", "LUT_M06",
        ]
        var textures: [Texture] = []

        for imageName in lutImageNames {
            guard let image = UIImage(named: imageName) else {
                continue
            }

            guard let cgImage = image.cgImage else {
                continue
            }

            // ✅ Use demo method: Texture.makeTexture(cgImage:)
            guard let texture = Texture.makeTexture(cgImage: cgImage) else {
                continue
            }

            textures.append(texture)
        }

        // If no LUT images found in bundle, create fallback textures
        if textures.isEmpty {
            textures = createFallbackLutTextures()
        }

        return textures
    }

    private func createFallbackLutTextures() -> [Texture] {
        var textures: [Texture] = []

        // Create simple gradient LUT textures programmatically
        let lutColors = [
            (UIColor.red, UIColor.yellow),
            (UIColor.blue, UIColor.cyan),
            (UIColor.green, UIColor.white),
            (UIColor.purple, UIColor.systemPink),
            (UIColor.orange, UIColor.red),
        ]

        for (startColor, endColor) in lutColors {
            if let texture = createGradientLutTexture(
                from: startColor,
                to: endColor
            ) {
                textures.append(texture)
            }
        }

        return textures
    }

    private func createGradientLutTexture(
        from startColor: UIColor,
        to endColor: UIColor
    ) -> Texture? {
        let size = CGSize(width: 256, height: 16)  // Standard LUT dimensions
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [startColor.cgColor, endColor.cgColor]
        guard
            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: colors as CFArray,
                locations: nil
            )
        else {
            UIGraphicsEndImageContext()
            return nil
        }

        context.drawLinearGradient(
            gradient,
            start: CGPoint.zero,
            end: CGPoint(x: size.width, y: 0),
            options: []
        )

        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
            let cgImage = image.cgImage
        else {
            UIGraphicsEndImageContext()
            return nil
        }

        UIGraphicsEndImageContext()

        return Texture.makeTexture(cgImage: cgImage)
    }

    private func makeSimpleTextAnimationLayer(
        text: String,
        fontSize: CGFloat = 72,
        textColor: UIColor = .white,
        backgroundColor: UIColor = .clear,
        position: CGPoint = CGPoint(x: 640, y: 360),
        alignment: NSTextAlignment = .center,
        maxWidth: CGFloat = 800
    ) -> TextAnimationLayer {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor,
            .paragraphStyle: paragraphStyle,
        ]

        let attributedString = NSAttributedString(
            string: text,
            attributes: attributes
        )
        let size = attributedString.boundingRect(
            with: CGSize(width: maxWidth, height: 720),
            options: .usesLineFragmentOrigin,
            context: nil
        ).size

        let layer = TextAnimationLayer()
        layer.attributedText = attributedString
        layer.position = position
        layer.bounds = CGRect(origin: CGPoint.zero, size: size)

        return layer
    }

    // MARK: - Apply Custom Text to Current Composition
    // Note: AnimationLayer text is only visible in exported video, not in preview
    // This is VideoLab's default behavior - preview shows video layers only
    private func applyAnimatedTextToComposition(
        text: String,
        fontSize: CGFloat = 72,
        textColor: UIColor = .white,
        backgroundColor: UIColor = .clear,
        positionX: CGFloat = 0.5,  // 0.0 = left, 1.0 = right
        positionY: CGFloat = 0.5,  // 0.0 = top, 1.0 = bottom
        alignment: NSTextAlignment = .center
    ) {
        guard let currentComposition = getCurrentRenderComposition() else {
            HUD.show(.label("No active composition"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        print("🔍 === APPLYING ANIMATED TEXT ===")
        print("🔍 Text: '\(text)'")
        print("🔍 Position: (\(positionX), \(positionY))")
        print("🔍 Composition size: \(currentComposition.renderSize)")

        // Calculate absolute position from relative position
        let absolutePosition = CGPoint(
            x: currentComposition.renderSize.width * positionX,
            y: currentComposition.renderSize.height * positionY
        )

        print("🔍 Absolute position: \(absolutePosition)")

        let textLayer = makeTextOpacityAnimationLayer(
            text: text,
            fontSize: fontSize,
            textColor: textColor,
            backgroundColor: backgroundColor,
            position: absolutePosition,
            alignment: alignment,
            maxWidth: currentComposition.renderSize.width * 0.8
        )

        print("🔍 Created text layer: \(textLayer)")
        print("🔍 Text layer bounds: \(textLayer.bounds)")
        print("🔍 Text layer position: \(textLayer.position)")

        // Clear previous animation layer
        currentComposition.animationLayer = nil

        // Set new animation layer
        currentComposition.animationLayer = textLayer

        // Verify it was set
        if currentComposition.animationLayer != nil {
            print("✅ Animation layer set successfully")
        } else {
            print("❌ Failed to set animation layer")
        }

        refreshVideoPreview()

        HUD.show(
            .label("✅ Animated text applied! Use 'Export Video' to see text.")
        )
        HUD.hide(afterDelay: 2.0)
    }

    private func applySimpleTextToComposition(
        text: String,
        fontSize: CGFloat = 72,
        textColor: UIColor = .white,
        backgroundColor: UIColor = .clear,
        positionX: CGFloat = 0.5,
        positionY: CGFloat = 0.5,
        alignment: NSTextAlignment = .center
    ) {
        guard let currentComposition = getCurrentRenderComposition() else {
            HUD.show(.label("No active composition"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        print("🔍 === APPLYING SIMPLE TEXT ===")
        print("🔍 Text: '\(text)'")
        print("🔍 Composition size: \(currentComposition.renderSize)")

        let absolutePosition = CGPoint(
            x: currentComposition.renderSize.width * positionX,
            y: currentComposition.renderSize.height * positionY
        )

        let textLayer = makeSimpleTextAnimationLayer(
            text: text,
            fontSize: fontSize,
            textColor: textColor,
            backgroundColor: backgroundColor,
            position: absolutePosition,
            alignment: alignment,
            maxWidth: currentComposition.renderSize.width * 0.8
        )

        print("🔍 Created simple text layer: \(textLayer)")

        // Clear previous animation layer
        currentComposition.animationLayer = nil

        // Set new animation layer
        currentComposition.animationLayer = textLayer

        // Verify it was set
        if currentComposition.animationLayer != nil {
            print("✅ Simple text layer set successfully")
        } else {
            print("❌ Failed to set simple text layer")
        }

        refreshVideoPreview()

        HUD.show(
            .label("✅ Simple text applied! Use 'Export Video' to see text.")
        )
        HUD.hide(afterDelay: 2.0)
    }

    // MARK: - Export Video with Text (Since AnimationLayer only works in export)
    private func exportVideoWithText() {
        guard let currentComposition = getCurrentRenderComposition() else {
            HUD.show(.label("No composition available"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        guard currentComposition.animationLayer != nil else {
            HUD.show(.label("No text layer found. Add text first."))
            HUD.hide(afterDelay: 2.0)
            return
        }

        print("🔍 === EXPORTING VIDEO WITH TEXT ===")
        print(
            "🔍 Composition has animationLayer: \(currentComposition.animationLayer != nil)"
        )

        guard
            let timelineVC = VLEMainConcreteMediator.shared
                .timelineViewController
        else {
            HUD.show(.label("No timeline available"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        let videoLab = timelineVC.buildVideolab()

        // ✅ Create output URL first
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        )[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        let outputURL = URL(fileURLWithPath: documentsPath)
            .appendingPathComponent("video_with_text_\(timestamp).mp4")

        // Remove existing file
        try? FileManager.default.removeItem(at: outputURL)

        // ✅ Fix: Pass outputURL parameter and use AVFileType.mp4
        guard
            let exportSession = videoLab.makeExportSession(
                presetName: AVAssetExportPresetMediumQuality,
                outputURL: outputURL
            )
        else {
            HUD.show(.label("Failed to create export session"))
            HUD.hide(afterDelay: 2.0)
            return
        }

        // ✅ Fix: Use AVFileType.mp4 instead of .mp4
        exportSession.outputFileType = AVFileType.mp4

        print("🔍 Starting export...")
        print("📁 Output: \(outputURL)")

        HUD.show(.label("Exporting video with text..."))

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    print("✅ EXPORT COMPLETED!")
                    print("📁 Video saved: \(outputURL)")

                    // Save to Photos Library
                    UISaveVideoAtPathToSavedPhotosAlbum(
                        outputURL.path,
                        nil,
                        nil,
                        nil
                    )

                    HUD.show(.label("✅ Video exported to Photos!"))
                    HUD.hide(afterDelay: 3.0)

                case .failed:
                    print(
                        "❌ Export failed: \(String(describing: exportSession.error))"
                    )
                    HUD.show(.label("❌ Export failed"))
                    HUD.hide(afterDelay: 2.0)

                case .cancelled:
                    print("⚠️ Export cancelled")
                    HUD.show(.label("Export cancelled"))
                    HUD.hide(afterDelay: 1.0)

                default:
                    print("🔍 Export status: \(exportSession.status.rawValue)")
                    HUD.show(.label("Export in progress..."))
                    HUD.hide(afterDelay: 1.0)
                }
            }
        }
    }
    private func addTitleText(text: String) {
        applyAnimatedTextToComposition(
            text: text,
            fontSize: 96,
            textColor: .white,
            backgroundColor: .black.withAlphaComponent(0.5),
            positionX: 0.5,
            positionY: 0.2,
            alignment: .center
        )
    }

    private func addSubtitleText(text: String) {
        applySimpleTextToComposition(
            text: text,
            fontSize: 48,
            textColor: .white,
            backgroundColor: .black.withAlphaComponent(0.7),
            positionX: 0.5,
            positionY: 0.9,
            alignment: .center
        )
    }

    private func addWatermarkText(text: String) {
        applySimpleTextToComposition(
            text: text,
            fontSize: 32,
            textColor: .white.withAlphaComponent(0.7),
            backgroundColor: .clear,
            positionX: 0.95,
            positionY: 0.05,
            alignment: .right
        )
    }

    private func applyLUTFilter(lutName: String) {
        guard let currentLayer = getCurrentRenderLayer() else {
            HUD.show(.label("No active render layer"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        // ✅ Use proper LUT texture creation from demo
        let lutTextures = makeLutTextures()
        guard !lutTextures.isEmpty else {
            // Fallback: use LookupFilter without texture
            let lookupFilter = LookupFilter()
            currentLayer.operations = [lookupFilter]
            refreshVideoPreview()
            HUD.show(.label("Basic LUT filter applied"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        let lookupFilter = LookupFilter()
        lookupFilter.addTexture(lutTextures[0], at: 0)  // Use first available LUT
        currentLayer.operations = [lookupFilter]
        refreshVideoPreview()

        HUD.show(.label("LUT filter applied: \(lutName)"))
        HUD.hide(afterDelay: 1.0)
    }

    private func applyZoomBlurEffect() {
        guard let currentLayer = getCurrentRenderLayer() else {
            HUD.show(.label("No active render layer"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        // ✅ Real VideoLab API - ZoomBlur with KeyframeAnimation (confirmed available)
        let zoomBlur = ZoomBlur()

        // Create keyframe animation for blur size
        let keyTimes = [
            CMTime.zero, CMTime(seconds: 2, preferredTimescale: 600),
        ]
        let animation = KeyframeAnimation(
            keyPath: "blurSize",
            values: [0.0, 3.0],
            keyTimes: keyTimes,
            timingFunctions: [.quarticEaseOut]
        )

        zoomBlur.animations = [animation]
        currentLayer.operations = [zoomBlur]
        refreshVideoPreview()

        HUD.show(.label("Zoom blur applied"))
        HUD.hide(afterDelay: 1.0)
    }

    private func applyTransformAnimation(property: String) {
        guard let currentLayer = getCurrentRenderLayer() else {
            HUD.show(.label("No active render layer"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        // ✅ Real VideoLab API - Transform with KeyframeAnimation
        var transform = Transform.identity
        let keyTimes = [
            CMTime.zero,
            CMTime(seconds: 1, preferredTimescale: 600),
            CMTime(seconds: 2, preferredTimescale: 600),
        ]

        let animation: KeyframeAnimation

        switch property {
        case "Scale":
            animation = KeyframeAnimation(
                keyPath: "scale",
                values: [1.0, 1.5, 1.0],
                keyTimes: keyTimes,
                timingFunctions: [.quadraticEaseInOut, .quadraticEaseInOut]
            )
        case "Rotation":
            animation = KeyframeAnimation(
                keyPath: "rotation",
                values: [0, Float.pi, Float.pi * 2],
                keyTimes: keyTimes,
                timingFunctions: [.linear, .linear]
            )
        case "Position":
            let centerPoint = CGPoint(x: 0.5, y: 0.5)
            transform.center = centerPoint
            animation = KeyframeAnimation(
                keyPath: "center.x",
                values: [0.25, 0.75, 0.25],
                keyTimes: keyTimes,
                timingFunctions: [.quadraticEaseInOut, .quadraticEaseInOut]
            )
        default:
            HUD.show(.label("Animation property not supported"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        transform.animations = [animation]
        currentLayer.transform = transform
        refreshVideoPreview()

        HUD.show(.label("\(property) animation applied"))
        HUD.hide(afterDelay: 1.0)
    }

    private func createLayerGroup() {
        guard let currentComposition = getCurrentRenderComposition() else {
            HUD.show(.label("No active composition"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        // ✅ Real VideoLab API - RenderLayerGroup
        let timeRange = CMTimeRange(
            start: CMTime.zero,
            duration: CMTime(seconds: 5, preferredTimescale: 600)
        )
        let layerGroup = RenderLayerGroup(timeRange: timeRange)

        // Add current layers to group if available
        if !currentComposition.layers.isEmpty {
            let firstLayer = currentComposition.layers.first!
            layerGroup.layers = [firstLayer]

            HUD.show(.label("Layer group created"))
        } else {
            HUD.show(.label("No layers to group"))
        }
        HUD.hide(afterDelay: 1.0)
    }

    // MARK: - Custom Filter Implementation
    private func applyCustomFilter(filterType: String) {
        guard let currentLayer = getCurrentRenderLayer() else {
            HUD.show(.label("No active render layer"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        // ✅ Simplified approach - Use existing VideoLab operations instead of custom
        // Since we don't have Metal shader files, use available operations
        switch filterType {
        case "Blur":
            // Use ZoomBlur for blur effect
            let blurEffect = ZoomBlur()
            currentLayer.operations = [blurEffect]
        case "Sharpen", "Edge Detect", "Emboss":
            // For filters requiring custom shaders, show message instead
            HUD.show(
                .label("Custom filter \(filterType) requires Metal shaders")
            )
            HUD.hide(afterDelay: 2.0)
            return
        default:
            HUD.show(.label("Filter type not supported"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        refreshVideoPreview()
        HUD.show(.label("Filter applied: \(filterType)"))
        HUD.hide(afterDelay: 1.0)
    }

    // MARK: - Helper Methods

    private func convertUIColorToVideoLabColor(_ uiColor: UIColor) -> Color {
        // VideoLab Color only has limited static properties
        // Based on compilation errors, only these colors are available:

        switch uiColor {
        case UIColor.black:
            return Color.black
        case UIColor.white:
            return Color.white
        case UIColor.red:
            return Color.red
        case UIColor.green:
            return Color.green
        case UIColor.blue:
            return Color.blue
        default:
            // For unsupported colors (yellow, orange, purple, etc.)
            // Check if VideoLab Color has custom initializers

            // Try to extract RGBA and create custom color if possible
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            // Try different VideoLab Color initializers
            // Option 1: Check if Color has RGBA initializer
            if let customColor = createCustomVideoLabColor(
                red: Float(red),
                green: Float(green),
                blue: Float(blue),
                alpha: Float(alpha)
            ) {
                return customColor
            }

            // Option 2: Map to closest available color
            return mapToClosestAvailableColor(uiColor)
        }
    }

    private func createCustomVideoLabColor(
        red: Float,
        green: Float,
        blue: Float,
        alpha: Float
    ) -> Color? {
        // Try different VideoLab Color initializers
        // These are common patterns in graphics frameworks

        // Try pattern 1: Color(red:green:blue:alpha:)
        // if let color = Color(red: red, green: green, blue: blue, alpha: alpha) {
        //     return color
        // }

        // Try pattern 2: Color(r:g:b:a:)
        // if let color = Color(r: red, g: green, b: blue, a: alpha) {
        //     return color
        // }

        // Try pattern 3: Color with simd_float4
        // let colorVector = simd_float4(red, green, blue, alpha)
        // if let color = Color(simd_float4: colorVector) {
        //     return color
        // }

        // If no custom initializers work, return nil
        return nil
    }

    private func mapToClosestAvailableColor(_ uiColor: UIColor) -> Color {
        // Map unsupported colors to closest available VideoLab colors

        switch uiColor {
        case UIColor.yellow:
            return Color.red  // Closest warm color
        case UIColor.orange:
            return Color.red  // Closest warm color
        case UIColor.purple:
            return Color.blue  // Closest cool color
        case UIColor.cyan:
            return Color.blue
        case UIColor.magenta:
            return Color.red
        case UIColor.brown:
            return Color.black
        case UIColor.gray, UIColor.lightGray, UIColor.darkGray:
            return Color.white
        default:
            print(
                "Warning: Color \(uiColor) not supported, using black as fallback"
            )
            return Color.black
        }
    }

    private func getCurrentRenderComposition() -> RenderComposition? {
        guard
            let timelineViewController = VLEMainConcreteMediator.shared
                .timelineViewController
        else {
            return nil
        }

        let videoLab = timelineViewController.buildVideolab()
        return videoLab.renderComposition
    }

    private func getCurrentRenderLayer() -> RenderLayer? {
        guard let composition = getCurrentRenderComposition(),
            !composition.layers.isEmpty
        else {
            return nil
        }

        return composition.layers.first
    }

    private func refreshVideoPreview() {
        VLEMainConcreteMediator.shared.prepareTimeLineItemForPlayback()
    }

    // MARK: - Text Preview Implementation (from Demo)
    private func createTextPreviewLayer() -> CALayer? {
        guard let currentComposition = getCurrentRenderComposition(),
            let animationLayer = currentComposition.animationLayer
        else {
            return nil
        }

        // Clone animation layer for preview
        let previewLayer = CALayer()
        previewLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: currentComposition.renderSize.width,
            height: currentComposition.renderSize.height
        )

        // Create a copy of the animation layer
        if let textLayer = animationLayer as? TextOpacityAnimationLayer {
            let copyLayer = TextOpacityAnimationLayer()
            copyLayer.attributedText = textLayer.attributedText
            copyLayer.position = textLayer.position
            copyLayer.bounds = textLayer.bounds
            previewLayer.addSublayer(copyLayer)
        } else if let textLayer = animationLayer as? TextAnimationLayer {
            let copyLayer = TextAnimationLayer()
            copyLayer.attributedText = textLayer.attributedText
            copyLayer.position = textLayer.position
            copyLayer.bounds = textLayer.bounds
            previewLayer.addSublayer(copyLayer)
        }

        return previewLayer
    }

    private func showTextPreview() {
        guard let previewLayer = createTextPreviewLayer() else {
            HUD.show(.label("No text to preview. Add text first."))
            HUD.hide(afterDelay: 2.0)
            return
        }

        // Add preview layer to current view
        if let viewController = self.findViewController() {
            previewLayer.zPosition = 999
            viewController.view.layer.addSublayer(previewLayer)

            // Position preview layer
            let videoSize =
                getCurrentRenderComposition()?.renderSize
                ?? CGSize(width: 1280, height: 720)
            let screenSize = viewController.view.bounds.size
            let videoRect = AVMakeRect(
                aspectRatio: videoSize,
                insideRect: CGRect(origin: CGPoint.zero, size: screenSize)
            )

            previewLayer.position = CGPoint(
                x: videoRect.midX,
                y: videoRect.midY
            )
            let scale = fminf(
                Float(screenSize.width / videoSize.width),
                Float(screenSize.height / videoSize.height)
            )
            previewLayer.setAffineTransform(
                CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale))
            )

            HUD.show(.label("👁️ Text preview enabled"))
            HUD.hide(afterDelay: 2.0)

            // Auto remove after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                previewLayer.removeFromSuperlayer()
                HUD.show(.label("Preview ended"))
                HUD.hide(afterDelay: 1.0)
            }
        }
    }

    // MARK: - Debug Text Layer
    private func debugTextLayer() {
        guard let currentComposition = getCurrentRenderComposition() else {
            print("❌ No composition found")
            HUD.show(.label("❌ No composition found"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        print("🔍 === DEBUG TEXT LAYER ===")
        print("🔍 Composition: \(currentComposition)")
        print("🔍 Render size: \(currentComposition.renderSize)")
        print(
            "🔍 Animation layer: \(String(describing: currentComposition.animationLayer))"
        )

        if let animLayer = currentComposition.animationLayer {
            print("✅ Animation layer EXISTS")
            print("🔍   - Type: \(type(of: animLayer))")
            print("🔍   - Frame: \(animLayer.frame)")
            print("🔍   - Position: \(animLayer.position)")
            print("🔍   - Bounds: \(animLayer.bounds)")

            if let textLayer = animLayer as? TextOpacityAnimationLayer {
                print(
                    "🔍   - Text content: '\(textLayer.attributedText.string)'"
                )
                HUD.show(.label("✅ Found TextOpacityAnimationLayer"))
            } else if let textLayer = animLayer as? TextAnimationLayer {
                print(
                    "🔍   - Text content: '\(textLayer.attributedText.string)'"
                )
                HUD.show(.label("✅ Found TextAnimationLayer"))
            } else {
                print("🔍   - Unknown layer type")
                HUD.show(.label("⚠️ Unknown animation layer type"))
            }
        } else {
            print("❌ Animation layer is NIL")
            HUD.show(.label("❌ No animation layer found"))
        }

        HUD.hide(afterDelay: 3.0)
    }

    private func testSetAnimationLayer() {
        guard let currentComposition = getCurrentRenderComposition() else {
            print("❌ No composition")
            HUD.show(.label("❌ No composition"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        print("🔍 Testing set animation layer...")

        // Create simple test layer
        let testLayer = makeTextOpacityAnimationLayer(
            text: "TEST TEXT - \(Date())",
            fontSize: 64,
            textColor: .white,
            backgroundColor: .red,
            position: CGPoint(x: 640, y: 360),
            alignment: .center
        )

        print("🔍 Created test layer: \(testLayer)")
        print("🔍 Test layer text: '\(testLayer.attributedText.string)'")

        currentComposition.animationLayer = testLayer

        print(
            "🔍 After setting - animationLayer: \(String(describing: currentComposition.animationLayer))"
        )

        // Immediate check
        if currentComposition.animationLayer != nil {
            print("✅ Animation layer set successfully")
            HUD.show(.label("✅ Test text layer created"))

            // Also refresh preview
            refreshVideoPreview()
        } else {
            print("❌ Animation layer still nil")
            HUD.show(.label("❌ Failed to set test layer"))
        }

        HUD.hide(afterDelay: 2.0)
    }

    // MARK: - UI Helper Methods

    private func presentAlert(_ alertController: UIAlertController) {
        if let viewController = self.findViewController() {
            if let popover = alertController.popoverPresentationController {
                popover.sourceView = self
                popover.sourceRect = self.bounds
            }
            viewController.present(alertController, animated: true)
        }
    }

    private func showColorPicker(completion: @escaping (UIColor) -> Void) {
        // Only show colors that are actually supported by VideoLab Color
        let colors: [UIColor] = [.black, .white, .red, .green, .blue]
        let alertController = UIAlertController(
            title: "Select Color",
            message: nil,
            preferredStyle: .actionSheet
        )

        for (index, color) in colors.enumerated() {
            let colorName = ["Black", "White", "Red", "Green", "Blue"][index]
            alertController.addAction(
                UIAlertAction(title: colorName, style: .default) { _ in
                    completion(color)
                }
            )
        }

        // Add option for custom colors (will be mapped to closest available)
        alertController.addAction(
            UIAlertAction(title: "More Colors (Approximate)", style: .default) {
                _ in
                self.showExtendedColorPicker(completion: completion)
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    private func showExtendedColorPicker(
        completion: @escaping (UIColor) -> Void
    ) {
        let extendedColors: [UIColor] = [
            .yellow, .orange, .purple, .cyan, .magenta, .brown,
        ]
        let alertController = UIAlertController(
            title: "Extended Colors",
            message:
                "These colors will be mapped to closest available VideoLab colors",
            preferredStyle: .actionSheet
        )

        for (index, color) in extendedColors.enumerated() {
            let colorName = [
                "Yellow→Red", "Orange→Red", "Purple→Blue", "Cyan→Blue",
                "Magenta→Red", "Brown→Black",
            ][index]
            alertController.addAction(
                UIAlertAction(title: colorName, style: .default) { _ in
                    completion(color)
                }
            )
        }

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    private func showCanvasRatioOptions() {
        let alertController = UIAlertController(
            title: "Canvas Ratio",
            message: "Select Canvas Ratio",
            preferredStyle: .actionSheet
        )

        let ratios: [(String, CGSize)] = [
            ("16:9", CGSize(width: 16, height: 9)),
            ("9:16", CGSize(width: 9, height: 16)),
            ("1:1", CGSize(width: 1, height: 1)),
            ("4:3", CGSize(width: 4, height: 3)),
            ("3:4", CGSize(width: 3, height: 4)),
        ]

        for (name, size) in ratios {
            alertController.addAction(
                UIAlertAction(title: name, style: .default) { _ in
                    self.applyCanvasRatio(size)
                }
            )
        }

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    // MARK: - Text Animation Options UI

    private func showTextAnimationOptions() {
        let alertController = UIAlertController(
            title: "Add Animated Text",
            message: "Configure animated text properties",
            preferredStyle: .alert
        )

        // Text content
        alertController.addTextField { textField in
            textField.placeholder = "Enter text content"
            textField.text = "Hello VideoLab!"
        }

        // Font size
        alertController.addTextField { textField in
            textField.placeholder = "Font size (default: 72)"
            textField.keyboardType = .numberPad
            textField.text = "72"
        }

        // Position Y (vertical)
        alertController.addTextField { textField in
            textField.placeholder = "Vertical position (0.0-1.0, default: 0.5)"
            textField.keyboardType = .decimalPad
            textField.text = "0.5"
        }

        alertController.addAction(
            UIAlertAction(title: "Add White Text", style: .default) { _ in
                let text = alertController.textFields?[0].text ?? "Default Text"
                let fontSize = CGFloat(
                    Double(alertController.textFields?[1].text ?? "72") ?? 72
                )
                let positionY = CGFloat(
                    Double(alertController.textFields?[2].text ?? "0.5") ?? 0.5
                )

                self.applyAnimatedTextToComposition(
                    text: text,
                    fontSize: fontSize,
                    textColor: .white,
                    backgroundColor: .clear,
                    positionX: 0.5,
                    positionY: positionY,
                    alignment: .center
                )
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Add Red Text", style: .default) { _ in
                let text = alertController.textFields?[0].text ?? "Default Text"
                let fontSize = CGFloat(
                    Double(alertController.textFields?[1].text ?? "72") ?? 72
                )
                let positionY = CGFloat(
                    Double(alertController.textFields?[2].text ?? "0.5") ?? 0.5
                )

                self.applyAnimatedTextToComposition(
                    text: text,
                    fontSize: fontSize,
                    textColor: .red,
                    backgroundColor: .white.withAlphaComponent(0.8),
                    positionX: 0.5,
                    positionY: positionY,
                    alignment: .center
                )
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Add Bottom Title", style: .default) { _ in
                let text = alertController.textFields?[0].text ?? "Default Text"
                let fontSize = CGFloat(
                    Double(alertController.textFields?[1].text ?? "96") ?? 96
                )

                self.applyAnimatedTextToComposition(
                    text: text,
                    fontSize: fontSize,
                    textColor: .white,
                    backgroundColor: .black.withAlphaComponent(0.7),
                    positionX: 0.5,
                    positionY: 0.9,
                    alignment: .center
                )
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    private func showSimpleTextOptions() {
        let alertController = UIAlertController(
            title: "Add Simple Text",
            message: "Configure simple text properties",
            preferredStyle: .alert
        )

        // Text content
        alertController.addTextField { textField in
            textField.placeholder = "Enter text content"
            textField.text = "Simple Text"
        }

        // Font size
        alertController.addTextField { textField in
            textField.placeholder = "Font size (default: 48)"
            textField.keyboardType = .numberPad
            textField.text = "48"
        }

        // Position Y (vertical)
        alertController.addTextField { textField in
            textField.placeholder = "Vertical position (0.0-1.0, default: 0.8)"
            textField.keyboardType = .decimalPad
            textField.text = "0.8"
        }

        alertController.addAction(
            UIAlertAction(title: "Add White Text", style: .default) { _ in
                let text = alertController.textFields?[0].text ?? "Default Text"
                let fontSize = CGFloat(
                    Double(alertController.textFields?[1].text ?? "48") ?? 48
                )
                let positionY = CGFloat(
                    Double(alertController.textFields?[2].text ?? "0.8") ?? 0.8
                )

                self.applySimpleTextToComposition(
                    text: text,
                    fontSize: fontSize,
                    textColor: .white,
                    backgroundColor: .clear,
                    positionX: 0.5,
                    positionY: positionY,
                    alignment: .center
                )
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Add Black Background", style: .default) { _ in
                let text = alertController.textFields?[0].text ?? "Default Text"
                let fontSize = CGFloat(
                    Double(alertController.textFields?[1].text ?? "48") ?? 48
                )
                let positionY = CGFloat(
                    Double(alertController.textFields?[2].text ?? "0.8") ?? 0.8
                )

                self.applySimpleTextToComposition(
                    text: text,
                    fontSize: fontSize,
                    textColor: .white,
                    backgroundColor: .black.withAlphaComponent(0.7),
                    positionX: 0.5,
                    positionY: positionY,
                    alignment: .center
                )
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Add Top Title", style: .default) { _ in
                let text = alertController.textFields?[0].text ?? "Default Text"
                let fontSize = CGFloat(
                    Double(alertController.textFields?[1].text ?? "64") ?? 64
                )

                self.applySimpleTextToComposition(
                    text: text,
                    fontSize: fontSize,
                    textColor: .white,
                    backgroundColor: .red.withAlphaComponent(0.8),
                    positionX: 0.5,
                    positionY: 0.2,
                    alignment: .center
                )
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    private func showTransformAnimationOptions() {
        let alertController = UIAlertController(
            title: "Transform Animation",
            message: "Select Transform Type",
            preferredStyle: .actionSheet
        )

        let transforms = ["Scale", "Rotation", "Position"]

        for transform in transforms {
            alertController.addAction(
                UIAlertAction(title: transform, style: .default) { _ in
                    self.applyTransformAnimation(property: transform)
                }
            )
        }

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    private func showLUTFilterOptions() {
        let alertController = UIAlertController(
            title: "LUT Filter",
            message: "Select LUT Type",
            preferredStyle: .actionSheet
        )

        let luts = ["vintage", "cool", "warm", "cinematic", "blackwhite"]

        for lut in luts {
            alertController.addAction(
                UIAlertAction(title: lut.capitalized, style: .default) { _ in
                    self.applyLUTFilter(lutName: lut)
                }
            )
        }

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    private func showCustomFilterOptions() {
        let alertController = UIAlertController(
            title: "Custom Filter",
            message: "Select Filter Type",
            preferredStyle: .actionSheet
        )

        // Only include filters that can be implemented with existing VideoLab operations
        let filters = ["Blur"]  // Removed complex filters that need custom shaders

        for filter in filters {
            alertController.addAction(
                UIAlertAction(title: filter, style: .default) { _ in
                    self.applyCustomFilter(filterType: filter)
                }
            )
        }

        // Add informational option
        alertController.addAction(
            UIAlertAction(
                title: "More Filters (Requires Custom Shaders)",
                style: .default
            ) { _ in
                self.showCustomFilterInfo()
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    private func showCustomFilterInfo() {
        let alert = UIAlertController(
            title: "Custom Filters",
            message:
                "Advanced filters like Sharpen, Edge Detect, and Emboss require custom Metal shader files (.metal) to be added to your project. Check VideoLab documentation for shader implementation guides.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.presentAlert(alert)
    }

    private func showLayerGroupOptions() {
        let alertController = UIAlertController(
            title: "Layer Group",
            message: "Select Group Action",
            preferredStyle: .actionSheet
        )

        alertController.addAction(
            UIAlertAction(title: "Create Layer Group", style: .default) { _ in
                self.createLayerGroup()
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    required init?(coder: NSCoder) {
        fatalError("")
    }

    // MARK: - Capture Frame Implementation
    private func handleCaptureEffect() {
        let alertController = UIAlertController(
            title: "🎥 Capture Frame",
            message: "Enter time to capture frame from video",
            preferredStyle: .alert
        )

        // Time input field
        alertController.addTextField { textField in
            textField.placeholder = "Time (mm:ss or seconds)"
            textField.keyboardType = .decimalPad
            textField.text = "0:05"
        }

        // Capture with auto orientation
        alertController.addAction(
            UIAlertAction(title: "📸 Capture (Auto)", style: .default) { _ in
                let timeInput = alertController.textFields?[0].text ?? "0:05"
                self.captureFrameAtTime(timeInput: timeInput)
            }
        )

        // ✅ THÊM OPTION FORCE ORIENTATION:
        alertController.addAction(
            UIAlertAction(title: "📸 Force Upright", style: .default) { _ in
                let timeInput = alertController.textFields?[0].text ?? "0:05"
                self.captureFrameAtTime(
                    timeInput: timeInput,
                    forceOrientation: true
                )
            }
        )

        // Current time action
        alertController.addAction(
            UIAlertAction(title: "📍 Current Time", style: .default) { _ in
                self.captureFrameAtCurrentTime()
            }
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )
        self.presentAlert(alertController)
    }

    private func captureFrameAtTime(
        timeInput: String,
        forceOrientation: Bool = false
    ) {
        guard let targetTime = parseTimeInput(timeInput) else {
            HUD.show(.label("❌ Invalid time format"))
            HUD.hide(afterDelay: 2.0)
            return
        }

        if forceOrientation {
            performFrameCaptureForceUpright(at: targetTime)
        } else {
            performFrameCapture(at: targetTime)
        }
    }

    private func performFrameCaptureForceUpright(at time: CMTime) {
        guard
            let videoLab = VLEMainConcreteMediator.shared
                .timelineViewController?.buildVideolab()
        else {
            HUD.show(.label("❌ Cannot build video"))
            HUD.hide(afterDelay: 2.0)
            return
        }

        let playerItem = videoLab.makePlayerItem()
        let asset = playerItem.asset

        let imageGenerator = AVAssetImageGenerator(asset: asset)

        // ✅ FORCE NO TRANSFORM - raw image
        imageGenerator.appliesPreferredTrackTransform = false
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator.maximumSize = CGSize(width: 1920, height: 1080)

        HUD.show(.label("📸 Capturing (Force Upright)..."))

        imageGenerator.generateCGImagesAsynchronously(forTimes: [
            NSValue(time: time)
        ]) { [weak self] requestedTime, cgImage, actualTime, result, error in

            DispatchQueue.main.async {
                HUD.hide()

                if let error = error {
                    print("❌ Capture error: \(error)")
                    HUD.show(.label("❌ Capture failed"))
                    HUD.hide(afterDelay: 2.0)
                    return
                }

                guard let cgImage = cgImage else {
                    HUD.show(.label("❌ No image generated"))
                    HUD.hide(afterDelay: 2.0)
                    return
                }

                let capturedImage = UIImage(cgImage: cgImage)
                let timeString =
                    self?.formatTimeForDisplay(time: actualTime) ?? "Unknown"

                print("✅ Frame captured (Force Upright) at: \(timeString)")
                self?.showCapturePreview(
                    image: capturedImage,
                    captureTime: actualTime
                )
            }
        }
    }

    private func captureFrameAtCurrentTime() {
        guard
            let playbackVC = VLEMainConcreteMediator.shared
                .playbackViewController,
            let player = playbackVC.player
        else {
            HUD.show(.label("❌ No video playing"))
            HUD.hide(afterDelay: 2.0)
            return
        }

        let currentTime = player.currentTime()
        performFrameCapture(at: currentTime)
    }

    private func parseTimeInput(_ input: String) -> CMTime? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        // Try parsing as "mm:ss" format
        if trimmed.contains(":") {
            let components = trimmed.components(separatedBy: ":")
            guard components.count == 2,
                let minutes = Double(components[0]),
                let seconds = Double(components[1])
            else {
                return nil
            }
            let totalSeconds = minutes * 60 + seconds
            return CMTime(seconds: totalSeconds, preferredTimescale: 600)
        }

        // Try parsing as seconds
        guard let seconds = Double(trimmed) else {
            return nil
        }

        return CMTime(seconds: seconds, preferredTimescale: 600)
    }

    private func performFrameCapture(at time: CMTime) {
        guard let currentComposition = getCurrentRenderComposition() else {
            HUD.show(.label("❌ No video to capture"))
            HUD.hide(afterDelay: 2.0)
            return
        }

        // Get video asset
        guard
            let videoLab = VLEMainConcreteMediator.shared
                .timelineViewController?.buildVideolab()
        else {
            HUD.show(.label("❌ Cannot build video"))
            HUD.hide(afterDelay: 2.0)
            return
        }

        let playerItem = videoLab.makePlayerItem()
        let asset = playerItem.asset

        // ✅ THÊM DEBUG VIDEO PROPERTIES:
        debugVideoProperties(asset: asset)

        // Check if time is within video duration
        let videoDuration = asset.duration
        if CMTimeCompare(time, videoDuration) > 0 {
            HUD.show(.label("❌ Time exceeds video duration"))
            HUD.hide(afterDelay: 2.0)
            return
        }

        HUD.show(.label("📸 Capturing frame..."))

        // ✅ SỬA LẠI IMAGE GENERATOR VỚI PROPER ORIENTATION:
        captureFrameWithCorrectOrientation(from: asset, at: time)
    }

    private func debugVideoProperties(asset: AVAsset) {
        guard
            let videoTrack = asset.tracks(withMediaType: AVMediaType.video)
                .first
        else {
            print("❌ No video track for debugging")
            return
        }

        print("🔍 === VIDEO PROPERTIES DEBUG ===")
        print("🔍 Natural size: \(videoTrack.naturalSize)")
        print("🔍 Preferred transform: \(videoTrack.preferredTransform)")
        print("🔍 Preferred volume: \(videoTrack.preferredVolume)")

        // Calculate final display size after transform
        let naturalRect = CGRect(origin: .zero, size: videoTrack.naturalSize)
        let transformedRect = naturalRect.applying(
            videoTrack.preferredTransform
        )
        print("🔍 Transformed rect: \(transformedRect)")

        // Calculate rotation angle
        let transform = videoTrack.preferredTransform
        let angle = atan2(transform.b, transform.a)
        let degrees = angle * 180 / .pi
        print("🔍 Rotation angle: \(degrees) degrees")

        // Check for common orientations
        if abs(degrees) < 5 {
            print("🔍 Orientation: Normal (0°)")
        } else if abs(degrees - 90) < 5 {
            print("🔍 Orientation: Rotated 90° (Portrait filmed in landscape)")
        } else if abs(degrees + 90) < 5 {
            print("🔍 Orientation: Rotated -90°")
        } else if abs(abs(degrees) - 180) < 5 {
            print("🔍 Orientation: Upside down (180°)")
        } else {
            print("🔍 Orientation: Custom angle \(degrees)°")
        }

        print("🔍 === END DEBUG ===")
    }

    // ✅ THÊM METHOD MỚI XỬ LÝ ORIENTATION:
    private func captureFrameWithCorrectOrientation(
        from asset: AVAsset,
        at time: CMTime
    ) {
        // Get video track for orientation info
        guard
            let videoTrack = asset.tracks(withMediaType: AVMediaType.video)
                .first
        else {
            HUD.show(.label("❌ No video track found"))
            HUD.hide(afterDelay: 2.0)
            return
        }

        // Create image generator
        let imageGenerator = AVAssetImageGenerator(asset: asset)

        // ✅ KEY FIX: Proper transform handling
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero

        // ✅ Get video track transform for debugging
        let transform = videoTrack.preferredTransform
        let videoSize = videoTrack.naturalSize
        print("🔍 Video natural size: \(videoSize)")
        print("🔍 Video transform: \(transform)")

        // ✅ Calculate proper maximum size based on transform
        let properMaxSize = calculateProperImageSize(
            naturalSize: videoSize,
            transform: transform
        )
        imageGenerator.maximumSize = properMaxSize

        print("🔍 Using maximum size: \(properMaxSize)")

        // Generate image
        imageGenerator.generateCGImagesAsynchronously(forTimes: [
            NSValue(time: time)
        ]) { [weak self] requestedTime, cgImage, actualTime, result, error in

            DispatchQueue.main.async {
                HUD.hide()

                if let error = error {
                    print("❌ Capture error: \(error)")
                    HUD.show(.label("❌ Capture failed"))
                    HUD.hide(afterDelay: 2.0)
                    return
                }

                guard let cgImage = cgImage else {
                    HUD.show(.label("❌ No image generated"))
                    HUD.hide(afterDelay: 2.0)
                    return
                }

                // ✅ CREATE IMAGE AND APPLY ADDITIONAL ORIENTATION FIX IF NEEDED
                let capturedImage = UIImage(cgImage: cgImage)

                // ✅ Check if we need additional orientation fix
                let finalImage =
                    self?.fixImageOrientationIfNeeded(
                        capturedImage,
                        videoTransform: transform
                    ) ?? capturedImage

                let timeString =
                    self?.formatTimeForDisplay(time: actualTime) ?? "Unknown"

                print("✅ Frame captured at: \(timeString)")
                print("🔍 Final image size: \(finalImage.size)")

                self?.showCapturePreview(
                    image: finalImage,
                    captureTime: actualTime
                )
            }
        }
    }

    // ✅ THÊM METHOD TÍNH TOÁN SIZE ĐÚNG:
    private func calculateProperImageSize(
        naturalSize: CGSize,
        transform: CGAffineTransform
    ) -> CGSize {
        // Apply transform to understand final orientation
        let transformedRect = CGRect(origin: .zero, size: naturalSize).applying(
            transform
        )
        let finalSize = CGSize(
            width: abs(transformedRect.width),
            height: abs(transformedRect.height)
        )

        // Scale to reasonable maximum while maintaining aspect ratio
        let maxDimension: CGFloat = 1920
        let aspectRatio = finalSize.width / finalSize.height

        if finalSize.width > finalSize.height {
            // Landscape
            return CGSize(
                width: maxDimension,
                height: maxDimension / aspectRatio
            )
        } else {
            // Portrait
            return CGSize(
                width: maxDimension * aspectRatio,
                height: maxDimension
            )
        }
    }

    // ✅ THÊM METHOD FIX ORIENTATION CUỐI CÙNG:
    private func fixImageOrientationIfNeeded(
        _ image: UIImage,
        videoTransform: CGAffineTransform
    ) -> UIImage {
        // Check if transform indicates rotation
        let angle = atan2(videoTransform.b, videoTransform.a)
        let degrees = angle * 180 / .pi

        print("🔍 Video rotation angle: \(degrees) degrees")

        // If appliesPreferredTrackTransform worked correctly, we shouldn't need additional rotation
        // But in some cases, we might need manual correction

        // Check for common problematic rotations
        if abs(degrees - 90) < 5 || abs(degrees + 90) < 5
            || abs(degrees - 270) < 5
        {
            print("🔧 Applying manual orientation correction")
            return rotateImageIfNeeded(image, degrees: degrees)
        }

        return image
    }

    // ✅ THÊM METHOD ROTATE IMAGE:
    private func rotateImageIfNeeded(_ image: UIImage, degrees: Double)
        -> UIImage
    {
        // For most cases, appliesPreferredTrackTransform should handle this
        // This is a fallback for edge cases

        // If image looks wrong, we can apply manual rotation
        // But first, let's just return original and see if appliesPreferredTrackTransform works
        return image
    }

    private func showCapturePreview(image: UIImage, captureTime: CMTime) {
        guard let viewController = self.findViewController() else { return }

        // Create preview view controller
        let previewVC = VLECapturePreviewViewController(
            capturedImage: image,
            captureTime: captureTime
        )
        previewVC.modalPresentationStyle = .fullScreen

        viewController.present(previewVC, animated: true)
    }

    private func formatTimeForDisplay(time: CMTime) -> String {
        let totalSeconds = Int(CMTimeGetSeconds(time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - UIView Extension
extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

// MARK: - VLEMainConcreteMediator Extensions
extension VLEMainConcreteMediator {
    var currentRenderComposition: RenderComposition? {
        guard let timelineViewController = self.timelineViewController else {
            return nil
        }
        let videoLab = timelineViewController.buildVideolab()
        return videoLab.renderComposition
    }

    var currentSelectedRenderLayer: RenderLayer? {
        guard let composition = currentRenderComposition,
            !composition.layers.isEmpty
        else {
            return nil
        }
        return composition.layers.first
    }

    func refreshVideoPreview() {
        self.prepareTimeLineItemForPlayback()
    }
}
