//
//  VLETimeLineDragSortView.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/9/29.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import UIKit

protocol VLETimeLineDragSortViewDelegate: NSObjectProtocol {
    func timelineDargSortViewChangedSeparate(with selectedIndex: Int, dragPositionXRate: Float)
    func timeLineDargSortViewDeleteSegment(with selectedIndex: Int)
    func timeLineDargSortViewDidSort(with selectedIndex: Int, targetIndex: Int)
}

class VLETimeLineDragSortView: UIView {
    
    weak var delegate: VLETimeLineDragSortViewDelegate?
    var selectedIndex: Int
    var targetIndex: Int = Int.max
    var contentWidth: CGFloat = 0
    var itemMarginSpace: CGFloat = 10
    var itemHorizontalSpace: CGFloat = 10
    var itemVerticalSpace: CGFloat = 35
    var itemWidth: CGFloat = 60
    var itemImageArray: [UIImage] = []
    // ✅ ADD THIS PROPERTY
    private var selectedOverlayPosition: CGPoint?
    var isSelectedHeaderView: Bool = false {
        didSet {
            if oldValue != isSelectedHeaderView {
                if isSelectedHeaderView == true {
                    self.headerView.backgroundColor = UIColor.init(hexString: "#FFFFFF", alpha: 0.1)
                    self.headerLabel.textColor = UIColor.init(hexString: "#FFFFFF", alpha: 0.3)
                    let impactFeedbackGenerator = UIImpactFeedbackGenerator.init(style:UIImpactFeedbackGenerator.FeedbackStyle.heavy)
                    impactFeedbackGenerator.impactOccurred()
                } else {
                    self.headerView.backgroundColor = UIColor.init(hexString: "#FFFFFF", alpha: 0.2)
                    self.headerLabel.textColor = UIColor.init(hexString: "#FFFFFF", alpha: 1)
                }
            }
        }
    }
    var isSelectedFooterView: Bool = false {
        didSet {
            if oldValue != isSelectedFooterView {
                if isSelectedFooterView == true {
                    self.deleteButton.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
                    let impactFeedbackGenerator = UIImpactFeedbackGenerator.init(style: UIImpactFeedbackGenerator.FeedbackStyle.heavy)
                    impactFeedbackGenerator.impactOccurred()
                } else {
                    self.deleteButton.transform = CGAffineTransform.identity
                }
            }
        }
    }
    
    init(with itemArray: [UIImage], delegate: VLETimeLineDragSortViewDelegate, selectedIndex: Int) {
        self.selectedIndex = selectedIndex
        super.init(frame: CGRect.zero)
        self.targetIndex = self.selectedIndex
        self.itemImageArray.removeAll()
        self.delegate = delegate
        self.itemImageArray.append(contentsOf: itemArray)
        contentWidth = itemMarginSpace * 2 + (itemWidth + itemHorizontalSpace) * CGFloat(self.itemImageArray.count) - itemHorizontalSpace
        if contentWidth < UIScreen.main.bounds.width {
            contentWidth = UIScreen.main.bounds.width
        }
        setupView()
        dragSortGridView.selectedItemView(with: self.selectedIndex)
    }
    
    required init?(coder: NSCoder) {
        fatalError("")
    }
    
    func setupView() {
        self.backgroundColor = UIColor.init(hexString: "#212123")
        scrollView.contentSize = CGSize.init(width: contentWidth, height: 350)
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        scrollView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.width.equalTo(contentWidth)
            make.height.equalTo(65)
            make.left.top.equalToSuperview()
        }
        self.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(scrollView.snp.top).offset(22)
        }
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.width.equalTo(contentWidth)
            make.height.equalTo(150)
            make.top.equalTo(headerView.snp.bottom)
        }
        scrollView.addSubview(footerView)
        footerView.snp.makeConstraints { make in
            make.width.equalTo(contentWidth)
            make.height.equalTo(135)
            make.left.equalToSuperview()
            make.top.equalTo(stackView.snp.bottom)
        }
        self.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize.init(width: 65, height: 65))
            make.top.equalTo(footerView.snp.top).offset(0)
        }
        stackView.addArrangedSubview(dragSortGridView)
    }

    lazy var headerView: UIView = {
        let view = UIView.init()
        view.backgroundColor = UIColor.init(hexString: "#FFFFFF", alpha: 0.2)
        return view
    }()

    lazy var footerView: UIView = {
        let view = UIView.init()
        view.backgroundColor = UIColor.clear
        return view
    }()

    lazy var headerLabel: UILabel = {
        let label = UILabel.init()
        label.textColor = UIColor.init(hexString: "#FFFFFF")
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.text = "Drag here to convert to independent layer"
        return label
    }()

    lazy var deleteButton: UIButton = {
        let button = UIButton.init()
        button.setBackgroundImage(UIImage.init(named: "timeline_dragsort_delete"), for: UIControl.State.normal)
        return button
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView.init()
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.backgroundColor = UIColor.init(hexString: "#212123")
        return scrollView
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView.init()
        stackView.axis = .horizontal
        stackView.spacing = itemHorizontalSpace
        stackView.backgroundColor = UIColor.init(hexString: "#212123")
        return stackView
    }()

    lazy var dragSortGridView: VLETimeLineDragSortGridView = {
        let view = VLETimeLineDragSortGridView.init(subViews: createSubItemViews(), itemWidth: itemWidth, itemHeight: itemWidth, edgeInsets: UIEdgeInsets.init(top: itemVerticalSpace, left: itemHorizontalSpace, bottom: itemVerticalSpace, right: itemHorizontalSpace))
        view.updateSortedBlock = { (array: [VLETimeLineDragSortMoveItemView]) -> Void in
            var sortIndex = 0
            for item in array {
                if item.index == self.selectedIndex {
                    self.targetIndex = sortIndex
                }
                sortIndex+=1
            }
        }
        return view
    }()

    func createSubItemViews() -> [VLETimeLineDragSortMoveItemView] {
        var views: [VLETimeLineDragSortMoveItemView] = []
        var index = 0
        for item in itemImageArray {
            let view = VLETimeLineDragSortMoveItemView.init()
            view.backImageView.image = item
            view.index = index
            index+=1
            views.append(view)
        }
        return views
    }
}

extension VLETimeLineDragSortView {

    func beginSortView(with sender: UILongPressGestureRecognizer) {
        dragSortGridView.beginDragItemView(with: sender)
    }

    func moveSortView(with sender: UILongPressGestureRecognizer) {
        dragSortGridView.moveDragItemView(with: sender)
        let point = sender.location(in: dragSortGridView)
        if (point.y < 0) && (point.y > -65) {
            isSelectedHeaderView = true
            isSelectedFooterView = false
        } else if (point.y > 150) && (point.y < 285) {
            isSelectedHeaderView = false
            isSelectedFooterView = true
        } else {
            isSelectedHeaderView = false
            isSelectedFooterView = false
        }
    }

    // ✅ MODIFY EXISTING endSortView METHOD
    func endSortView(with sender: UILongPressGestureRecognizer) {
        dragSortGridView.endDragItemView(with: sender)
        
        if isSelectedHeaderView == true {
            // ✅ SHOW POSITION PICKER FIRST
            showOverlayPositionOptions { [weak self] selectedPosition in
                guard let self = self else { return }
                
                // ✅ STORE POSITION IN STATE MODEL BEFORE CALLING DELEGATE
                if let delegate = self.delegate as? VLETimeLineViewController {
                    delegate.stateModel.setPendingOverlayPosition(selectedPosition)
                }
                
                let point = sender.location(in: self.dragSortGridView)
                let rate = point.x / UIScreen.main.bounds.width
                
                // ✅ CALL ORIGINAL DELEGATE METHOD
                self.delegate?.timelineDargSortViewChangedSeparate(with: self.selectedIndex, dragPositionXRate: Float(rate))
            }
        } else if isSelectedFooterView == true {
            self.delegate?.timeLineDargSortViewDeleteSegment(with: selectedIndex)
        } else {
            self.delegate?.timeLineDargSortViewDidSort(with: selectedIndex, targetIndex: targetIndex)
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: VLEConstants.VLETimeLineRemoveDragSortViewNotification), object: nil)
    }
    
    // ✅ ADD THE POSITION PICKER METHOD
    private func showOverlayPositionOptions(completion: @escaping (CGPoint) -> Void) {
        let alert = UIAlertController(title: "Overlay Position", message: "Choose position", preferredStyle: .actionSheet)
        
        let positions = [
            ("Top Left", CGPoint(x: 0.2, y: 0.2)),
            ("Top Right", CGPoint(x: 0.8, y: 0.2)),
            ("Bottom Left", CGPoint(x: 0.2, y: 0.8)),
            ("Bottom Right", CGPoint(x: 0.8, y: 0.8)),
            ("Center", CGPoint(x: 0.5, y: 0.5))
        ]
        
        for (title, position) in positions {
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                completion(position)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // ✅ FALLBACK TO RANDOM POSITION IF CANCELLED
            let randomX = CGFloat.random(in: 0.25...0.75)
            let randomY = CGFloat.random(in: 0.25...0.75)
            completion(CGPoint(x: randomX, y: randomY))
        })
        
        DispatchQueue.main.async {
            if let viewController = self.findViewController() {
                viewController.present(alert, animated: true)
            }
        }
    }
    
}
