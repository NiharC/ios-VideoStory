//
//  AVVodeoPlayerView.swift
//  VideoPlayerTest
//
//  Created by nihar chadhei on 08/07/19.
//  Copyright © 2019. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

final class AVVodeoPlayerView: UIView {

    @IBOutlet weak var videoPlayerView: UIView!
    
    @IBOutlet weak var progressView: MediaProgressView!
   
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    var mediaCount = 0 {
        didSet {
            progressView.mediaCount = mediaCount
        }
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        playerLayer.videoGravity = AVLayerVideoGravity.resize
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
        playerLayer.videoGravity = AVLayerVideoGravity.resize
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("AVVodeoPlayerView", owner: self, options: nil)
        addSubview(videoPlayerView)
        videoPlayerView.frame = self.bounds
        videoPlayerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
}
extension AVVodeoPlayerView {
    func setPlayPause(play: Bool) {
        if play {
            player?.play()
        } else {
            player?.pause()
        }
    }
}

