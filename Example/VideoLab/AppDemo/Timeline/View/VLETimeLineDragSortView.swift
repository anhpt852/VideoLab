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
    lazy var realTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor.systemBlue
        label.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        label.textAlignment = .center
        label.text = "00:00"
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.layer.borderWidth = 2
        label.layer.borderColor = UIColor.systemBlue.cgColor
        label.isHidden = true
        return label
    }()

    lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.text = "Move horizontally to select time"
        label.isHidden = true
        return label
    }()
    
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
    
    // ✅ MODIFY setupView() method - add after headerLabel setup:
    func setupView() {
        self.backgroundColor = UIColor.init(hexString: "#212123")
        
        scrollView.contentSize = CGSize.init(width: contentWidth, height: 300)
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.width.equalTo(contentWidth)
            make.height.equalTo(80)  // ✅ Increased for time display
            make.left.top.equalToSuperview()
        }
        
        // ✅ Header label (instruction)
        headerView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
        }
        
        // ✅ ADD real-time display
        headerView.addSubview(realTimeLabel)
        realTimeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(35)
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
        }
        
        // ✅ ADD instruction label
        headerView.addSubview(instructionLabel)
        instructionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(realTimeLabel.snp.bottom).offset(4)
        }
        
        // ✅ Rest of existing setup...
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
            make.height.equalTo(90)
            make.left.equalToSuperview()
            make.top.equalTo(stackView.snp.bottom)
        }
        
        self.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize.init(width: 65, height: 65))
            make.top.equalTo(footerView.snp.top).offset(15)
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

    // ✅ REPLACE EXISTING setupTimelineSlider() method:
    func setupTimelineSlider() {
        guard let timelineVC = self.delegate as? VLETimeLineViewController else {
            print("❌ Cannot access timeline view controller for slider setup")
            return
        }
        
        mainTrackDuration = timelineVC.stateModel.calculateMainTrackDuration()
        let maxSeconds = Float(CMTimeGetSeconds(mainTrackDuration))
        
        // ✅ ENSURE MINIMUM DURATION FOR SLIDER
        let safeMaxSeconds = max(maxSeconds, 1.0)  // At least 1 second
        
        timelineSlider.minimumValue = 0
        timelineSlider.maximumValue = safeMaxSeconds
        
        // ✅ CLAMP CURRENT VALUE TO SAFE RANGE
        let defaultValue = min(safeMaxSeconds * 0.25, safeMaxSeconds)
        timelineSlider.value = defaultValue
        
        selectedOverlayTime = CMTime(seconds: Double(timelineSlider.value), preferredTimescale: 600)
        updateTimeLabel()
        
        print("🎛️ Timeline slider setup:")
        print("🎛️   - Main track duration: \(maxSeconds)s")
        print("🎛️   - Slider range: 0-\(safeMaxSeconds)s")
        print("🎛️   - Default value: \(defaultValue)s")
    }

    // ✅ REPLACE EXISTING timelineSliderChanged() method:
    @objc func timelineSliderChanged(_ slider: UISlider) {
        // ✅ DOUBLE-CHECK VALUE IS WITHIN MAIN TRACK
        let mainDurationSeconds = Float(CMTimeGetSeconds(mainTrackDuration))
        let clampedValue = min(slider.value, mainDurationSeconds)
        
        if slider.value > mainDurationSeconds {
            // ✅ AUTO-CORRECT SLIDER IF USER SOMEHOW GOES BEYOND
            slider.value = clampedValue
            print("⚠️ Slider value auto-corrected from \(slider.value)s to \(clampedValue)s")
        }
        
        selectedOverlayTime = CMTime(seconds: Double(clampedValue), preferredTimescale: 600)
        updateTimeLabel()
        
        // ✅ UPDATE CURSOR POSITION IN REAL-TIME
        if let timelineVC = self.delegate as? VLETimeLineViewController {
            timelineVC.updateCursorPosition(time: selectedOverlayTime)
        }
        
        print("🎛️ Timeline slider: \(CMTimeGetSeconds(selectedOverlayTime))s (max: \(mainDurationSeconds)s)")
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
    
    func refreshSliderRange() {
        guard let timelineVC = self.delegate as? VLETimeLineViewController else { return }
        
        let newMainDuration = timelineVC.stateModel.calculateMainTrackDuration()
        let newMaxSeconds = Float(CMTimeGetSeconds(newMainDuration))
        
        if newMaxSeconds != timelineSlider.maximumValue {
            print("🔄 Updating slider range: \(timelineSlider.maximumValue)s → \(newMaxSeconds)s")
            
            timelineSlider.maximumValue = max(newMaxSeconds, 1.0)
            
            // ✅ CLAMP CURRENT VALUE IF NEEDED
            if timelineSlider.value > newMaxSeconds {
                timelineSlider.value = newMaxSeconds * 0.8  // 80% of new duration
                timelineSliderChanged(timelineSlider)  // Update selected time
            }
            
            mainTrackDuration = newMainDuration
        }
    }
}

extension VLETimeLineDragSortView {

    // ✅ ADD this helper method:
    private func calculateTimelinePosition(from dragX: CGFloat) -> CMTime {
        guard let timelineVC = self.delegate as? VLETimeLineViewController else {
            return CMTime.zero
        }
        
        // Map drag position to timeline
        let headerWidth = headerView.bounds.width
        let timelineRatio = max(0, min(1, dragX / headerWidth))
        
        let mainDuration = timelineVC.stateModel.calculateMainTrackDuration()
        let targetSeconds = Double(timelineRatio) * CMTimeGetSeconds(mainDuration)
        
        return CMTime(seconds: targetSeconds, preferredTimescale: 600)
    }

    func beginSortView(with sender: UILongPressGestureRecognizer) {
        dragSortGridView.beginDragItemView(with: sender)
    }


    // ✅ REPLACE EXISTING moveSortView() method:
    func moveSortView(with sender: UILongPressGestureRecognizer) {
        dragSortGridView.moveDragItemView(with: sender)
        let point = sender.location(in: dragSortGridView)
        
        if (point.y < 0) && (point.y > -80) {  // ✅ Adjusted for new header height
            isSelectedHeaderView = true
            isSelectedFooterView = false
            
            // ✅ Show time display UI
            showTimeDisplayUI()
            
            // ✅ Calculate and display real-time position
            let headerPoint = sender.location(in: self)
            let timelinePosition = calculateTimelinePositionFromDrag(dragX: headerPoint.x)
            updateRealTimeDisplay(time: timelinePosition)
            updatePendingOverlayTime(timelinePosition)
            
            // ✅ Show cursor at calculated position
            if let timelineVC = self.delegate as? VLETimeLineViewController {
                timelineVC.showOverlayCursor()
                timelineVC.updateCursorPosition(time: timelinePosition)
            }
            
            print("🎯 Real-time positioning: X=\(headerPoint.x)px → Time=\(CMTimeGetSeconds(timelinePosition))s")
            
        } else if (point.y > 150) && (point.y < 235) {  // Delete area
            isSelectedHeaderView = false
            isSelectedFooterView = true
            
            // ✅ Hide time display
            hideTimeDisplayUI()
            
            if let timelineVC = self.delegate as? VLETimeLineViewController {
                timelineVC.hideOverlayCursor()
            }
            
        } else {  // Normal area
            isSelectedHeaderView = false
            isSelectedFooterView = false
            
            // ✅ Hide time display
            hideTimeDisplayUI()
            
            if let timelineVC = self.delegate as? VLETimeLineViewController {
                timelineVC.hideOverlayCursor()
            }
        }
    }

    // ✅ ADD to beginning of endSortView() method:
    func endSortView(with sender: UILongPressGestureRecognizer) {
        dragSortGridView.endDragItemView(with: sender)
        
        // ✅ Hide time display when drag ends
        hideTimeDisplayUI()
        
        if let timelineVC = self.delegate as? VLETimeLineViewController {
            timelineVC.hideOverlayCursor()
        }
        
        // ✅ Rest of existing logic...
        if isSelectedHeaderView == true {
            let finalTime = selectedOverlayTime
            print("🎯 Final selected time: \(CMTimeGetSeconds(finalTime))s")
            
            showOverlayPositionOptions { [weak self] selectedPosition in
                guard let self = self else { return }
                
                if let timelineVC = self.delegate as? VLETimeLineViewController {
                    timelineVC.stateModel.setPendingOverlayPosition(selectedPosition)
                    print("✅ Confirmed positioning: time=\(CMTimeGetSeconds(finalTime))s, position=\(selectedPosition)")
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
    

    // ✅ REPLACE existing showOverlayPositionOptions():
    private func showOverlayPositionOptions(completion: @escaping (CGPoint) -> Void) {
        let alert = UIAlertController(title: "Overlay Setup", message: "Choose position and size", preferredStyle: .actionSheet)
        
        // ✅ Position + Size combinations
        let options = [
            ("📱 Small Top Left", CGPoint(x: 0.2, y: 0.2), 0.2),
            ("📱 Small Top Right", CGPoint(x: 0.8, y: 0.2), 0.2),
            ("📱 Small Bottom Left", CGPoint(x: 0.2, y: 0.8), 0.2),
            ("📱 Small Bottom Right", CGPoint(x: 0.8, y: 0.8), 0.2),
            ("📺 Medium Center", CGPoint(x: 0.5, y: 0.5), 0.3),
            ("🖥️ Large Center", CGPoint(x: 0.5, y: 0.5), 0.4),
            ("📹 Full Width Top", CGPoint(x: 0.5, y: 0.15), 0.5)
        ]
        
        for (title, position, scale) in options {
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                // ✅ Store both position and scale
                if let timelineVC = self.delegate as? VLETimeLineViewController {
                    timelineVC.stateModel.setPendingOverlayPosition(position)
                    timelineVC.stateModel.setPendingOverlayScale(Float(scale))  // ← NEW
                }
                completion(position)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            let fallbackPosition = CGPoint(x: 0.5, y: 0.5)
            if let timelineVC = self.delegate as? VLETimeLineViewController {
                timelineVC.stateModel.setPendingOverlayPosition(fallbackPosition)
                timelineVC.stateModel.setPendingOverlayScale(0.25)
            }
            completion(fallbackPosition)
        })
        
        DispatchQueue.main.async {
            if let viewController = self.findViewController() {
                viewController.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - Direct Timeline Positioning

    // MARK: - Real-Time Display Methods

    private func showTimeDisplayUI() {
        realTimeLabel.isHidden = false
        instructionLabel.isHidden = false
        
        // ✅ Animate appearance
        realTimeLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.realTimeLabel.transform = CGAffineTransform.identity
        }
        
        // ✅ Update header instruction
        headerLabel.text = "Select overlay start time"
        headerLabel.textColor = UIColor.systemBlue
    }

    private func hideTimeDisplayUI() {
        realTimeLabel.isHidden = true
        instructionLabel.isHidden = true
        
        // ✅ Reset header
        headerLabel.text = "Drag here to convert to independent layer"
        headerLabel.textColor = UIColor.white
    }

    private func updateRealTimeDisplay(time: CMTime) {
        let timeString = formatTimeForDisplay(timeInSeconds: CMTimeGetSeconds(time))
        realTimeLabel.text = timeString
        
        // ✅ Subtle animation for feedback
        UIView.animate(withDuration: 0.1) {
            self.realTimeLabel.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.realTimeLabel.transform = CGAffineTransform.identity
            }
        }
        
        // ✅ Update instruction with more info
        let mainDuration = getMainDuration()
        let percentage = (CMTimeGetSeconds(time) / CMTimeGetSeconds(mainDuration)) * 100
        instructionLabel.text = String(format: "%.0f%% of timeline", percentage)
    }

    private func formatTimeForDisplay(timeInSeconds: Double) -> String {
        let totalSeconds = Int(timeInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let milliseconds = Int((timeInSeconds - Double(totalSeconds)) * 100)
        
        // ✅ Show precise time with centiseconds
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }

    private func getMainDuration() -> CMTime {
        guard let timelineVC = delegate as? VLETimeLineViewController else {
            return CMTime(seconds: 1, preferredTimescale: 600)
        }
        return timelineVC.stateModel.calculateMainTrackDuration()
    }

    // ✅ Improved timeline position calculation
    private func calculateTimelinePositionFromDrag(dragX: CGFloat) -> CMTime {
        guard let timelineVC = self.delegate as? VLETimeLineViewController else {
            return CMTime.zero
        }
        
        // ✅ Use more precise mapping with margins
        let leftMargin: CGFloat = 20
        let rightMargin: CGFloat = 20
        let effectiveWidth = self.bounds.width - leftMargin - rightMargin
        let adjustedX = max(0, min(effectiveWidth, dragX - leftMargin))
        
        let timelineRatio = adjustedX / effectiveWidth
        
        let mainDuration = timelineVC.stateModel.calculateMainTrackDuration()
        let targetSeconds = Double(timelineRatio) * CMTimeGetSeconds(mainDuration)
        
        let timelinePosition = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        
        print("📍 Precise mapping: X=\(dragX)px → Ratio=\(timelineRatio) → Time=\(targetSeconds)s")
        
        return timelinePosition
    }

    private func updatePendingOverlayTime(_ time: CMTime) {
        selectedOverlayTime = time
        updateTimeLabel()
        
        // ✅ Update pending state immediately
        if let timelineVC = delegate as? VLETimeLineViewController {
            timelineVC.stateModel.setPendingOverlayStartTime(time)
        }
        
        print("🕐 Updated pending overlay time: \(CMTimeGetSeconds(time))s")
    }

    // ✅ Optional: Visual feedback on header
    private func updateHeaderVisualFeedback(dragX: CGFloat) {
        let viewWidth = self.bounds.width
        let ratio = max(0, min(1, dragX / viewWidth))
        
        // Update header label with real-time time
        if let timelineVC = delegate as? VLETimeLineViewController {
            let mainDuration = timelineVC.stateModel.calculateMainTrackDuration()
            let targetSeconds = Double(ratio) * CMTimeGetSeconds(mainDuration)
            let timeString = formatTimeForDisplay(seconds: targetSeconds)
            
            headerLabel.text = "Drop at \(timeString)"
        }
    }

    private func formatTimeForDisplay(seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
