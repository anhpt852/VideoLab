//
//  VLETimeLineDragSortView.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/9/29.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia

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
    
    // ✅ ADD NEW PROPERTIES HERE
    private var selectedOverlayTime: CMTime = CMTime.zero
    private var mainTrackDuration: CMTime = CMTime.zero
    
    lazy var timelineSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.25  // Default to 25% position
        slider.tintColor = UIColor.systemBlue
        slider.thumbTintColor = UIColor.white
        slider.addTarget(self, action: #selector(timelineSliderChanged(_:)), for: .valueChanged)
        return slider
    }()
    
    lazy var timelineLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.text = "📍 Select overlay start time"
        return label
    }()
    
    lazy var timeValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor.systemBlue
        label.textAlignment = .center
        label.text = "00:00"
        label.layer.cornerRadius = 8
        label.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        label.layer.masksToBounds = true
        return label
    }()
    
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
    
    // ✅ REPLACE ENTIRE setupView() method:
    func setupView() {
        self.backgroundColor = UIColor.init(hexString: "#212123")
        
        // ✅ SETUP TIMELINE SLIDER FIRST
        setupTimelineSlider()
        
        scrollView.contentSize = CGSize.init(width: contentWidth, height: 350)
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.width.equalTo(contentWidth)
            make.height.equalTo(90)  // ✅ Increased height for slider
            make.left.top.equalToSuperview()
        }
        
        // ✅ ADD TIMELINE CONTROLS TO MAIN VIEW (not scrollView)
        self.addSubview(timelineLabel)
        timelineLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(scrollView.snp.top).offset(8)
        }
        
        self.addSubview(timelineSlider)
        timelineSlider.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.top.equalTo(timelineLabel.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        
        self.addSubview(timeValueLabel)
        timeValueLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(30)
            make.top.equalTo(timelineSlider.snp.bottom).offset(8)
        }
        
        // ✅ MODIFY HEADER LABEL POSITION
        self.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(timeValueLabel.snp.bottom).offset(8)
        }
        
        // ... rest of existing setupView (stackView, footerView, etc.) remains the same ...
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
    
    // ✅ ADD THESE NEW METHODS before extensions:

    // MARK: - Timeline Slider Methods

    func setupTimelineSlider() {
        guard let timelineVC = self.delegate as? VLETimeLineViewController else {
            print("❌ Cannot access timeline view controller for slider setup")
            return
        }
        
        mainTrackDuration = timelineVC.stateModel.calculateMainTrackDuration()
        let maxSeconds = Float(CMTimeGetSeconds(mainTrackDuration))
        
        timelineSlider.maximumValue = maxSeconds
        timelineSlider.value = maxSeconds * 0.25  // Default to 25% position
        
        selectedOverlayTime = CMTime(seconds: Double(timelineSlider.value), preferredTimescale: 600)
        updateTimeLabel()
        
        print("🎛️ Timeline slider setup: 0-\(maxSeconds)s, default: \(timelineSlider.value)s")
    }

    @objc func timelineSliderChanged(_ slider: UISlider) {
        selectedOverlayTime = CMTime(seconds: Double(slider.value), preferredTimescale: 600)
        updateTimeLabel()
        
        // ✅ UPDATE CURSOR POSITION IN REAL-TIME
        if let timelineVC = self.delegate as? VLETimeLineViewController {
            timelineVC.updateCursorPosition(time: selectedOverlayTime)
        }
        
        print("🎛️ Timeline slider: \(CMTimeGetSeconds(selectedOverlayTime))s")
    }

    func updateTimeLabel() {
        let totalSeconds = Int(CMTimeGetSeconds(selectedOverlayTime))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        timeValueLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    func getSelectedOverlayTime() -> CMTime {
        return selectedOverlayTime
    }
}

extension VLETimeLineDragSortView {

    func beginSortView(with sender: UILongPressGestureRecognizer) {
        dragSortGridView.beginDragItemView(with: sender)
    }

    // ✅ REPLACE EXISTING moveSortView() method:
    func moveSortView(with sender: UILongPressGestureRecognizer) {
        dragSortGridView.moveDragItemView(with: sender)
        let point = sender.location(in: dragSortGridView)
        
        if (point.y < 0) && (point.y > -90) {  // ✅ Increased area for slider
            isSelectedHeaderView = true
            isSelectedFooterView = false
            
            // ✅ SHOW CURSOR WHEN ENTERING OVERLAY AREA
            if let timelineVC = self.delegate as? VLETimeLineViewController {
                timelineVC.showOverlayCursor()
                timelineVC.updateCursorPosition(time: selectedOverlayTime)
            }
            
        } else if (point.y > 150) && (point.y < 285) {
            isSelectedHeaderView = false
            isSelectedFooterView = true
            
            // ✅ HIDE CURSOR WHEN IN DELETE AREA
            if let timelineVC = self.delegate as? VLETimeLineViewController {
                timelineVC.hideOverlayCursor()
            }
            
        } else {
            isSelectedHeaderView = false
            isSelectedFooterView = false
            
            // ✅ HIDE CURSOR IN NORMAL AREA
            if let timelineVC = self.delegate as? VLETimeLineViewController {
                timelineVC.hideOverlayCursor()
            }
        }
    }

    // ✅ REPLACE EXISTING endSortView() method:
    func endSortView(with sender: UILongPressGestureRecognizer) {
        dragSortGridView.endDragItemView(with: sender)
        
        if let timelineVC = self.delegate as? VLETimeLineViewController {
            timelineVC.hideOverlayCursor()
        }
        
        if isSelectedHeaderView == true {
            showOverlayPositionOptions { [weak self] selectedPosition in
                guard let self = self else { return }
                
                if let timelineVC = self.delegate as? VLETimeLineViewController {
                    timelineVC.stateModel.setPendingOverlayPosition(selectedPosition)
                    // ✅ USE SELECTED TIME FROM SLIDER
                    timelineVC.stateModel.setPendingOverlayStartTime(self.selectedOverlayTime)
                    
                    print("🎯 Using slider time: \(CMTimeGetSeconds(self.selectedOverlayTime))s")
                    print("🎯 Using position: \(selectedPosition)")
                }
                
                self.delegate?.timelineDargSortViewChangedSeparate(with: self.selectedIndex, dragPositionXRate: 0.0)
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
