//
//  AVVideoPlayerModel.swift
//  VideoPlayerTest
//
//  Created by nihar chadhei on 08/07/19.
//  Copyright © 2019. All rights reserved.
//

import UIKit
import AVFoundation

struct PlayerKeys {
    static let rate = "rate"
    static let status = "status"
    static let timeRanges = "loadedTimeRanges"
    static let bufferEmpty = "playbackBufferEmpty"
    static let playBackKeepUp = "playbackLikelyToKeepUp"
    static let duration = "duration"
}

protocol PlayerStateDelegate: class {
    func playerDidFailToPlay(message: String)
    func playerDidSuccesToPlay()
}

extension PlayerStateDelegate {
    //default empty implementation to make playerDidFailToPlay optional
    func playerDidFailToPlay(message: String) {
        
    }
}

final class AVVideoPlayerModel: NSObject {
    
    @objc var player: AVPlayer?
    
    weak var delegate: PlayerStateDelegate?
    var playerItems = [AVPlayerItem]()
    var players = [AVPlayer]()
    
    static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]
    
    override init() {
        super.init()
    }
    
    var currentTime: Double {
        get {
            return CMTimeGetSeconds(player?.currentTime() ?? CMTime.zero)
        }
        set {
            let newTime = CMTimeMakeWithSeconds(newValue, preferredTimescale: 1)
            player?.seek(to: newTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
    
    var duration: Double {
        guard let currentItem = player?.currentItem else { return 0.0 }
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    var rate: Float {
        get {
            return player?.rate ?? 0.0
        }
        
        set {
            player?.rate = newValue
        }
    }
    var avUrlAssets: [AVURLAsset]? {
        didSet {
            guard let newAssets = avUrlAssets else {
                return
            }
            asynchronouslyLoadURLAssets(newAssets)
        }
    }
    
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()

    private var timeObserverToken: Any?
    
    func asynchronouslyLoadURLAssets(_ newAssets: [AVURLAsset]) {
        playerItems = []
        players = []
        DispatchQueue.main.async {
            for newAsset in newAssets {
                newAsset.loadValuesAsynchronously(forKeys: AVVideoPlayerModel.assetKeysRequiredToPlay) {
                    
                    
                    for key in AVVideoPlayerModel.assetKeysRequiredToPlay {
                        var error: NSError?
                        
                        if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                            let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                            let message = String.localizedStringWithFormat(stringFormat, key)
                            self.delegate?.playerDidFailToPlay(message: message)
                            return
                        }
                    }
                    
                    if !newAsset.isPlayable || newAsset.hasProtectedContent {
                        let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                        self.delegate?.playerDidFailToPlay(message: message)
                        return
                    }
                    let currentItem = AVPlayerItem(asset: newAsset)
                    let currentPlayer = AVPlayer(playerItem: currentItem)
                    DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
                        if self.playerItems.isEmpty {
                            self.playerItems.append(currentItem)
                            self.players.append(currentPlayer)
                            self.delegate?.playerDidSuccesToPlay()
                        } else {
                            self.players.append(currentPlayer)
                            self.playerItems.append(currentItem)
                        }
                    })
                }
            }
            
        }
    }
    
    // MARK: - IBActions
    
    func playPauseButtonWasPressed() {
        guard let player = player else {
            return
        }
        if player.rate != 1.0 {
            // Not playing forward, so play.
            if currentTime == duration {
                // At end, so got back to begining.
                currentTime = 0.0
            }
            player.play()
        } else {
            // Playing, so pause.
            player.pause()
        }
    }
    
    // Trigger KVO for anyone observing our properties affected by player and player.currentItem
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration": [#keyPath(player.currentItem.duration )],
            "rate": [#keyPath(player.rate)]
        ]
        return affectedKeyPathsMappingByKey[key]!
    }
    // MARK: Convenience
    
    func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
    
    func getTimeString(from time: CMTime?) -> String {
        if let totalTime = time, totalTime.isIndefinite == false {
            let totalSeconds = CMTimeGetSeconds(totalTime)
            let hours = Int(totalSeconds/3600)
            let minutes = Int(totalSeconds/60) % 60
            let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
            if hours > 0 {
                return String(format: "%i:%02i:%02i", arguments: [hours, minutes, seconds])
            } else {
                return String(format: "%02i:%02i", arguments: [minutes, seconds])
            }
        } else {
            return "0:00"
        }
    }
    
}
