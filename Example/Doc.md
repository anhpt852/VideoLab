VideoLab_Example Project - Complete Analysis & Documentation
📋 Table of Contents
Project Overview
Architecture & Design Patterns
Core Components
Timeline System Deep Dive
Mediator Pattern Implementation
UI Components & Layouts
Data Models
User Interaction Flows
VideoLab Integration
Key Features
🎯 Project Overview
VideoLab_Example is a sophisticated iOS video editing application built with Swift, using the VideoLab framework for video processing and composition. The app implements advanced design patterns and provides professional timeline-based video editing capabilities.

Technology Stack
Language: Swift
Video Framework: VideoLab
UI Framework: UIKit + SnapKit (Auto Layout)
Architecture: Mediator Pattern + MVC
Media: AVFoundation, Photos Framework
UI Components: Custom timeline, drag & drop, gesture recognizers
🏗️ Architecture & Design Patterns
Mediator Pattern Implementation
The app uses a Centralized Mediator Pattern to manage communication between different view controllers.

swift
class VLEMainConcreteMediator: VLEMainMediator {
    static let shared = VLEMainConcreteMediator()
    
    weak var playbackViewController: VLEPlaybackViewController?
    weak var timelineViewController: VLETimeLineViewController?
    weak var effectViewController: VLEEffectViewController?
    weak var navViewController: VLENavViewController?
    weak var mainViewController: VLEMainViewController?
}
Controller Hierarchy
VLEMainViewController (Root Container)
├── VLENavViewController (Navigation Bar - 48pt)
├── VLEPlaybackViewController (Video Player - Flexible)
├── VLETimeLineViewController (Timeline Editor - 250pt)
└── VLEEffectViewController (Effects Panel - 52pt + safe area)
🧩 Core Components
1. VLEMainViewController
Role: Root container managing all child view controllers

Layout Stack (Top to Bottom):

┌─────────────────────────────────────┐
│         Navigation (48pt)           │ ← navViewController
├─────────────────────────────────────┤
│                                     │
│         Video Playback              │ ← playbackViewController
│         (flexible height)           │
│                                     │
├─────────────────────────────────────┤
│         Timeline (250pt)            │ ← timelineViewController
├─────────────────────────────────────┤
│         Effects (52pt + safe area)  │ ← effectViewController
└─────────────────────────────────────┘
2. VLEPlaybackViewController
Role: Video playback and preview

Key Features:

AVPlayer integration for real-time video preview
Scrubbing support from timeline
VideoLab composition rendering
Time-based seeking and playback control
swift
func previewItem(with videoLab: VideoLab) {
    let playerItem = videoLab.makePlayerItem()
    playerItem.seekingWaitsForVideoCompositionRendering = true
    // Setup AVPlayer with VideoLab composition
}
3. VLETimeLineViewController
Role: Timeline-based video editing interface

Key Components:

scaleView: Time ruler with time markers
renderTrackView: Main video track
separateRenderTrackViewArray: Overlay tracks
dragSortView: Drag reordering interface
toolBarView: Editing tools (clip, undo, redo)
4. VLEEffectViewController
Role: Effects and filters management

Available Effects:

Canvas Effects: Background colors, aspect ratios
Text Effects: Animated text, titles, watermarks
Filter Effects: LUT filters, custom filters
Special Effects: Zoom blur, transform animations
🎬 Timeline System Deep Dive
Data Architecture
swift
VLETimeLineStateModel
├── renderTrackItemModelArray: [VLETimeLineItemModel]    // Main sequential track
├── separateRenderTrackItemModelArray: [VLETimeLineItemModel]  // Overlay tracks
├── currentSelectedItemModel: VLETimeLineItemModel?      // Currently selected
├── currentSelectedIndex: Int?                           // Selection index
└── renderSize: CGSize                                   // Video composition size
Time Calculation System (VLETimeLineConfig)
swift
static let framesPerSecond: Float = 30      // 30 FPS timeline
static let ptPerFrames: CGFloat = 1          // 1 point = 1 frame
static let frontMargin: CGFloat = screenWidth/2  // Left padding
static let backMargin: CGFloat = screenWidth/2   // Right padding

// Core conversion functions
func convertToPt(value time: CMTime) -> CGFloat
func convertToSecond(value pt: CGFloat) -> Float
Timeline Scale Formula:

Pixel Position = (Time in seconds) × 30 FPS × 1 pt/frame
Total Width = frontMargin + videoWidth + backMargin
Two-Track System
Main Render Track
Sequential videos placed end-to-end
Auto-calculated timing with refreshItemTime()
Clip operations for splitting segments
Drag reordering support
Separate Render Track (Overlay)
Independent timing and positioning
Transform animations (scale: 0.5, random position)
Multi-layer support for text, stickers, floating videos
Individual editing capabilities
Advanced Drag & Drop Features
1. Segment Reordering
swift
func timeLineDargSortViewDidSort(selectedIndex: Int, targetIndex: Int) {
    stateModel.swapItemForRenderTrack(selectedIndex: selectedIndex, targetIndex: targetIndex)
    stateModel.refreshItemTime()
    reloadView()
}
2. Main → Separate Track Conversion
swift
func timelineDargSortViewChangedSeparate(with selectedIndex: Int, dragPositionXRate: Float) {
    // Convert main track item to overlay
    let selectedModel = renderTrackItemModelArray.remove(at: selectedIndex)
    selectedModel.isSeparateRenderTrack = true
    
    // Apply transform for overlay positioning
    let center = CGPoint(x: randomX, y: randomY)
    let transform = Transform(center: center, rotation: 0, scale: 0.5)
    selectedModel.renderLayer.transform = transform
}
3. Segment Editing with Resize Handles
swift
VLETimeLineRenderTrackDragView
├── leftDragBlockView   // Trim start + adjust duration
├── rightDragBlockView  // Trim end only
└── middleAreaView      // Selection indicator
Timeline-Playback Synchronization
Scroll → Video Seek
swift
func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let rate = offsetX / maxX
    VLEMainConcreteMediator.shared.previewTimeLineItem(rate: Float64(rate))
}
Video Progress → Timeline Position
swift
func updatePlaybackProgress(time: CMTime) {
    let second = CMTimeGetSeconds(time) * Float64(framesPerSecond) * Float64(ptPerFrames)
    backScrollView.setContentOffset(CGPoint(x: second, y: 0), animated: false)
}
🔄 Mediator Pattern Implementation
Communication Flows
Asset Management Flow
User clicks "+" → Timeline → Mediator → Present Picker →
User selects → Mediator → Timeline updates → Playback updates
Playback Control Flow
Timeline scroll → Mediator → Playback seeks →
Mediator → Timeline updates position
Effects Application Flow
User selects effect → Effects View → Mediator →
Timeline applies → Playback updates
Key Mediator Methods
swift
// Asset Management
func addAssetWithPickerViewController()
func addAssetToRenderTrackWith(itemModelArray: [VLETimeLineItemModel])

// Playback Control
func previewTimeLineItem(videoLab: VideoLab)
func previewTimeLineItem(rate: Float64)
func playbackProgressValueDidChanged(currentTime: CMTime)

// Export
func buildCurrentTimeLineItemToExport() -> VideoLab?
🎨 UI Components & Layouts
VLETimeLineScaleView - Time Ruler
swift
private func reloadScale() {
    while (sumWidth >= 0) {
        if index == 0 || index == 3 {
            // Show time text every 3 intervals (MM:SS format)
            let timeTextStr = VLETimeLineConfig.secondsToMinutesSeconds(sourceSeconds: second)
        } else {
            // Show small dots for intermediate marks
            let circleLayer = makeCircleLayer(center: point)
        }
    }
}
VLETimeLineRenderTrackSegmentView - Video Thumbnails
swift
func refreshThumbnailImageView(count: Int) {
    // Generate multiple thumbnails across video duration
    model.generateThumbnails(with: count) { error in
        // Display thumbnails in 64pt intervals
    }
}
VLETimeLineSeparateRenderTrackView - Overlay Elements
Two-state UI: Collapsed (icon only) vs Expanded (with resize handles)

swift
func showSummaryView() {
    summaryView.isHidden = false
    rightDragBlockView.isHidden = false
    leftDragBlockView.isHidden = false
    // Show resize handles and selection border
}
📊 Data Models
VLETimeLineItemModel
swift
class VLETimeLineItemModel {
    var source: Source                    // VideoLab source (video/image/audio)
    var type: VLETimeLineItemType         // .video, .image, .audio, .text, .sticker
    var renderLayer: RenderLayer          // VideoLab render layer
    var globalStartTime: CMTime           // Timeline position
    var thumbnailImageArray: [UIImage]    // Preview thumbnails
    var isSeparateRenderTrack: Bool       // Main track vs overlay track
}
VLETimeLineStateModel
swift
class VLETimeLineStateModel {
    var renderSize: CGSize                // Video composition size (1280x720)
    var totalSeconds: Float               // Total timeline duration
    var totalDuration: CMTime             // Total duration in CMTime
    var currentSelectedItemModel: VLETimeLineItemModel?
    var currentSelectedIndex: Int?
    
    // Track arrays with automatic notifications
    var renderTrackItemModelArray: [VLETimeLineItemModel]
    var separateRenderTrackItemModelArray: [VLETimeLineItemModel]
}
🎯 User Interaction Flows
Flow 1: Add Video Asset
1. User taps + button
2. Timeline → Mediator.addAssetWithPickerViewController()
3. Present VLEPickerViewController
4. User selects video asset
5. Mediator.addAssetToRenderTrackWith(itemModelArray:)
6. Timeline.addAssetToRenderTrackViewWith()
7. stateModel.renderTrackItemModelArray.append()
8. stateModel.refreshItemTime()
9. reloadView() → Update UI
10. buildVideolab() → Create composition
11. Mediator.previewTimeLineItem() → Update playback
Flow 2: Reorder Timeline Segments
1. Long press on timeline segment
2. VLETimeLineDragSortView appears (full-screen)
3. User drags to new position
4. timeLineDargSortViewDidSort(selectedIndex:, targetIndex:)
5. stateModel.swapItemForRenderTrack()
6. stateModel.refreshItemTime()
7. reloadView() → Update positions
8. buildVideolab() → Update composition
9. Preview updates automatically
Flow 3: Convert to Overlay Track
1. Long press timeline segment
2. Drag to header area ("转换为独立的层")
3. timelineDargSortViewChangedSeparate()
4. Remove from renderTrackItemModelArray
5. Apply transform (scale: 0.5, random position)
6. Add to separateRenderTrackItemModelArray
7. Create VLETimeLineSeparateRenderTrackView
8. Update layout and preview
Flow 4: Clip/Split Video Segment
1. Select timeline segment
2. Position timeline cursor at split point
3. Tap clip button in toolbar
4. clipRenderTrackItemModelAtCurrentIndex(clipRate:)
5. Calculate split position from cursor
6. Create new VLETimeLineItemModel with remaining duration
7. Update original item duration
8. Insert new item at currentIndex + 1
9. refreshItemTime() → Recalculate all positions
10. Update UI and preview
🎬 VideoLab Integration
Timeline → VideoLab Composition
swift
func buildVideolab() -> VideoLab {
    var renderLayers: [RenderLayer] = []
    
    // Add main sequential track
    for item in stateModel.renderTrackItemModelArray {
        renderLayers.append(item.renderLayer)
    }
    
    // Add overlay tracks
    for item in stateModel.separateRenderTrackItemModelArray {
        renderLayers.append(item.renderLayer)
    }
    
    // Create final composition
    let composition = RenderComposition()
    composition.renderSize = stateModel.renderSize  // 1280x720
    composition.layers = renderLayers
    
    return VideoLab(renderComposition: composition)
}
Effects Integration
swift
// Text Effects with VideoLab AnimationLayer
let textLayer = TextOpacityAnimationLayer()
textLayer.attributedText = attributedString
textLayer.position = position
composition.animationLayer = textLayer

// Filter Effects with VideoLab Operations
let lookupFilter = LookupFilter()
lookupFilter.addTexture(lutTexture, at: 0)
currentLayer.operations = [lookupFilter]

// Transform Animations with KeyframeAnimation
let animation = KeyframeAnimation(
    keyPath: "scale",
    values: [1.0, 1.5, 1.0],
    keyTimes: keyTimes,
    timingFunctions: [.quadraticEaseInOut]
)
transform.animations = [animation]
📡 Notification System
Event Broadcasting
swift
// VLEConstants.swift - Centralized notification names
static let VLETimeLineAssetDidIsEmptyNotification = "VLETimeLineAssetIsEmptyNotification"
static let VLETimeLineAssetDidIsNonemptyNotification = "VLETimeLineAssetIsNonemptyNotification"
static let VLETImeLineShowDragSortViewNotification = "VLETImeLineShowDragSortViewNotification"
static let VLETimeLineRemoveDragSortViewNotification = "VLETimeLineRemoveDragSortViewNotification"
State-Driven UI Updates
swift
// Automatic notifications on data changes
public var renderTrackItemModelArray: [VLETimeLineItemModel] {
    set {
        _renderTrackItemModelArray = newValue
        if isEmpty {
            NotificationCenter.default.post(name: .VLETimeLineAssetDidIsEmpty)
        } else {
            NotificationCenter.default.post(name: .VLETimeLineAssetDidIsNonempty)
        }
    }
}
✨ Key Features
1. Professional Timeline Editing
Frame-accurate editing with 30 FPS precision
Multi-track support (main + overlay tracks)
Visual timeline with time ruler and thumbnails
Drag & drop reordering with smooth animations
Clip/split operations for precise editing
2. Real-time Preview
Instant preview on every timeline change
Synchronized playback with timeline position
Scrubbing support for precise seeking
Live composition updates via VideoLab
3. Advanced Effects System
Text overlays with animations (fade in/out)
LUT filters for color grading
Transform animations (scale, rotation, position)
Special effects (zoom blur, custom filters)
4. Intuitive User Experience
Gesture-rich interface (tap, long press, pan, scroll)
Visual feedback (drag zones, resize handles)
Contextual toolbars (clip, undo, redo)
Smooth animations throughout
5. Robust Architecture
Mediator pattern for loose coupling
Automatic state management with notifications
Memory efficient with lazy loading
Scalable design for adding new features
🔧 Development Notes
iOS 18.5 Compatibility Issue
There's a known crash on iOS 18.5 related to Photos framework:

swift
// Issue: .smartAlbumUserLibrary not found
guard let model = model else {
    // Fallback: Create default album model
    let allPhotosResult = PHAsset.fetchAssets(with: option)
    return VLEPickerAlbumListModel(title: "All Photos", result: allPhotosResult, ...)
}
Performance Considerations
Thumbnail generation is async and cached
Timeline rendering uses CAShapeLayer for efficiency
Video composition is built on-demand
Memory management with weak references in Mediator
Extension Points
Custom effects via VideoLab operations
Export formats via AVAssetExportSession
Cloud storage integration potential
Collaborative editing architecture ready
📚 Additional Resources
Key Files Structure
VideoLab_Example/
├── Controllers/
│   ├── VLEMainViewController.swift
│   ├── VLEPlaybackViewController.swift
│   ├── VLETimeLineViewController.swift
│   ├── VLEEffectViewController.swift
│   └── VLENavViewController.swift
├── Models/
│   ├── VLETimeLineStateModel.swift
│   ├── VLETimeLineItemModel.swift
│   └── VLETimeLineConfig.swift
├── Views/
│   ├── Timeline/
│   │   ├── VLETimeLineScaleView.swift
│   │   ├── VLETimeLineRenderTrackView.swift
│   │   ├── VLETimeLineSeparateRenderTrackView.swift
│   │   └── VLETimeLineDragSortView.swift
│   └── Effects/
│       └── VLEEffectFirstLevelView.swift
└── Mediator/
    └── VLEMainConcreteMediator.swift
Design Patterns Used
Mediator Pattern: Central communication hub
Delegate Pattern: View-to-controller communication
Observer Pattern: Notification-based state updates
Factory Pattern: View creation methods
State Pattern: Timeline state management
This documentation provides a comprehensive overview of the VideoLab_Example project architecture, components, and functionality. Use it as a reference for understanding the codebase, adding new features, or troubleshooting issues.

