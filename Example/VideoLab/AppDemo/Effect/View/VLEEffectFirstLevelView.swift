//
//  VLEEffectFirstLevelView.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/10/9.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import UIKit
import PKHUD


class VLEEffectFirstLevelView: UIView {
    
    let model: VLEEffectItemModel
    var iconViewArray: [VLEEffectIconView] = []
    var onCanvasUpdated: ((CGSize, UIColor) -> Void)?
    var onSelectFeature: ((VLEEffectFirstLevelItemType) -> Void)?
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
            let iconView = VLEEffectIconView.init(with: iconImage as! String, title: iconTitle as! String)
            let gesture = UITapGestureRecognizer.init(target: self, action: #selector(iconViewTapGestureAction(sender:)))
            iconView.addGestureRecognizer(gesture)
            iconViewArray.append(iconView)
            scrollView.addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.size.equalTo(CGSize.init(width: iconW, height: 52))
                make.left.equalTo(self.scrollView.snp.left).offset(0 + index * iconW)
                make.centerY.equalToSuperview()
            }
            index += 1
        }
        scrollView.contentSize = CGSize.init(width: index * iconW, height: 52)
    }
    
    @objc func iconViewTapGestureAction(sender: UITapGestureRecognizer) {
        let index = iconViewArray.firstIndex(of: sender.view as! VLEEffectIconView)
        let itemModel = self.model.firstLevelItemArray[index!]
        let type = itemModel[VLEEffectItemModel.kIconType] as! VLEEffectFirstLevelItemType
        switch  type {
        case .text, .filter, .specialeffect:
            HUD.show(.label("暂未开放"))
            HUD.hide(afterDelay: 0.5)
        case .canvas:
            self.onSelectFeature?(.canvas)
        case .sticker:
            VLEMainConcreteMediator.shared.addStickerWithPickerViewController()
        case .audio:
            VLEMainConcreteMediator.shared.addAudioWithPickerViewController()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("")
    }
    
    func presentCanvasEditor() {
        guard let topVC = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        let alert = UIAlertController(title: "Canvas Settings", message: "Enter size and background color", preferredStyle: .alert)

        alert.addTextField { $0.placeholder = "Width (e.g. 1280)" }
        alert.addTextField { $0.placeholder = "Height (e.g. 720)" }

        let colors: [(String, UIColor)] = [
            ("Black", .black), ("White", .white), ("Transparent", .clear),
            ("Red", .red), ("Blue", .blue)
        ]

        for (name, color) in colors {
            alert.addAction(UIAlertAction(title: "Set \(name)", style: .default) { _ in
                self.applyCanvasSettings(from: alert.textFields ?? [], backgroundColor: color)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        topVC.present(alert, animated: true)
    }

    func applyCanvasSettings(from textFields: [UITextField], backgroundColor: UIColor) {
        guard let widthText = textFields[0].text,
              let heightText = textFields[1].text,
              let width = Int(widthText),
              let height = Int(heightText),
              width > 0, height > 0 else {
            HUD.show(.label("Invalid size"))
            HUD.hide(afterDelay: 1.0)
            return
        }

        let size = CGSize(width: width, height: height)

        
        self.onCanvasUpdated?(size, backgroundColor)

    }

}
