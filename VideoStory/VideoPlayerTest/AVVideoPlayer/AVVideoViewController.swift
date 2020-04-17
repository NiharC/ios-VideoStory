
//
//  AVVideoViewController.swift
//  VideoPlayerTest
//
//  Created by nihar chadhei on 08/07/19.
//  Copyright © 2019. All rights reserved.
//

import UIKit
import AVFoundation

final class AVVideoViewController: UIViewController {

    
    private var playerView: AVVodeoPlayerView?
    private var playerViewModel: AVVideoPlayerModel?
    private var movieURLs: [URL]
    private var snapIndex: Int = 0
    
    private lazy var tap_gesture: UITapGestureRecognizer = {
        let tg = UITapGestureRecognizer(target: self, action: #selector(didTapSnap(_:)))
        tg.numberOfTapsRequired = 1
        return tg
    }()
    
    init(url: [URL]) {
        movieURLs = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

    }
    
    func configureVideoPlayer() {
        playerView = AVVodeoPlayerView.init(frame: self.view.frame)
        playerView?.translatesAutoresizingMaskIntoConstraints = false
        playerView?.mediaCount = movieURLs.count
        var assets = [AVURLAsset]()
        for url in movieURLs {
            assets.append(AVURLAsset(url: url, options: nil))
        }
        var playerItem = [AVPlayerItem]()
        for asset in assets {
            playerItem.append(AVPlayerItem(asset: asset))
        }
        
        guard let playerView = playerView else { return }
        playerViewModel = AVVideoPlayerModel()
        playerViewModel?.avUrlAssets = assets
        guard let playerViewModel = playerViewModel else { return }
        playerViewModel.delegate = self
        playerView.backgroundColor = UIColor.black
        self.view.backgroundColor = UIColor.black
        self.view.addSubview(playerView)
        playerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        playerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        playerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        
        playerView.progressView.createSnapProgressors()
        view.addGestureRecognizer(tap_gesture)
    }
    
    private func addPlayer(player: AVPlayer) {
        player.currentItem?.seek(to:  CMTime.zero, completionHandler: nil)
        playerViewModel?.player = player
        guard let playerView = playerView else { return }
        playerView.playerLayer.player = player
    }
    
    @objc private func didTapSnap(_ sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(ofTouch: 0, in: view)
        if touchLocation.x < view.frame.width/2 {
            clearLastPlayedSnap()
            changePlayer(forward: false, selectedIndex: snapIndex)
        } else  {
            fillupLastPlayedSnap()
            changePlayer(forward: true, selectedIndex: snapIndex)
        }
    }
    
    @objc private func didEnterForeground() {
        if let progressView = self.getProgressView(with: snapIndex) {
            progressView.resume()
        }
    }
    
    @objc private func didEnterBackground() {
        if let progressView = self.getProgressView(with: snapIndex) {
            progressView.pause()
        }
    }
}

extension AVVideoViewController: PlayerStateDelegate {
    func playerDidSuccesToPlay() {
        if let item = playerViewModel?.playerItems.first,
            let player = playerViewModel?.players.first  {
            DispatchQueue.main.async {
                self.addPlayer(player: player)
                self.addObservers(item: item)
            }
        }
        
    }
    
    private func removeObservers(item: AVPlayerItem) {
        NotificationCenter.default
            .removeObserver(self,
                            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                            object: item)
        
        item.removeObserver(self,
                            forKeyPath: PlayerKeys.timeRanges)
        item.removeObserver(self,
                            forKeyPath: PlayerKeys.duration)
    }
    
    private func addObservers(item: AVPlayerItem) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidEndPlaying),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: item)
        item.addObserver(self,
                         forKeyPath: PlayerKeys.timeRanges,
                         options: .new,
                         context: nil)
        item.addObserver(self,
                         forKeyPath: PlayerKeys.duration,
                         options: [.new, .initial],
                         context: nil)
        
    }
    
    @objc private func playerDidEndPlaying(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            if let model = playerViewModel,
                let index = model.playerItems.firstIndex(of: playerItem) {
                changePlayer(forward: true, selectedIndex: index)
            }
        }
    }
    
    
    
    private func changePlayer(forward: Bool, selectedIndex: Int) {
        if let model = playerViewModel,
            let firstItem =  model.playerItems.first,
            let firstPlayer = model.players.first {
            let selectedItem = model.playerItems[selectedIndex]
            stopPlayer()
            removeObservers(item: selectedItem)
            let item: AVPlayerItem
            let player: AVPlayer
            if forward {
                if selectedIndex < model.playerItems.count - 1 {
                    item = model.playerItems[selectedIndex + 1]
                    player = model.players[selectedIndex + 1]
                } else {
                    player = firstPlayer
                    item = firstItem
                }
            } else {
                if selectedIndex > 0 {
                    item = model.playerItems[selectedIndex - 1]
                    player = model.players[selectedIndex - 1]
                } else {
                    player = firstPlayer
                    item = firstItem
                }
            }
            addPlayer(player: player)
            addObservers(item: item)
        }
    }
}

extension AVVideoViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem,
            let keyPath = keyPath else {
                return
        }
        if item == playerViewModel?.player?.currentItem,
            let playerArray = playerViewModel?.playerItems,
            let index = playerArray.firstIndex(of: item) {
            DispatchQueue.main.async {
                if keyPath == PlayerKeys.duration, item.duration.seconds > 0.0 {
                    self.didStartPlaying(index: index, player: self.playerViewModel?.player)
                } else if keyPath == PlayerKeys.timeRanges {
                    self.playerView?.setPlayPause(play: true)
                }
            }
        }
    }
}

extension AVVideoViewController {
    
    private func stopPlayer() {
        playerView?.player?.pause()
    }
    
    private func getProgressView(with index: Int) -> MediaProgressAnimatorView? {
        if let progressView = playerView?.progressView.getProgressView, progressView.subviews.count > 0 {
            let pv = progressView.subviews.filter({v in v.tag == index+progressViewTag}).first as? MediaProgressAnimatorView
            return pv
        }
        return nil
    }
    
    private func getProgressIndicatorView(with index: Int) -> UIView? {
        if let progressView = playerView?.progressView.getProgressView, progressView.subviews.count>0 {
            return progressView.subviews.filter({v in v.tag == index+progressIndicatorViewTag}).first
        }else{
            return nil
        }
    }

    //Before progress view starts we have to fill the progressView
    private func fillupLastPlayedSnap() {
        if let holderView = self.getProgressIndicatorView(with: snapIndex),
            let progressView = self.getProgressView(with: snapIndex) {
            progressView.stop()
            progressView.frame.size.width = holderView.frame.width
        }
    }
    
    private func fillupLastPlayedSnaps() {
        //Coz, we are ignoring the first.snap
        if snapIndex != 0 {
            for i in 0..<snapIndex {
                if let holderView = self.getProgressIndicatorView(with: i),
                    let progressView = self.getProgressView(with: i) {
                    progressView.stop()
                    progressView.frame.size.width = holderView.frame.width
                }
            }
        }
    }
    
    private func clearLastPlayedSnap() {
        if let progressView = self.getProgressView(with: snapIndex) {
            progressView.stop()
            progressView.frame.size.width = 0
        }
        if snapIndex > 0, let progressView = self.getProgressView(with: snapIndex - 1) {
            progressView.frame.size.width = 0
        }
    }
}

extension AVVideoViewController {
    func didStartPlaying(index: Int, player: AVPlayer?) {
        snapIndex = index
        if let holderView = getProgressIndicatorView(with: index),
            let progressView = getProgressView(with: index) {
            if index == 0 {
                playerView?.progressView.resetProgressBar()
            }
            progressView.snapIndex = index
            if let duration = player?.currentItem?.asset.duration {
                if Float(duration.value) > 0 {
                    progressView.start(with: duration.seconds, width: holderView.frame.width, completion: {(snapIndex, isCancelledAbruptly) in
                        if isCancelledAbruptly == false {
//                            self.stopPlayer()
//                            self.didCompleteProgress()
                        } else {
//                            self.videoSnapIndex = snapIndex
//                            self.stopPlayer()
                        }
                    })
                }else {
                    debugPrint("Player error: Unable to play the video")
                }
            }
        }
    }
}
