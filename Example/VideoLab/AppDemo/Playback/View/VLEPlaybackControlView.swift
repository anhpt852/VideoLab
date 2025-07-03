//
//  VLEPlayControlView.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/8/30.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import UIKit
import PKHUD

enum VLEPlaybackState {
    case play
    case pause
    case playback
}

enum VLEPlaybackAction {
    case play
    case pause
}

protocol VLEPlaybackControlViewDelegate: NSObjectProtocol {
    func playbackControlView(_ view: VLEPlaybackControlView, clickPlaybackButton button: UIButton, action: VLEPlaybackAction)
}

class VLEPlaybackControlView : UIView{
    weak var delegate: VLEPlaybackControlViewDelegate?
    
    // ✅ ADD: Current playback state
    private var currentState: VLEPlaybackState = .pause {
        didSet {
            updatePlayButtonAppearance()
        }
    }
    
    lazy var switchFullScreenButton: UIButton = {
        let button = UIButton.init()
        button.setBackgroundImage(UIImage.init(named: "playback_fullscreen_button"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(switchFullScreenButtonAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel.init()
        label.text = "00:00"
        label.textColor = UIColor.init(hexString: "#BABABA")
        return label
    }()
    
    // ✅ UPDATED: Play button with state management
    lazy var playButton: UIButton = {
        let button = UIButton.init()
        button.setBackgroundImage(UIImage.init(named: "playback_play_button"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(playButtonAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    init(delegate: VLEPlaybackControlViewDelegate) {
        self.delegate = delegate
        super.init(frame: CGRect.zero)
        setupViews()
        updatePlayButtonAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        self.addSubview(timeLabel)
        timeLabel.snp.makeConstraints({ make in
            make.centerY.equalToSuperview()
            make.left.equalTo(self.snp_leftMargin).offset(5)
        })
        self.addSubview(playButton)
        playButton.snp.makeConstraints({ make in
            make.size.equalTo(32)
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        })
        self.addSubview(switchFullScreenButton)
        switchFullScreenButton.snp.makeConstraints({ make in
            make.size.equalTo(32)
            make.centerY.equalToSuperview()
            make.right.equalTo(self.snp_rightMargin).offset(-12)
        })
    }
    
    // ✅ ADD: Update button appearance based on state
    private func updatePlayButtonAppearance() {
        switch currentState {
        case .play, .playback:
            // Show pause icon
            playButton.setBackgroundImage(UIImage.init(named: "playback_pause_button"), for: .normal)
            playButton.accessibilityLabel = "Pause"
        case .pause:
            // Show play icon
            playButton.setBackgroundImage(UIImage.init(named: "playback_play_button"), for: .normal)
            playButton.accessibilityLabel = "Play"
        }
    }
    
    // ✅ UPDATED: Toggle play/pause
    @objc func playButtonAction() {
        switch currentState {
        case .pause:
            currentState = .play
            self.delegate?.playbackControlView(self, clickPlaybackButton: self.playButton, action: .play)
        case .play, .playback:
            currentState = .pause
            self.delegate?.playbackControlView(self, clickPlaybackButton: self.playButton, action: .pause)
        }
    }
    
    @objc func switchFullScreenButtonAction() {
        HUD.show(.label("Not yet available"))
        HUD.hide(afterDelay: 0.5)
    }
    
    // ✅ ADD: Public methods to update state
    public func setPlaybackState(_ state: VLEPlaybackState) {
        currentState = state
    }
    
    public func updateForPlaying() {
        currentState = .play
    }
    
    public func updateForPaused() {
        currentState = .pause
    }
}
